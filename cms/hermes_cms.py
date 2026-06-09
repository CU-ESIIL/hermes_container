#!/usr/bin/env python3
"""Minimal file-backed Hermes workspace CMS."""

from __future__ import annotations

import html
import csv
import json
import mimetypes
import os
import posixpath
import re
import shutil
import subprocess
import urllib.parse
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

DEFAULT_ROOTS = "/workspace,/data/outputs,/repo/docs,/repo/examples,/repo/storage,/external_storage/local"
DEFAULT_SAFE_WRITE_ROOTS = "/workspace,/data/outputs,/tmp"
STATUSES = ["draft", "needs_review", "approved", "published"]
VISIBILITIES = ["private", "public", "metadata_only"]
TEXT_EXTENSIONS = {".md", ".txt", ".py", ".sh", ".yml", ".yaml", ".json", ".csv", ".html", ".css", ".js", ".toml"}
ASSET_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".svg", ".csv", ".json", ".geojson", ".html"}
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg"}
TABLE_EXTENSIONS = {".csv", ".tsv"}
BLOCKED_PATHS = {
    Path("/proc"),
    Path("/sys"),
    Path("/dev"),
    Path("/run/secrets"),
    Path("/var/run/secrets"),
}
BLOCKED_PARTS = {".git", ".hermes", ".openclaw", ".ssh", "node_modules", "__pycache__", "secrets"}
BLOCKED_NAMES = {"id_rsa", "id_ed25519"}
BLOCKED_SUFFIXES = {".pem", ".key", ".token"}
MAX_TEXT_PREVIEW_BYTES = 250_000
MAX_TABLE_ROWS = 100
GITHUB_OWNER_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9.-]{0,38}$")
GITHUB_REPO_RE = re.compile(r"^[A-Za-z0-9._-]{1,100}$")
GITHUB_BRANCH_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._/-]{0,96}$")
PERMISSION_TIERS = {"read", "contribute", "admin"}
WRITE_PERMISSION_TIERS = {"contribute"}
PROTECTED_BRANCHES = {"main", "master"}


class Root:
    def __init__(self, name: str, path: Path):
        self.name = name
        self.path = path.resolve()


class UploadedFile:
    def __init__(self, filename: str, data: bytes):
        self.filename = filename
        self.data = data


def configured_roots() -> list[Root]:
    raw = os.environ.get("HERMES_CMS_ROOTS", DEFAULT_ROOTS)
    roots: list[Root] = []
    seen: set[Path] = set()
    for item in raw.split(","):
        item = item.strip()
        if not item:
            continue
        path = Path(item).resolve()
        if path in seen:
            continue
        seen.add(path)
        path.mkdir(parents=True, exist_ok=True)
        name = path.name or str(path)
        if str(path) == "/workspace":
            name = "workspace"
        elif str(path) == "/data/outputs":
            name = "outputs"
        elif str(path).startswith("/repo/"):
            name = f"repo-{path.name}"
        roots.append(Root(name, path))
    return roots


ROOTS = configured_roots()


def configured_safe_write_roots() -> list[Path]:
    raw = os.environ.get("HERMES_FILE_WRITABLE_ROOTS", DEFAULT_SAFE_WRITE_ROOTS)
    roots: list[Path] = []
    for item in raw.split(","):
        item = item.strip()
        if item:
            roots.append(Path(item).resolve())
    return roots


SAFE_WRITE_ROOTS = configured_safe_write_roots()


def workspace_root() -> Path:
    return Path(os.environ.get("HERMES_WORKSPACE") or os.environ.get("OPENCLAW_WORKSPACE", "/workspace")).resolve(strict=False)


def github_config_root() -> Path:
    return workspace_root() / ".openclaw-github"


def github_repos_root() -> Path:
    return workspace_root() / "repos"


def github_registry_path() -> Path:
    return github_config_root() / "authorized-repos.yaml"


def is_relative_to(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def is_sensitive_path(path: Path) -> bool:
    path = path.resolve(strict=False)
    for blocked in BLOCKED_PATHS:
        if path == blocked or is_relative_to(path, blocked):
            return True
    parts = set(path.parts)
    if parts & BLOCKED_PARTS:
        return True
    name = path.name
    lower = name.lower()
    if name in BLOCKED_NAMES:
        return True
    if lower == ".env" or lower.startswith(".env."):
        return True
    if path.suffix.lower() in BLOCKED_SUFFIXES:
        return True
    if "token" in lower and path.suffix.lower() in {"", ".txt", ".json", ".yaml", ".yml", ".toml"}:
        return True
    return False


def require_visible(path: Path) -> None:
    if is_sensitive_path(path):
        raise ValueError("This path is hidden or blocked by the Hermes file safety policy.")


def can_write_path(path: Path) -> bool:
    path = path.resolve(strict=False)
    if is_sensitive_path(path):
        return False
    return any(path == root or is_relative_to(path, root) for root in SAFE_WRITE_ROOTS)


def require_writable(path: Path) -> None:
    if not can_write_path(path):
        allowed = ", ".join(str(root) for root in SAFE_WRITE_ROOTS)
        raise ValueError(f"Write operations are limited to safe workspace roots: {allowed}")


def container_path(raw_path: str | None = None) -> Path:
    requested = (raw_path or "/").strip() or "/"
    if not requested.startswith("/"):
        requested = "/" + requested
    path = Path(posixpath.normpath(requested)).resolve(strict=False)
    require_visible(path)
    return path


def display_size(path: Path) -> str:
    if path.is_dir():
        return ""
    size = path.stat().st_size
    for unit in ["B", "KB", "MB", "GB"]:
        if size < 1024 or unit == "GB":
            return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024
    return str(path.stat().st_size)


def modified_time(path: Path) -> str:
    try:
        return datetime.fromtimestamp(path.stat().st_mtime).strftime("%Y-%m-%d %H:%M")
    except OSError:
        return ""


def file_kind(path: Path) -> str:
    if path.is_dir():
        return "folder"
    suffix = path.suffix.lower().lstrip(".")
    return suffix or "file"


def icon_for(path: Path) -> str:
    if path.is_dir():
        return "folder"
    suffix = path.suffix.lower()
    if suffix in IMAGE_EXTENSIONS:
        return "image"
    if suffix in TABLE_EXTENSIONS:
        return "table"
    if suffix == ".md":
        return "markdown"
    if suffix in TEXT_EXTENSIONS:
        return "text"
    return "file"


def find_root(name: str) -> Root:
    for root in ROOTS:
        if root.name == name:
            return root
    raise ValueError(f"Unknown root: {name}")


def safe_path(root_name: str, rel_path: str = "") -> tuple[Root, Path]:
    root = find_root(root_name)
    clean_rel = posixpath.normpath("/" + rel_path).lstrip("/")
    path = (root.path / clean_rel).resolve()
    if path != root.path and root.path not in path.parents:
        raise ValueError("Path escapes configured root.")
    require_visible(path)
    return root, path


def metadata_path(path: Path) -> Path:
    return path.with_name(f"{path.name}.hermes.meta.json")


def read_metadata(path: Path) -> dict[str, Any]:
    meta = metadata_path(path)
    if not meta.exists():
        return {
            "status": "draft",
            "visibility": "private",
            "created_by": "hermes-cms",
            "source_files": [str(path)],
            "outputs": [],
            "external_data": [],
        }
    try:
        return json.loads(meta.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {"status": "draft", "visibility": "private", "metadata_error": f"Invalid JSON: {meta}"}


def write_metadata(path: Path, updates: dict[str, Any]) -> dict[str, Any]:
    meta = read_metadata(path)
    meta.update(updates)
    meta.setdefault("created_at", datetime.now(timezone.utc).isoformat())
    meta["updated_at"] = datetime.now(timezone.utc).isoformat()
    metadata_path(path).write_text(json.dumps(meta, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return meta


def render_page(title: str, body: str, gateway_url: str = "") -> bytes:
    gateway_link = (
        f'<a class="nav-button primary" href="{html.escape(gateway_url)}">Back to Hermes</a>'
        if gateway_url else ""
    )
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)} - Hermes CMS</title>
<style>
:root {{ --blue:#234a65; --cyan:#42bcdc; --green:#007135; --ink:#161a19; --line:#e3e3e3; }}
body {{ margin:0; font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color:var(--ink); background:#f7faf9; }}
header {{ display:flex; align-items:center; justify-content:space-between; gap:1rem; padding:0.85rem 1.1rem; border-bottom:1px solid var(--line); background:white; position:sticky; top:0; z-index:2; }}
.brand-lockup {{ display:flex; align-items:center; gap:0.9rem; min-width:0; }}
header img {{ width:2.4rem; height:2.4rem; object-fit:contain; }}
header strong {{ color:var(--blue); font-size:1.05rem; }}
.header-nav {{ display:flex; flex-wrap:wrap; justify-content:flex-end; gap:.45rem; }}
.nav-button {{ display:inline-flex; align-items:center; min-height:2rem; padding:.35rem .6rem; border:1px solid var(--line); border-radius:6px; background:#f9fbfb; color:var(--blue); font-weight:750; white-space:nowrap; }}
.nav-button.primary {{ background:var(--green); border-color:var(--green); color:white; }}
main {{ max-width:1280px; margin:0 auto; padding:1.2rem; }}
a {{ color:#006c8c; text-decoration:none; }}
a:hover {{ text-decoration:underline; }}
.toolbar, .panel {{ background:white; border:1px solid var(--line); border-radius:8px; padding:1rem; margin-bottom:1rem; }}
.roots {{ display:flex; flex-wrap:wrap; gap:0.45rem; }}
.pill {{ display:inline-flex; align-items:center; gap:.35rem; padding:0.3rem 0.55rem; border:1px solid var(--line); border-radius:999px; background:#f9fbfb; font-size:0.9rem; }}
table {{ width:100%; border-collapse:collapse; background:white; border:1px solid var(--line); border-radius:8px; overflow:hidden; }}
th, td {{ padding:0.55rem 0.65rem; border-bottom:1px solid var(--line); text-align:left; vertical-align:top; }}
th {{ background:#edf5f2; color:var(--blue); }}
tr:last-child td {{ border-bottom:0; }}
textarea {{ width:100%; min-height:28rem; font:0.92rem ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; border:1px solid var(--line); border-radius:6px; padding:0.7rem; box-sizing:border-box; }}
button, .button {{ border:0; border-radius:6px; background:var(--green); color:white; padding:0.45rem 0.7rem; font-weight:650; cursor:pointer; }}
.button.secondary, button.secondary {{ background:var(--blue); }}
input, select {{ border:1px solid var(--line); border-radius:6px; padding:0.42rem; }}
pre {{ overflow:auto; background:#0f1720; color:#eef7f7; padding:1rem; border-radius:8px; }}
.preview img {{ max-width:100%; height:auto; border:1px solid var(--line); border-radius:8px; }}
.muted {{ color:#5d666b; }}
.file-shell {{ display:grid; grid-template-columns:minmax(240px, 320px) minmax(0, 1fr); gap:1rem; align-items:start; }}
.file-sidebar {{ position:sticky; top:5rem; }}
.file-actions {{ display:flex; flex-wrap:wrap; gap:.45rem; align-items:center; }}
.file-actions form {{ display:inline-flex; flex-wrap:wrap; gap:.35rem; align-items:center; margin:0; }}
.breadcrumbs {{ font-size:.92rem; color:#5d666b; }}
.status-card {{ border-left:4px solid var(--green); }}
.system-warning {{ border-left:4px solid #f28c28; }}
.workspace-good {{ border-left:4px solid var(--cyan); }}
.danger {{ background:#c8332b; }}
.file-table td:first-child {{ font-weight:650; }}
.file-icon {{ display:inline-block; width:1.8rem; color:var(--blue); font-weight:800; }}
.preview-grid {{ display:grid; grid-template-columns:minmax(0, 1fr) 260px; gap:1rem; }}
.metadata-list {{ margin:0; padding:0; list-style:none; }}
.metadata-list li {{ padding:.35rem 0; border-bottom:1px solid var(--line); }}
.markdown-preview {{ line-height:1.55; }}
.markdown-preview code {{ background:#edf5f2; border-radius:4px; padding:.1rem .25rem; }}
.markdown-preview pre code {{ background:transparent; padding:0; }}
.markdown-preview table {{ margin:.8rem 0; }}
.search-box {{ min-width:14rem; }}
.github-grid {{ display:grid; grid-template-columns:minmax(280px, 360px) minmax(0, 1fr); gap:1rem; align-items:start; }}
.repo-card {{ border-left:4px solid var(--blue); }}
.repo-card.disabled {{ opacity:.68; }}
.repo-actions {{ display:flex; flex-wrap:wrap; gap:.4rem; align-items:center; }}
.repo-actions form {{ display:inline-flex; flex-wrap:wrap; gap:.35rem; align-items:center; margin:0; }}
.tier-read {{ color:#234a65; font-weight:800; }}
.tier-contribute {{ color:#007135; font-weight:800; }}
.tier-admin {{ color:#c8332b; font-weight:800; }}
.dirty {{ color:#c8332b; font-weight:800; }}
.clean {{ color:#007135; font-weight:800; }}
@media (max-width: 880px) {{
  .file-shell, .preview-grid, .github-grid {{ grid-template-columns:1fr; }}
  .file-sidebar {{ position:static; }}
  header {{ align-items:flex-start; flex-direction:column; }}
  .header-nav {{ justify-content:flex-start; }}
}}
</style>
</head>
<body>
<header>
  <div class="brand-lockup"><img src="/brand/hermes.png" alt=""><div><strong>Hermes Workspace</strong><br><span class="muted">files, outputs, previews, and review</span></div></div>
  <nav class="header-nav" aria-label="Workspace navigation">
    {gateway_link}
    <a class="nav-button" href="/">CMS Home</a>
    <a class="nav-button" href="/files?path=/workspace">Files</a>
    <a class="nav-button" href="/github">GitHub</a>
  </nav>
</header>
<main>{body}</main>
</body>
</html>""".encode("utf-8")


def rel_link(root: str, path: Path, root_path: Path) -> str:
    rel = "" if path == root_path else path.relative_to(root_path).as_posix()
    return f"/browse?root={urllib.parse.quote(root)}&path={urllib.parse.quote(rel)}"


def files_link(path: Path) -> str:
    return f"/files?path={urllib.parse.quote(str(path))}"


def raw_file_link(path: Path, download: bool = False) -> str:
    suffix = "&download=1" if download else ""
    return f"/files/raw?path={urllib.parse.quote(str(path))}{suffix}"


def render_basic_markdown(text: str, base_path: Path) -> str:
    lines = text.splitlines()
    out: list[str] = []
    in_code = False
    code_lines: list[str] = []
    table_rows: list[list[str]] = []

    def flush_table() -> None:
        nonlocal table_rows
        if not table_rows:
            return
        head, *body = table_rows
        out.append("<table><thead><tr>" + "".join(f"<th>{html.escape(cell)}</th>" for cell in head) + "</tr></thead><tbody>")
        for row in body:
            out.append("<tr>" + "".join(f"<td>{html.escape(cell)}</td>" for cell in row) + "</tr>")
        out.append("</tbody></table>")
        table_rows = []

    for line in lines:
        if line.strip().startswith("```"):
            flush_table()
            if in_code:
                out.append("<pre><code>" + html.escape("\n".join(code_lines)) + "</code></pre>")
                code_lines = []
                in_code = False
            else:
                in_code = True
            continue
        if in_code:
            code_lines.append(line)
            continue
        if "|" in line and line.strip().startswith("|") and line.strip().endswith("|"):
            cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
            if not all(re.fullmatch(r":?-{3,}:?", cell) for cell in cells):
                table_rows.append(cells)
            continue
        flush_table()
        if not line.strip():
            continue
        image = re.fullmatch(r"!\[([^\]]*)\]\(([^)]+)\)", line.strip())
        if image:
            alt, src = image.groups()
            if not urllib.parse.urlparse(src).scheme:
                src_path = (base_path.parent / src).resolve(strict=False)
                if not is_sensitive_path(src_path) and src_path.exists():
                    src = raw_file_link(src_path)
            out.append(f"<p><img src='{html.escape(src)}' alt='{html.escape(alt)}'></p>")
            continue
        heading = re.match(r"^(#{1,6})\s+(.+)$", line)
        if heading:
            level = len(heading.group(1))
            out.append(f"<h{level}>{html.escape(heading.group(2))}</h{level}>")
            continue
        escaped = html.escape(line)
        escaped = re.sub(r"`([^`]+)`", r"<code>\1</code>", escaped)
        out.append(f"<p>{escaped}</p>")
    flush_table()
    if in_code:
        out.append("<pre><code>" + html.escape("\n".join(code_lines)) + "</code></pre>")
    return "".join(out)


def image_dimensions(path: Path) -> str:
    suffix = path.suffix.lower()
    try:
        data = path.read_bytes()[:4096]
        if suffix == ".png" and data.startswith(b"\x89PNG\r\n\x1a\n") and len(data) >= 24:
            width = int.from_bytes(data[16:20], "big")
            height = int.from_bytes(data[20:24], "big")
            return f"{width} x {height}"
        if suffix == ".gif" and data.startswith((b"GIF87a", b"GIF89a")) and len(data) >= 10:
            width = int.from_bytes(data[6:8], "little")
            height = int.from_bytes(data[8:10], "little")
            return f"{width} x {height}"
        if suffix == ".svg":
            text = path.read_text(encoding="utf-8", errors="replace")[:4096]
            width = re.search(r'\bwidth=["\']?([0-9.]+)', text)
            height = re.search(r'\bheight=["\']?([0-9.]+)', text)
            if width and height:
                return f"{width.group(1)} x {height.group(1)}"
    except OSError:
        pass
    return "unknown"


def mask_secret_text(text: str) -> str:
    patterns = [
        r"xoxb-[A-Za-z0-9._-]+",
        r"xapp-[A-Za-z0-9._-]+",
        r"gh[pousr]_[A-Za-z0-9_]+",
        r"github_pat_[A-Za-z0-9_]+",
        r"sk-[A-Za-z0-9._-]+",
    ]
    masked = text
    for pattern in patterns:
        masked = re.sub(pattern, lambda m: m.group(0)[:6] + "****" + m.group(0)[-4:], masked)
    return masked


def validate_repo_parts(owner: str, repo: str) -> None:
    if not GITHUB_OWNER_RE.fullmatch(owner or ""):
        raise ValueError("Invalid GitHub owner. Use a conservative owner/name identifier.")
    if not GITHUB_REPO_RE.fullmatch(repo or ""):
        raise ValueError("Invalid GitHub repository name. Use letters, numbers, '.', '_', or '-'.")


def validate_permission_tier(tier: str) -> str:
    tier = (tier or "read").strip().lower()
    if tier not in PERMISSION_TIERS:
        raise ValueError("Invalid permission tier.")
    return tier


def default_repo_url(owner: str, repo: str) -> str:
    validate_repo_parts(owner, repo)
    return f"https://github.com/{owner}/{repo}.git"


def validate_remote_url(url: str, owner: str, repo: str) -> str:
    url = (url or default_repo_url(owner, repo)).strip()
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme == "https" and parsed.netloc.lower() == "github.com":
        return url
    if re.fullmatch(r"git@github\.com:[A-Za-z0-9.-]+/[A-Za-z0-9._-]+\.git", url):
        return url
    raise ValueError("Only github.com HTTPS or git@github.com remotes are supported.")


def validate_branch_name(branch: str) -> str:
    branch = (branch or "").strip()
    if not GITHUB_BRANCH_RE.fullmatch(branch):
        raise ValueError("Invalid branch name.")
    if branch in PROTECTED_BRANCHES:
        raise ValueError("Protected branches cannot be used as working branches.")
    if branch.startswith(("-", "/", ".")) or branch.endswith(("/", ".", ".lock")) or ".." in branch or "@{" in branch:
        raise ValueError("Unsafe branch name.")
    return branch


def safe_repo_local_path(owner: str, repo: str, local_path: str | None = None) -> Path:
    validate_repo_parts(owner, repo)
    root = github_repos_root().resolve(strict=False)
    requested = Path(local_path).resolve(strict=False) if local_path else (root / repo).resolve(strict=False)
    if requested != root and not is_relative_to(requested, root):
        raise ValueError("GitHub repositories must be cloned under /workspace/repos.")
    if is_sensitive_path(requested):
        raise ValueError("Repository path is blocked by the sensitive file policy.")
    return requested


def yaml_quote(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return '""'
    return json.dumps(str(value), ensure_ascii=True)


def yaml_unquote(value: str) -> Any:
    value = value.strip()
    if value in {"true", "false"}:
        return value == "true"
    if value in {"", '""', "''"}:
        return ""
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return value.strip("'\"")


def read_github_registry() -> dict[str, Any]:
    path = github_registry_path()
    if not path.exists():
        return {"repositories": []}
    repos: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or stripped == "repositories:":
            continue
        if stripped.startswith("- "):
            if current:
                repos.append(current)
            current = {}
            stripped = stripped[2:].strip()
            if stripped and ":" in stripped:
                key, value = stripped.split(":", 1)
                current[key.strip()] = yaml_unquote(value)
            continue
        if current is not None and ":" in stripped:
            key, value = stripped.split(":", 1)
            current[key.strip()] = yaml_unquote(value)
    if current:
        repos.append(current)
    cleaned: list[dict[str, Any]] = []
    for repo in repos:
        owner = str(repo.get("owner", "")).strip()
        name = str(repo.get("repo", "")).strip()
        validate_repo_parts(owner, name)
        tier = validate_permission_tier(str(repo.get("permission_tier", "read")))
        local = safe_repo_local_path(owner, name, str(repo.get("local_path") or ""))
        cleaned.append({
            "owner": owner,
            "repo": name,
            "url": validate_remote_url(str(repo.get("url") or ""), owner, name),
            "local_path": str(local),
            "default_branch": str(repo.get("default_branch") or "main"),
            "permission_tier": tier,
            "enabled": bool(repo.get("enabled", True)),
            "notes": str(repo.get("notes") or ""),
        })
    return {"repositories": cleaned}


def write_github_registry(registry: dict[str, Any]) -> None:
    root = github_config_root()
    root.mkdir(parents=True, exist_ok=True)
    repos = registry.get("repositories", [])
    lines = [
        "# Authorized GitHub repositories for this Hermes workspace.",
        "# Tokens are never stored here.",
        "repositories:",
    ]
    for repo in repos:
        lines.append(f"  - owner: {yaml_quote(repo.get('owner', ''))}")
        lines.append(f"    repo: {yaml_quote(repo.get('repo', ''))}")
        lines.append(f"    url: {yaml_quote(repo.get('url', ''))}")
        lines.append(f"    local_path: {yaml_quote(repo.get('local_path', ''))}")
        lines.append(f"    default_branch: {yaml_quote(repo.get('default_branch', 'main'))}")
        lines.append(f"    permission_tier: {yaml_quote(repo.get('permission_tier', 'read'))}")
        lines.append(f"    enabled: {yaml_quote(bool(repo.get('enabled', True)))}")
        lines.append(f"    notes: {yaml_quote(repo.get('notes', ''))}")
    github_registry_path().write_text("\n".join(lines) + "\n", encoding="utf-8")


def github_repo_key(owner: str, repo: str) -> str:
    return f"{owner}/{repo}".lower()


def find_authorized_repo(owner: str, repo: str) -> dict[str, Any]:
    validate_repo_parts(owner, repo)
    registry = read_github_registry()
    key = github_repo_key(owner, repo)
    for item in registry["repositories"]:
        if github_repo_key(item["owner"], item["repo"]) == key:
            return item
    raise ValueError("Repository is not authorized in this workspace.")


def upsert_authorized_repo(repo: dict[str, Any]) -> dict[str, Any]:
    owner = str(repo.get("owner", "")).strip()
    name = str(repo.get("repo", "")).strip()
    validate_repo_parts(owner, name)
    normalized = {
        "owner": owner,
        "repo": name,
        "url": validate_remote_url(str(repo.get("url") or ""), owner, name),
        "local_path": str(safe_repo_local_path(owner, name, str(repo.get("local_path") or ""))),
        "default_branch": str(repo.get("default_branch") or "main"),
        "permission_tier": validate_permission_tier(str(repo.get("permission_tier") or "read")),
        "enabled": str(repo.get("enabled", "true")).lower() not in {"0", "false", "no", "disabled"},
        "notes": str(repo.get("notes") or ""),
    }
    registry = read_github_registry()
    key = github_repo_key(owner, name)
    registry["repositories"] = [
        existing for existing in registry["repositories"]
        if github_repo_key(existing["owner"], existing["repo"]) != key
    ]
    registry["repositories"].append(normalized)
    registry["repositories"].sort(key=lambda item: (item["owner"].lower(), item["repo"].lower()))
    write_github_registry(registry)
    return normalized


def remove_authorized_repo(owner: str, repo: str) -> None:
    registry = read_github_registry()
    key = github_repo_key(owner, repo)
    registry["repositories"] = [
        item for item in registry["repositories"]
        if github_repo_key(item["owner"], item["repo"]) != key
    ]
    write_github_registry(registry)


def run_safe_command(args: list[str], cwd: Path | None = None, timeout: int = 45) -> dict[str, Any]:
    try:
        result = subprocess.run(
            args,
            cwd=str(cwd) if cwd else None,
            text=True,
            capture_output=True,
            timeout=timeout,
            check=False,
            env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
        )
    except FileNotFoundError:
        return {"returncode": 127, "stdout": "", "stderr": f"Command not found: {args[0]}", "ok": False}
    except subprocess.TimeoutExpired:
        return {"returncode": 124, "stdout": "", "stderr": f"Command timed out: {args[0]}", "ok": False}
    return {
        "returncode": result.returncode,
        "stdout": mask_secret_text(result.stdout.strip()),
        "stderr": mask_secret_text(result.stderr.strip()),
        "ok": result.returncode == 0,
    }


def git_available() -> bool:
    return shutil.which("git") is not None


def gh_available() -> bool:
    return shutil.which("gh") is not None


def command_summary(command: dict[str, Any]) -> str:
    text = "\n".join(part for part in [command.get("stdout", ""), command.get("stderr", "")] if part)
    return text[:4000]


def github_token_available() -> bool:
    return bool(os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN"))


def github_setup_git_credentials() -> dict[str, Any]:
    if not gh_available():
        return {"ok": False, "returncode": 127, "stdout": "", "stderr": "GitHub CLI is not installed."}
    if not github_token_available():
        return {
            "ok": False,
            "returncode": 2,
            "stdout": "",
            "stderr": "No GH_TOKEN or GITHUB_TOKEN is available to the CMS process. Add a GitHub secret/token and recreate the CMS service.",
        }
    setup = run_safe_command(["gh", "auth", "setup-git"], timeout=30)
    git_config = run_safe_command(
        ["git", "config", "--global", "credential.https://github.com.helper", "!gh auth git-credential"],
        timeout=15,
    )
    gist_config = run_safe_command(
        ["git", "config", "--global", "credential.https://gist.github.com.helper", "!gh auth git-credential"],
        timeout=15,
    )
    ok = setup["ok"] or (git_config["ok"] and gist_config["ok"])
    return {
        "ok": ok,
        "returncode": 0 if ok else setup.get("returncode", 1),
        "stdout": "\n".join(
            part for part in [
                command_summary(setup),
                "Configured git credential helpers for github.com and gist.github.com."
                if git_config["ok"] and gist_config["ok"] else "",
            ] if part
        ),
        "stderr": "\n".join(
            part for part in [
                "" if setup["ok"] else command_summary(setup),
                "" if git_config["ok"] else command_summary(git_config),
                "" if gist_config["ok"] else command_summary(gist_config),
            ] if part
        ),
    }


def git_repo_status(repo: dict[str, Any]) -> dict[str, Any]:
    path = safe_repo_local_path(repo["owner"], repo["repo"], repo["local_path"])
    status: dict[str, Any] = {
        "owner": repo["owner"],
        "repo": repo["repo"],
        "local_path": str(path),
        "url": repo["url"],
        "default_branch": repo.get("default_branch", "main"),
        "permission_tier": repo.get("permission_tier", "read"),
        "enabled": repo.get("enabled", True),
        "cloned": (path / ".git").exists(),
        "current_branch": "",
        "dirty": False,
        "changed_files": [],
        "ahead_behind": "",
        "recent_commits": [],
        "remote_head": "",
        "last_fetch": "",
        "active_pr": "",
    }
    if not status["cloned"] or not git_available():
        return status
    branch = run_safe_command(["git", "branch", "--show-current"], cwd=path)
    status["current_branch"] = branch["stdout"] if branch["ok"] else ""
    porcelain = run_safe_command(["git", "status", "--porcelain"], cwd=path)
    if porcelain["ok"]:
        files = [line for line in porcelain["stdout"].splitlines() if line.strip()]
        status["dirty"] = bool(files)
        status["changed_files"] = files
    remote_head = run_safe_command(["git", "rev-parse", "--abbrev-ref", "origin/HEAD"], cwd=path)
    if remote_head["ok"]:
        status["remote_head"] = remote_head["stdout"]
    if status["current_branch"]:
        ahead = run_safe_command(["git", "rev-list", "--left-right", "--count", f"origin/{status['current_branch']}...HEAD"], cwd=path)
        if ahead["ok"]:
            status["ahead_behind"] = ahead["stdout"]
    log = run_safe_command(["git", "log", "--oneline", "-n", "10"], cwd=path)
    if log["ok"]:
        status["recent_commits"] = [line for line in log["stdout"].splitlines() if line.strip()]
    fetch_head = path / ".git" / "FETCH_HEAD"
    if fetch_head.exists():
        status["last_fetch"] = modified_time(fetch_head)
    if gh_available():
        pr = run_safe_command(["gh", "pr", "view", "--json", "url", "--jq", ".url"], cwd=path, timeout=20)
        if pr["ok"]:
            status["active_pr"] = pr["stdout"]
    return status


def require_repo_contribute(repo: dict[str, Any]) -> None:
    tier = validate_permission_tier(str(repo.get("permission_tier", "read")))
    if tier not in WRITE_PERMISSION_TIERS:
        raise ValueError("This repository is not authorized for contribute operations.")


def require_not_protected_branch(path: Path) -> str:
    branch = run_safe_command(["git", "branch", "--show-current"], cwd=path)
    current = branch["stdout"].strip()
    if current in PROTECTED_BRANCHES:
        raise ValueError("Direct write operations on main/master are blocked. Create an agent branch first.")
    return current


class Handler(BaseHTTPRequestHandler):
    server_version = "HermesCMS/0.1"

    def end_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        super().end_headers()

    def do_OPTIONS(self) -> None:  # noqa: N802
        self.send_response(204)
        self.end_headers()

    def do_GET(self) -> None:  # noqa: N802
        try:
            parsed = urllib.parse.urlparse(self.path)
            if parsed.path == "/":
                self.send_html("Hermes CMS", self.home())
            elif parsed.path == "/files":
                query = urllib.parse.parse_qs(parsed.query)
                self.send_html("Files", self.files(query.get("path", ["/"])[0], query.get("q", [""])[0]))
            elif parsed.path == "/files/edit":
                query = urllib.parse.parse_qs(parsed.query)
                self.send_html("Edit file", self.file_edit(query.get("path", ["/workspace/README.md"])[0]))
            elif parsed.path == "/files/raw":
                query = urllib.parse.parse_qs(parsed.query)
                self.send_container_raw(query.get("path", ["/"])[0], download=bool(query.get("download")))
            elif parsed.path == "/api/file/list":
                query = urllib.parse.parse_qs(parsed.query)
                self.send_json(self.file_listing(query.get("path", ["/"])[0], query.get("q", [""])[0]))
            elif parsed.path == "/github":
                query = urllib.parse.parse_qs(parsed.query)
                self.send_html("GitHub", self.github_page(query.get("repo", [""])[0]))
            elif parsed.path == "/api/github/status":
                self.send_json(self.github_auth_status())
            elif parsed.path == "/api/github/repos":
                self.send_json(self.github_registry_with_status())
            elif parsed.path == "/api/github/repo/status":
                query = urllib.parse.parse_qs(parsed.query)
                owner = query.get("owner", [""])[0]
                repo = query.get("repo", [""])[0]
                self.send_json(git_repo_status(find_authorized_repo(owner, repo)))
            elif parsed.path == "/browse":
                query = urllib.parse.parse_qs(parsed.query)
                root = query.get("root", [ROOTS[0].name])[0]
                rel = query.get("path", [""])[0]
                self.send_html("Browse", self.browse(root, rel))
            elif parsed.path == "/edit":
                query = urllib.parse.parse_qs(parsed.query)
                self.send_html("Edit", self.edit(query.get("root", [""])[0], query.get("path", [""])[0]))
            elif parsed.path == "/raw":
                query = urllib.parse.parse_qs(parsed.query)
                self.send_raw(query.get("root", [""])[0], query.get("path", [""])[0])
            elif parsed.path == "/brand/hermes.png":
                self.send_brand()
            else:
                self.send_error(404)
        except Exception as exc:  # noqa: BLE001 - visible local diagnostic.
            self.send_html("Error", f"<div class='panel'><h1>Error</h1><pre>{html.escape(str(exc))}</pre></div>", status=500)

    def do_POST(self) -> None:  # noqa: N802
        try:
            parsed = urllib.parse.urlparse(self.path)
            if parsed.path.startswith("/api/file/") or parsed.path.startswith("/files/"):
                self.handle_file_post(parsed.path)
                return
            if parsed.path.startswith("/api/github/"):
                self.handle_github_post(parsed.path)
                return
            length = int(self.headers.get("Content-Length", "0"))
            payload = urllib.parse.parse_qs(self.rfile.read(length).decode("utf-8"))
            action = payload.get("action", [""])[0]
            root = payload.get("root", [""])[0]
            rel = payload.get("path", [""])[0]
            if action == "save":
                self.save_markdown(root, rel, payload.get("content", [""])[0])
            elif action == "metadata":
                self.update_metadata(root, rel, payload)
            elif action == "promote":
                self.promote(root, rel, payload.get("target", ["reports"])[0])
            else:
                self.send_error(400, "Unknown action")
        except Exception as exc:  # noqa: BLE001
            if self.path.startswith("/api/github/"):
                body = (
                    "<div class='panel'><h1>GitHub action failed</h1>"
                    f"<pre>{html.escape(mask_secret_text(str(exc)))}</pre>"
                    "<p><a class='button' href='/github'>Back to GitHub manager</a></p></div>"
                )
                self.send_html("GitHub action failed", body, status=400)
            else:
                self.send_html("Error", f"<div class='panel'><h1>Error</h1><pre>{html.escape(str(exc))}</pre></div>", status=500)

    def gateway_url(self) -> str:
        configured = os.environ.get("HERMES_GATEWAY_URL", "").strip()
        if configured:
            return configured
        port = os.environ.get("HERMES_PORT") or os.environ.get("OPENCLAW_GATEWAY_PORT", "18789")
        port = port.strip() or "18789"
        host_header = self.headers.get("Host", "")
        if host_header.startswith("[") and "]" in host_header:
            host = host_header[1:host_header.index("]")]
        else:
            host = host_header.split(":", 1)[0]
        host = host.strip() or "127.0.0.1"
        if host in {"0.0.0.0", "::"}:
            host = "127.0.0.1"
        return f"http://{host}:{port}/"

    def home(self) -> str:
        roots = " ".join(f"<a class='pill' href='/browse?root={urllib.parse.quote(root.name)}'>{html.escape(root.name)}: {html.escape(str(root.path))}</a>" for root in ROOTS)
        return f"""
<section class="panel">
<h1>Hermes workspace</h1>
<p>This local tool lets a human browse the container, inspect agent-created outputs, edit safe text files, attach provenance/status metadata, and promote approved public artifacts into the MkDocs docs tree. It does not execute agent code or publish without a repository action.</p>
<p><a class="button" href="/files?path=/workspace">Open file manager</a> <a class="button secondary" href="/github">Open GitHub manager</a> <a class="button secondary" href="/files?path=/workspace/outputs">Inspect outputs</a></p>
<div class="roots">{roots}</div>
</section>
<section class="panel">
<h2>Promotion model</h2>
<ol>
<li>Drafts start in <code>/workspace</code> or <code>/data/outputs</code>.</li>
<li>The CMS records status sidecars next to the source file.</li>
<li>Approved Markdown can be promoted to <code>docs/reports/</code> or <code>docs/dashboard/</code>.</li>
<li>Small public assets can be copied into <code>docs/assets/cms/</code>.</li>
<li>Large private outputs stay in external storage and are represented by metadata or public links.</li>
</ol>
</section>
"""

    def file_sidebar(self) -> str:
        shortcuts = [
            ("Container root", "/"),
            ("Workspace", "/workspace"),
            ("Outputs", "/workspace/outputs"),
            ("Data outputs", "/data/outputs"),
            ("Reports", "/workspace/reports"),
            ("Temporary files", "/tmp"),
        ]
        links = "".join(
            f"<a class='pill' href='{files_link(Path(path))}'>{html.escape(label)}</a>"
            for label, path in shortcuts
        )
        writable = ", ".join(str(root) for root in SAFE_WRITE_ROOTS)
        return f"""
<aside class="file-sidebar">
<section class="panel status-card">
<h2>Files</h2>
<p class="muted">Browse from <code>/</code>. Create and edit work inside safe project folders.</p>
<div class="roots">{links}</div>
</section>
<section class="panel workspace-good">
<h2>Safe write roots</h2>
<p><code>{html.escape(writable)}</code></p>
<p class="muted">System paths are visible for transparency but locked against accidental edits.</p>
</section>
<section class="panel">
<h2>Recent workspace changes</h2>
{self.recent_changes()}
</section>
</aside>"""

    def recent_changes(self) -> str:
        base = Path("/workspace")
        if not base.exists():
            return "<p class='muted'>No workspace mounted yet.</p>"
        items: list[Path] = []
        try:
            for path in base.rglob("*"):
                if len(items) > 300:
                    break
                if path.is_file() and not is_sensitive_path(path):
                    items.append(path)
        except OSError:
            return "<p class='muted'>Recent files unavailable.</p>"
        items = sorted(items, key=lambda p: p.stat().st_mtime if p.exists() else 0, reverse=True)[:8]
        if not items:
            return "<p class='muted'>No recent files yet.</p>"
        return "<ul>" + "".join(
            f"<li><a href='{files_link(path)}'>{html.escape(path.relative_to(base).as_posix())}</a><br><span class='muted'>{html.escape(modified_time(path))}</span></li>"
            for path in items
        ) + "</ul>"

    def files(self, raw_path: str, search: str = "") -> str:
        path = container_path(raw_path)
        body = f"<div class='file-shell'>{self.file_sidebar()}<div>{self.file_main(path, search)}</div></div>"
        return body

    def file_main(self, path: Path, search: str = "") -> str:
        if path.is_dir():
            return self.file_directory(path, search)
        return self.file_preview(path)

    def file_breadcrumbs(self, path: Path) -> str:
        parts = path.parts
        crumbs = ["<a href='/files?path=/'>/</a>"]
        acc = Path("/")
        for part in parts[1:]:
            acc = acc / part
            if is_sensitive_path(acc):
                break
            crumbs.append(f"<a href='{files_link(acc)}'>{html.escape(part)}</a>")
        return "<nav class='breadcrumbs'>" + " / ".join(crumbs) + "</nav>"

    def file_operation_forms(self, path: Path) -> str:
        target = path if path.is_dir() else path.parent
        if not can_write_path(target):
            return "<p class='muted'>Write operations are disabled outside safe workspace roots.</p>"
        escaped = html.escape(str(target))
        return f"""
<div class="file-actions">
<form method="post" action="/api/file/mkdir"><input type="hidden" name="path" value="{escaped}"><input name="name" placeholder="new folder"><button type="submit">Create folder</button></form>
<form method="post" action="/api/file/touch"><input type="hidden" name="path" value="{escaped}"><input name="name" placeholder="new file.md"><button type="submit">Create file</button></form>
<form method="post" action="/api/file/upload" enctype="multipart/form-data"><input type="hidden" name="path" value="{escaped}"><input type="file" name="file"><button type="submit">Upload</button></form>
</div>"""

    def file_directory(self, path: Path, search: str = "") -> str:
        query = search.strip().lower()
        rows = []
        if path != Path("/"):
            rows.append(f"<tr><td><span class='file-icon'>up</span><a href='{files_link(path.parent)}'>..</a></td><td>folder</td><td></td><td></td><td></td></tr>")
        try:
            children = sorted(path.iterdir(), key=lambda p: (not p.is_dir(), p.name.lower()))
        except PermissionError:
            children = []
        for item in children:
            if is_sensitive_path(item):
                continue
            if query and query not in item.name.lower():
                continue
            writable = "yes" if can_write_path(item) else "read-only"
            link = files_link(item)
            download = "" if item.is_dir() else f"<a href='{raw_file_link(item, download=True)}'>Download</a>"
            rows.append(
                "<tr>"
                f"<td><span class='file-icon'>{html.escape(icon_for(item))}</span><a href='{link}'>{html.escape(item.name)}</a></td>"
                f"<td>{html.escape(file_kind(item))}</td>"
                f"<td>{html.escape(display_size(item))}</td>"
                f"<td>{html.escape(modified_time(item))}</td>"
                f"<td>{html.escape(writable)} {download}</td>"
                "</tr>"
            )
        label = "Workspace project area" if is_relative_to(path, Path("/workspace")) else "System/container path"
        warning = "" if can_write_path(path) else "<section class='panel system-warning'><strong>Read-only system view.</strong> You can inspect this path, but file changes are restricted to safe workspace roots.</section>"
        return f"""
<section class="toolbar">
{self.file_breadcrumbs(path)}
<h1>{html.escape(str(path))}</h1>
<p class="muted">{label}</p>
<form method="get" action="/files"><input type="hidden" name="path" value="{html.escape(str(path))}"><input class="search-box" name="q" value="{html.escape(search)}" placeholder="Filter this folder"><button type="submit">Filter</button></form>
</section>
{warning}
<section class="panel">{self.file_operation_forms(path)}</section>
<table class="file-table"><thead><tr><th>Name</th><th>Kind</th><th>Size</th><th>Modified</th><th>Access</th></tr></thead><tbody>{''.join(rows)}</tbody></table>"""

    def file_preview(self, path: Path) -> str:
        require_visible(path)
        suffix = path.suffix.lower()
        actions = [
            f"<a class='button secondary' href='{files_link(path.parent)}'>Back</a>",
            f"<a class='button secondary' href='{raw_file_link(path, download=True)}'>Download</a>",
        ]
        if suffix in TEXT_EXTENSIONS and can_write_path(path):
            actions.append(f"<a class='button' href='/files/edit?path={urllib.parse.quote(str(path))}'>Edit</a>")
        if can_write_path(path):
            actions.append(
                "<form method='post' action='/api/file/delete' onsubmit=\"return confirm('Delete this file?')\" style='display:inline-flex;gap:.35rem'>"
                f"<input type='hidden' name='path' value='{html.escape(str(path))}'><input type='hidden' name='confirm' value='yes'>"
                "<button class='danger' type='submit'>Delete</button></form>"
            )
            actions.append(
                "<form method='post' action='/api/file/rename' style='display:inline-flex;gap:.35rem'>"
                f"<input type='hidden' name='path' value='{html.escape(str(path))}'><input name='name' placeholder='new name'><button type='submit'>Rename</button></form>"
            )
        meta = f"""
<ul class="metadata-list">
<li><strong>Path</strong><br><code>{html.escape(str(path))}</code></li>
<li><strong>Kind</strong><br>{html.escape(file_kind(path))}</li>
<li><strong>Size</strong><br>{html.escape(display_size(path))}</li>
<li><strong>Modified</strong><br>{html.escape(modified_time(path))}</li>
<li><strong>Writable</strong><br>{'yes' if can_write_path(path) else 'read-only'}</li>
</ul>"""
        if suffix in IMAGE_EXTENSIONS:
            meta = meta.replace("</ul>", f"<li><strong>Dimensions</strong><br>{html.escape(image_dimensions(path))}</li></ul>")
        return f"""
<section class="toolbar">{self.file_breadcrumbs(path)}<h1>{html.escape(path.name)}</h1><div class="file-actions">{''.join(actions)}</div></section>
<section class="panel preview-grid"><div class="preview">{self.file_preview_content(path)}</div><aside>{meta}</aside></section>"""

    def file_preview_content(self, path: Path) -> str:
        suffix = path.suffix.lower()
        if suffix in IMAGE_EXTENSIONS:
            return f"<img src='{raw_file_link(path)}' alt='{html.escape(path.name)}'>"
        if suffix == ".md":
            text = path.read_text(encoding="utf-8", errors="replace")[:MAX_TEXT_PREVIEW_BYTES]
            return f"<div class='markdown-preview'>{render_basic_markdown(text, path)}</div>"
        if suffix in TABLE_EXTENSIONS:
            delimiter = "\t" if suffix == ".tsv" else ","
            rows = []
            with path.open("r", encoding="utf-8", errors="replace", newline="") as handle:
                reader = csv.reader(handle, delimiter=delimiter)
                for idx, row in enumerate(reader):
                    if idx >= MAX_TABLE_ROWS:
                        break
                    tag = "th" if idx == 0 else "td"
                    rows.append("<tr>" + "".join(f"<{tag}>{html.escape(cell)}</{tag}>" for cell in row) + "</tr>")
            return "<table>" + "".join(rows) + "</table>"
        if suffix in TEXT_EXTENSIONS:
            text = path.read_text(encoding="utf-8", errors="replace")[:MAX_TEXT_PREVIEW_BYTES]
            return f"<pre>{html.escape(text)}</pre>"
        return "<p>No inline preview for this file type.</p>"

    def file_edit(self, raw_path: str) -> str:
        path = container_path(raw_path)
        require_writable(path)
        if path.suffix.lower() not in TEXT_EXTENSIONS:
            raise ValueError("Only safe text-like files can be edited.")
        text = path.read_text(encoding="utf-8", errors="replace") if path.exists() else ""
        return f"""<section class="toolbar">{self.file_breadcrumbs(path)}<h1>Edit {html.escape(path.name)}</h1></section>
<form method="post" action="/api/file/save" class="panel" id="file-edit-form">
<input type="hidden" name="path" value="{html.escape(str(path))}">
<textarea name="content" spellcheck="false">{html.escape(text)}</textarea>
<p><button type="submit">Save</button> <a class="button secondary" href="{files_link(path)}">Cancel</a></p>
</form>
<script>
let changed = false;
const form = document.getElementById('file-edit-form');
form.querySelector('textarea').addEventListener('input', () => changed = true);
form.addEventListener('submit', () => changed = false);
window.addEventListener('beforeunload', (event) => {{
  if (!changed) return;
  event.preventDefault();
  event.returnValue = '';
}});
</script>"""

    def file_listing(self, raw_path: str, search: str = "") -> dict[str, Any]:
        path = container_path(raw_path)
        if not path.is_dir():
            return {"path": str(path), "kind": "file", "writable": can_write_path(path)}
        query = search.strip().lower()
        entries = []
        for item in sorted(path.iterdir(), key=lambda p: (not p.is_dir(), p.name.lower())):
            if is_sensitive_path(item) or (query and query not in item.name.lower()):
                continue
            entries.append({
                "name": item.name,
                "path": str(item),
                "kind": file_kind(item),
                "size": item.stat().st_size if item.is_file() else None,
                "modified": modified_time(item),
                "writable": can_write_path(item),
            })
        return {"path": str(path), "writable": can_write_path(path), "entries": entries}

    def github_auth_status(self) -> dict[str, Any]:
        status: dict[str, Any] = {
            "git_installed": git_available(),
            "gh_installed": gh_available(),
            "authenticated": False,
            "username": "",
            "auth_method": "none",
            "token_available": github_token_available(),
            "summary": "",
        }
        if status["token_available"]:
            status["auth_method"] = "environment token"
        if not gh_available():
            status["summary"] = "GitHub CLI is not installed."
            return status
        auth = run_safe_command(["gh", "auth", "status", "--hostname", "github.com"], timeout=20)
        status["authenticated"] = auth["ok"]
        status["summary"] = command_summary(auth)
        if auth["ok"]:
            user = run_safe_command(["gh", "api", "user", "--jq", ".login"], timeout=20)
            if user["ok"]:
                status["username"] = user["stdout"]
                status["auth_method"] = "GitHub CLI"
        return status

    def github_registry_with_status(self) -> dict[str, Any]:
        registry = read_github_registry()
        repos = []
        for repo in registry["repositories"]:
            try:
                repos.append(git_repo_status(repo))
            except Exception as exc:  # noqa: BLE001
                item = dict(repo)
                item["error"] = str(exc)
                repos.append(item)
        return {"registry_path": str(github_registry_path()), "repos_root": str(github_repos_root()), "repositories": repos}

    def github_page(self, selected: str = "") -> str:
        auth = self.github_auth_status()
        registry = self.github_registry_with_status()
        selected_repo = None
        if selected:
            for item in registry["repositories"]:
                if f"{item.get('owner')}/{item.get('repo')}".lower() == selected.lower():
                    selected_repo = item
                    break
        if selected_repo is None and registry["repositories"]:
            selected_repo = registry["repositories"][0]
        return f"""
<div class="github-grid">
<aside>
{self.github_auth_panel(auth)}
{self.github_add_repo_panel()}
{self.github_policy_panel()}
</aside>
<main>
{self.github_repo_table(registry, selected_repo)}
{self.github_active_repo_panel(selected_repo) if selected_repo else "<section class='panel'><h2>No active repository</h2><p>Add an authorized repository to begin.</p></section>"}
</main>
</div>"""

    def github_auth_panel(self, auth: dict[str, Any]) -> str:
        state = "Authenticated" if auth["authenticated"] else "Not authenticated"
        username = f"<p><strong>User:</strong> {html.escape(auth['username'])}</p>" if auth.get("username") else ""
        summary = html.escape(auth.get("summary") or "Run gh auth status for details.")
        return f"""
<section class="panel status-card">
<h2>GitHub Connection</h2>
<p><strong>{state}</strong></p>
{username}
<p><strong>Auth method:</strong> {html.escape(auth.get("auth_method", "none"))}</p>
<p><strong>Token visible to CMS:</strong> {"yes" if auth.get("token_available") else "no"}</p>
<pre>{summary}</pre>
<form method="post" action="/api/github/setup-git">
<button type="submit">Configure git credentials</button>
</form>
<p class="muted">GitHub commands run from the <code>workspace-cms</code> service. Authenticate there with <code>gh auth login</code>, then <code>gh auth setup-git</code>, or provide a fine-grained <code>GITHUB_TOKEN</code> in local secrets and recreate the CMS service. Tokens are never stored in the repository registry.</p>
</section>"""

    def github_add_repo_panel(self) -> str:
        return """
<section class="panel">
<h2>Add Authorized Repository</h2>
<p class="muted">Authorizing a repository records it in the local allowlist. After it appears below, click <strong>Clone</strong> before fetch, pull, branch, commit, push, or PR actions are available.</p>
<form method="post" action="/api/github/repos">
<p><input name="owner" placeholder="owner" required> <input name="repo" placeholder="repo" required></p>
<p><input name="url" placeholder="https://github.com/owner/repo.git" style="width:100%"></p>
<p><select name="permission_tier"><option value="read">read</option><option value="contribute">contribute</option><option value="admin">admin (disabled)</option></select></p>
<p><input name="notes" placeholder="notes" style="width:100%"></p>
<button type="submit">Authorize repo</button>
</form>
</section>"""

    def github_policy_panel(self) -> str:
        return """
<section class="panel system-warning">
<h2>Agent Access Policy</h2>
<p>Connected repositories are project workspaces. The container repository is infrastructure.</p>
<p>Agents work on branches and open pull requests. Direct pushes to <code>main</code> and <code>master</code> are blocked.</p>
<p>No tokens are stored in the repository registry.</p>
</section>"""

    def github_repo_table(self, registry: dict[str, Any], selected_repo: dict[str, Any] | None) -> str:
        rows = []
        for repo in registry["repositories"]:
            name = f"{repo.get('owner')}/{repo.get('repo')}"
            selected = selected_repo and name.lower() == f"{selected_repo.get('owner')}/{selected_repo.get('repo')}".lower()
            tier = html.escape(str(repo.get("permission_tier", "read")))
            dirty = "dirty" if repo.get("dirty") else "clean"
            cloned = "cloned" if repo.get("cloned") else "not cloned"
            rows.append(
                "<tr>"
                f"<td><a href='/github?repo={urllib.parse.quote(name)}'>{html.escape(name)}</a>{' <strong>(active)</strong>' if selected else ''}</td>"
                f"<td><span class='tier-{tier}'>{tier}</span></td>"
                f"<td>{html.escape(cloned)}</td>"
                f"<td>{html.escape(repo.get('current_branch') or '')}</td>"
                f"<td><span class='{dirty}'>{dirty}</span></td>"
                f"<td>{html.escape(repo.get('active_pr') or '')}</td>"
                "</tr>"
            )
        body = "".join(rows) or "<tr><td colspan='6'>No authorized repositories yet.</td></tr>"
        return f"""
<section class="panel">
<h1>Authorized GitHub Repositories</h1>
<p class="muted">Registry: <code>{html.escape(str(github_registry_path()))}</code></p>
<table><thead><tr><th>Repository</th><th>Tier</th><th>Clone</th><th>Branch</th><th>Status</th><th>PR</th></tr></thead><tbody>{body}</tbody></table>
</section>"""

    def github_active_repo_panel(self, repo: dict[str, Any]) -> str:
        name = f"{repo.get('owner')}/{repo.get('repo')}"
        tier = str(repo.get("permission_tier", "read"))
        path = str(repo.get("local_path", ""))
        changed = "\n".join(repo.get("changed_files", [])) or "No uncommitted changes."
        commits = "\n".join(repo.get("recent_commits", [])) or "No local commits available."
        clone_form = f"<form method='post' action='/api/github/repos/{html.escape(repo['owner'])}/{html.escape(repo['repo'])}/clone'><button type='submit'>Clone</button></form>"
        fetch_form = f"<form method='post' action='/api/github/repos/{html.escape(repo['owner'])}/{html.escape(repo['repo'])}/fetch'><button type='submit'>Fetch</button></form>"
        pull_form = f"<form method='post' action='/api/github/repos/{html.escape(repo['owner'])}/{html.escape(repo['repo'])}/pull'><button type='submit'>Pull</button></form>"
        remove_form = f"<form method='post' action='/api/github/repos/{html.escape(repo['owner'])}/{html.escape(repo['repo'])}/remove' onsubmit=\"return confirm('Remove this repo from the registry? Local files are not deleted.')\"><button class='danger' type='submit'>Remove from registry</button></form>"
        cloned = bool(repo.get("cloned"))
        branch_form = f"""
<form method="post" action="/api/github/repos/{html.escape(repo['owner'])}/{html.escape(repo['repo'])}/branch">
<input name="branch" placeholder="agent/short-task-name">
<button type="submit">Create branch</button>
</form>"""
        commit_form = f"""
<form method="post" action="/api/github/repos/{html.escape(repo['owner'])}/{html.escape(repo['repo'])}/commit">
<input name="message" placeholder="commit message" style="min-width:22rem">
<button type="submit">Commit changes</button>
</form>"""
        push_form = f"<form method='post' action='/api/github/repos/{html.escape(repo['owner'])}/{html.escape(repo['repo'])}/push'><button type='submit'>Push branch</button></form>"
        pr_form = f"""
<form method="post" action="/api/github/repos/{html.escape(repo['owner'])}/{html.escape(repo['repo'])}/pr">
<input name="title" placeholder="PR title" style="min-width:18rem">
<input name="body" placeholder="Summary / known limits" style="min-width:22rem">
<button type="submit">Open PR</button>
</form>"""
        if not cloned:
            contribute = "<p class='muted'>Clone this repository before creating branches, commits, pushes, or pull requests.</p>"
            repo_actions = clone_form + remove_form
            changed = "Repository is authorized but not cloned yet."
            commits = "Clone the repository to inspect local commits."
        else:
            repo_actions = fetch_form + pull_form
            contribute = branch_form + commit_form + push_form + pr_form if tier == "contribute" else "<p class='muted'>Contribute actions are disabled for read/admin tier in this first implementation.</p>"
        files_link_html = f"<a class='button secondary' href='{files_link(Path(path))}'>Open in Files</a>" if cloned else ""
        return f"""
<section class="panel repo-card">
<h2>{html.escape(name)}</h2>
<p><strong>Permission:</strong> <span class="tier-{html.escape(tier)}">{html.escape(tier)}</span></p>
<p><strong>Path:</strong> <code>{html.escape(path)}</code></p>
<p><strong>Remote:</strong> <code>{html.escape(str(repo.get('url', '')))}</code></p>
<p><strong>Default branch:</strong> {html.escape(str(repo.get('default_branch', 'main')))} | <strong>Current branch:</strong> {html.escape(str(repo.get('current_branch', '')))}</p>
<p><strong>Ahead/behind:</strong> {html.escape(str(repo.get('ahead_behind', 'unknown')))} | <strong>Last fetch:</strong> {html.escape(str(repo.get('last_fetch', '')))}</p>
<div class="repo-actions">{repo_actions}{files_link_html}{remove_form if cloned else ""}</div>
</section>
<section class="panel"><h2>Branch and PR Workflow</h2><div class="repo-actions">{contribute}</div></section>
<section class="panel"><h2>Uncommitted Changes</h2><pre>{html.escape(changed)}</pre></section>
<section class="panel"><h2>Recent Commits</h2><pre>{html.escape(commits)}</pre></section>"""

    def browse(self, root_name: str, rel: str) -> str:
        root, path = safe_path(root_name, rel)
        breadcrumb = f"<a href='/'>CMS</a> / <a href='{rel_link(root.name, root.path, root.path)}'>{html.escape(root.name)}</a>"
        if path != root.path:
            parts = path.relative_to(root.path).parts
            acc: list[str] = []
            for part in parts:
                acc.append(part)
                breadcrumb += f" / <a href='{rel_link(root.name, root.path.joinpath(*acc), root.path)}'>{html.escape(part)}</a>"
        if path.is_dir():
            rows = []
            if path != root.path:
                rows.append(f"<tr><td><a href='{rel_link(root.name, path.parent, root.path)}'>..</a></td><td>directory</td><td></td></tr>")
            for item in sorted(path.iterdir(), key=lambda p: (not p.is_dir(), p.name.lower())):
                if item.name.startswith(".") and not item.name.endswith(".hermes.meta.json"):
                    continue
                rel_item = item.relative_to(root.path).as_posix()
                kind = "directory" if item.is_dir() else item.suffix.lower().lstrip(".") or "file"
                size = "" if item.is_dir() else str(item.stat().st_size)
                rows.append(f"<tr><td><a href='/browse?root={urllib.parse.quote(root.name)}&path={urllib.parse.quote(rel_item)}'>{html.escape(item.name)}</a></td><td>{kind}</td><td>{size}</td></tr>")
            return f"<div class='toolbar'>{breadcrumb}</div><table><thead><tr><th>Name</th><th>Kind</th><th>Bytes</th></tr></thead><tbody>{''.join(rows)}</tbody></table>"
        return self.preview(root, path)

    def preview(self, root: Root, path: Path) -> str:
        rel = path.relative_to(root.path).as_posix()
        meta = read_metadata(path)
        status_options = "".join(f"<option {'selected' if meta.get('status') == s else ''}>{s}</option>" for s in STATUSES)
        visibility_options = "".join(f"<option {'selected' if meta.get('visibility') == s else ''}>{s}</option>" for s in VISIBILITIES)
        edit = ""
        if path.suffix.lower() in TEXT_EXTENSIONS:
            edit = f"<a class='button secondary' href='/edit?root={urllib.parse.quote(root.name)}&path={urllib.parse.quote(rel)}'>Edit text</a>"
        promote = ""
        if path.suffix.lower() in TEXT_EXTENSIONS | ASSET_EXTENSIONS:
            promote = f"""<form method="post" style="display:inline-block;margin-left:.4rem">
<input type="hidden" name="action" value="promote"><input type="hidden" name="root" value="{html.escape(root.name)}"><input type="hidden" name="path" value="{html.escape(rel)}">
<select name="target"><option value="reports">reports</option><option value="dashboard">dashboard</option><option value="assets">assets</option></select>
<button type="submit">Promote</button></form>"""
        body = f"<div class='toolbar'><a href='{rel_link(root.name, path.parent, root.path)}'>Back</a> / {html.escape(rel)}<br>{edit}{promote}</div>"
        body += f"""<section class="panel"><h2>Status metadata</h2>
<form method="post">
<input type="hidden" name="action" value="metadata"><input type="hidden" name="root" value="{html.escape(root.name)}"><input type="hidden" name="path" value="{html.escape(rel)}">
Status <select name="status">{status_options}</select>
Visibility <select name="visibility">{visibility_options}</select>
<button type="submit">Save status</button>
</form>
<pre>{html.escape(json.dumps(meta, indent=2, sort_keys=True))}</pre></section>"""
        body += f"<section class='panel preview'><h2>Preview</h2>{self.preview_content(root.name, rel, path)}</section>"
        return body

    def preview_content(self, root_name: str, rel: str, path: Path) -> str:
        suffix = path.suffix.lower()
        if suffix in {".png", ".jpg", ".jpeg", ".gif", ".svg"}:
            return f"<img src='/raw?root={urllib.parse.quote(root_name)}&path={urllib.parse.quote(rel)}' alt=''>"
        if suffix in TEXT_EXTENSIONS:
            text = path.read_text(encoding="utf-8", errors="replace")
            return f"<pre>{html.escape(text[:120000])}</pre>"
        return f"<p>No inline preview for <code>{html.escape(suffix or 'file')}</code>. Use raw download through the file browser.</p>"

    def edit(self, root_name: str, rel: str) -> str:
        root, path = safe_path(root_name, rel)
        if path.suffix.lower() not in TEXT_EXTENSIONS:
            raise ValueError("Only text-like files can be edited.")
        text = path.read_text(encoding="utf-8", errors="replace")
        return f"""<div class="toolbar"><a href="/browse?root={urllib.parse.quote(root.name)}&path={urllib.parse.quote(rel)}">Back to preview</a></div>
<form method="post" class="panel">
<input type="hidden" name="action" value="save"><input type="hidden" name="root" value="{html.escape(root.name)}"><input type="hidden" name="path" value="{html.escape(rel)}">
<textarea name="content">{html.escape(text)}</textarea>
<p><button type="submit">Save</button></p>
</form>"""

    def save_markdown(self, root_name: str, rel: str, content: str) -> None:
        _, path = safe_path(root_name, rel)
        require_writable(path)
        if path.suffix.lower() not in TEXT_EXTENSIONS:
            raise ValueError("Only text-like files can be edited.")
        path.write_text(content, encoding="utf-8")
        write_metadata(path, {"status": "draft", "visibility": "private", "last_edited_by": "hermes-cms"})
        self.redirect(f"/browse?root={urllib.parse.quote(root_name)}&path={urllib.parse.quote(rel)}")

    def update_metadata(self, root_name: str, rel: str, payload: dict[str, list[str]]) -> None:
        _, path = safe_path(root_name, rel)
        status = payload.get("status", ["draft"])[0]
        visibility = payload.get("visibility", ["private"])[0]
        if status not in STATUSES or visibility not in VISIBILITIES:
            raise ValueError("Invalid status or visibility.")
        write_metadata(path, {"status": status, "visibility": visibility})
        self.redirect(f"/browse?root={urllib.parse.quote(root_name)}&path={urllib.parse.quote(rel)}")

    def promote(self, root_name: str, rel: str, target: str) -> None:
        _, source = safe_path(root_name, rel)
        repo_docs = Path(os.environ.get("HERMES_REPO_ROOT", "/repo")).resolve() / "docs"
        repo_docs.mkdir(parents=True, exist_ok=True)
        suffix = source.suffix.lower()
        slug = source.stem.lower().replace(" ", "-").replace("_", "-")
        if target in {"reports", "dashboard"} and suffix in TEXT_EXTENSIONS:
            target_dir = repo_docs / target
            target_dir.mkdir(parents=True, exist_ok=True)
            dest = target_dir / f"{slug}{suffix if suffix in {'.md', '.html'} else '.md'}"
            body = source.read_text(encoding="utf-8", errors="replace")
            if dest.suffix == ".md":
                body = f"<!-- Promoted from {source} by Hermes CMS. Review before publishing. -->\n\n{body}"
            dest.write_text(body, encoding="utf-8")
        elif target == "assets" and suffix in ASSET_EXTENSIONS:
            target_dir = repo_docs / "assets" / "cms"
            target_dir.mkdir(parents=True, exist_ok=True)
            dest = target_dir / source.name
            shutil.copy2(source, dest)
        else:
            raise ValueError("Unsupported promotion target for this file type.")
        write_metadata(source, {"status": "published", "visibility": "public", "publish_target": str(dest)})
        self.redirect(f"/browse?root={urllib.parse.quote(root_name)}&path={urllib.parse.quote(rel)}")

    def parse_post_fields(self) -> dict[str, Any]:
        ctype = self.headers.get("Content-Type", "")
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length)
        if ctype.startswith("multipart/form-data"):
            result: dict[str, Any] = {}
            match = re.search(r"boundary=([^;]+)", ctype)
            if not match:
                return result
            boundary = ("--" + match.group(1).strip('"')).encode("utf-8")
            for part in raw.split(boundary):
                part = part.strip()
                if not part or part == b"--":
                    continue
                if part.endswith(b"--"):
                    part = part[:-2].strip()
                header_blob, _, body = part.partition(b"\r\n\r\n")
                if not _:
                    continue
                headers = header_blob.decode("utf-8", errors="replace")
                name_match = re.search(r'name="([^"]+)"', headers)
                if not name_match:
                    continue
                name = name_match.group(1)
                if body.endswith(b"\r\n"):
                    body = body[:-2]
                filename_match = re.search(r'filename="([^"]*)"', headers)
                if filename_match and filename_match.group(1):
                    result[name] = UploadedFile(Path(filename_match.group(1)).name, body)
                else:
                    result[name] = body.decode("utf-8", errors="replace")
            return result
        if ctype.startswith("application/json"):
            return json.loads(raw.decode("utf-8") or "{}")
        return {key: values[0] for key, values in urllib.parse.parse_qs(raw.decode("utf-8")).items()}

    def field_text(self, fields: dict[str, Any], key: str, default: str = "") -> str:
        value = fields.get(key, default)
        if isinstance(value, bytes):
            return value.decode("utf-8", errors="replace")
        return str(value)

    def handle_file_post(self, route: str) -> None:
        fields = self.parse_post_fields()
        if route == "/api/file/mkdir":
            base = container_path(self.field_text(fields, "path", "/workspace"))
            name = Path(self.field_text(fields, "name")).name
            target = (base / name).resolve(strict=False)
            require_writable(target)
            target.mkdir(parents=True, exist_ok=False)
            self.redirect(files_link(target))
            return
        if route == "/api/file/touch":
            base = container_path(self.field_text(fields, "path", "/workspace"))
            name = Path(self.field_text(fields, "name")).name
            target = (base / name).resolve(strict=False)
            require_writable(target)
            if target.suffix.lower() not in TEXT_EXTENSIONS:
                raise ValueError("New browser-editable files must use a safe text extension.")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.touch(exist_ok=False)
            self.redirect(f"/files/edit?path={urllib.parse.quote(str(target))}")
            return
        if route == "/api/file/save":
            target = container_path(self.field_text(fields, "path"))
            require_writable(target)
            if target.suffix.lower() not in TEXT_EXTENSIONS:
                raise ValueError("Only safe text-like files can be edited.")
            target.write_text(self.field_text(fields, "content"), encoding="utf-8")
            self.redirect(files_link(target))
            return
        if route == "/api/file/upload":
            base = container_path(self.field_text(fields, "path", "/workspace"))
            require_writable(base)
            upload = fields.get("file")
            if not isinstance(upload, UploadedFile) or not upload.filename:
                name = Path(self.field_text(fields, "name", "uploaded.txt")).name
                data = self.field_text(fields, "content").encode("utf-8")
            else:
                name = Path(upload.filename).name
                data = upload.data
            target = (base / name).resolve(strict=False)
            require_writable(target)
            if is_sensitive_path(target):
                raise ValueError("Upload target is blocked by the sensitive file policy.")
            target.write_bytes(data)
            self.redirect(files_link(target))
            return
        if route == "/api/file/delete":
            target = container_path(self.field_text(fields, "path"))
            require_writable(target)
            if self.field_text(fields, "confirm") != "yes":
                raise ValueError("Deletion requires confirm=yes.")
            parent = target.parent
            if target.is_dir():
                if any(target.iterdir()):
                    raise ValueError("Only empty folders can be deleted from the browser.")
                target.rmdir()
            else:
                target.unlink()
            self.redirect(files_link(parent))
            return
        if route == "/api/file/rename":
            target = container_path(self.field_text(fields, "path"))
            require_writable(target)
            name = Path(self.field_text(fields, "name")).name
            if not name:
                raise ValueError("Rename requires a new file name.")
            dest = (target.parent / name).resolve(strict=False)
            require_writable(dest)
            target.rename(dest)
            self.redirect(files_link(dest))
            return
        if route == "/api/file/copy":
            source = container_path(self.field_text(fields, "source"))
            dest = container_path(self.field_text(fields, "dest"))
            require_writable(dest)
            if source.is_dir():
                shutil.copytree(source, dest)
            else:
                shutil.copy2(source, dest)
            self.redirect(files_link(dest))
            return
        if route == "/api/file/move":
            source = container_path(self.field_text(fields, "source"))
            dest = container_path(self.field_text(fields, "dest"))
            require_writable(source)
            require_writable(dest)
            shutil.move(str(source), str(dest))
            self.redirect(files_link(dest))
            return
        self.send_error(404)

    def github_result(self, title: str, message: str, owner: str = "", repo: str = "", status: int = 200) -> None:
        target = f"{owner}/{repo}" if owner and repo else ""
        back = f"/github?repo={urllib.parse.quote(target)}" if target else "/github"
        self.send_html(title, f"<section class='panel'><h1>{html.escape(title)}</h1><pre>{html.escape(mask_secret_text(message))}</pre><p><a class='button' href='{back}'>Back to GitHub manager</a></p></section>", status=status)

    def handle_github_post(self, route: str) -> None:
        fields = self.parse_post_fields()
        if route == "/api/github/setup-git":
            result = github_setup_git_credentials()
            if not result["ok"]:
                raise ValueError(command_summary(result) or "GitHub credential setup failed")
            status = self.github_auth_status()
            message = "\n".join(
                part for part in [
                    command_summary(result),
                    "Current GitHub status:",
                    status.get("summary", ""),
                ] if part
            )
            self.github_result("GitHub credentials configured", message)
            return

        if route == "/api/github/repos":
            repo = upsert_authorized_repo({
                "owner": self.field_text(fields, "owner"),
                "repo": self.field_text(fields, "repo"),
                "url": self.field_text(fields, "url"),
                "permission_tier": self.field_text(fields, "permission_tier", "read"),
                "notes": self.field_text(fields, "notes"),
                "enabled": "true",
            })
            self.redirect(f"/github?repo={urllib.parse.quote(repo['owner'] + '/' + repo['repo'])}")
            return

        match = re.fullmatch(r"/api/github/repos/([^/]+)/([^/]+)/([A-Za-z_-]+)", route)
        if not match:
            self.send_error(404)
            return
        owner = urllib.parse.unquote(match.group(1))
        name = urllib.parse.unquote(match.group(2))
        action = match.group(3)
        repo = find_authorized_repo(owner, name)
        path = safe_repo_local_path(owner, name, repo["local_path"])

        if action == "remove":
            remove_authorized_repo(owner, name)
            self.redirect("/github")
            return

        if action == "clone":
            if not repo.get("enabled", True):
                raise ValueError("Repository is disabled in the registry.")
            if path.exists() and any(path.iterdir()):
                raise ValueError("Clone destination already exists and is not empty.")
            path.parent.mkdir(parents=True, exist_ok=True)
            result = run_safe_command(["git", "clone", repo["url"], str(path)], timeout=180)
            if not result["ok"]:
                raise ValueError(command_summary(result) or "git clone failed")
            self.github_result("Repository cloned", command_summary(result) or f"Cloned {owner}/{name}", owner, name)
            return

        if not (path / ".git").exists():
            raise ValueError("Repository is not cloned yet.")

        if action == "fetch":
            result = run_safe_command(["git", "fetch", "--prune"], cwd=path, timeout=120)
            if not result["ok"]:
                raise ValueError(command_summary(result) or "git fetch failed")
            self.github_result("Fetch complete", command_summary(result) or "Fetch complete.", owner, name)
            return

        if action == "pull":
            result = run_safe_command(["git", "pull", "--ff-only"], cwd=path, timeout=120)
            if not result["ok"]:
                raise ValueError(command_summary(result) or "git pull failed")
            self.github_result("Pull complete", command_summary(result) or "Pull complete.", owner, name)
            return

        require_repo_contribute(repo)

        if action == "branch":
            branch = validate_branch_name(self.field_text(fields, "branch"))
            result = run_safe_command(["git", "checkout", "-b", branch], cwd=path)
            if not result["ok"]:
                raise ValueError(command_summary(result) or "git checkout failed")
            self.github_result("Branch created", command_summary(result) or f"Created {branch}", owner, name)
            return

        if action == "commit":
            require_not_protected_branch(path)
            message = self.field_text(fields, "message").strip()
            if not message:
                raise ValueError("Commit requires a message.")
            status = run_safe_command(["git", "status", "--porcelain"], cwd=path)
            if not status["stdout"].strip():
                raise ValueError("No uncommitted changes to commit.")
            add = run_safe_command(["git", "add", "-A"], cwd=path)
            if not add["ok"]:
                raise ValueError(command_summary(add) or "git add failed")
            commit_message = message + "\n\nGenerated with Hermes in the OASIS container.\nHuman review required before merge."
            commit = run_safe_command(["git", "commit", "-m", commit_message], cwd=path)
            if not commit["ok"]:
                raise ValueError(command_summary(commit) or "git commit failed")
            self.github_result("Commit created", command_summary(commit), owner, name)
            return

        if action == "push":
            branch = require_not_protected_branch(path)
            if not branch:
                raise ValueError("No current branch is checked out.")
            result = run_safe_command(["git", "push", "-u", "origin", branch], cwd=path, timeout=180)
            if not result["ok"]:
                raise ValueError(command_summary(result) or "git push failed")
            self.github_result("Branch pushed", command_summary(result) or f"Pushed {branch}", owner, name)
            return

        if action == "pr":
            branch = require_not_protected_branch(path)
            title = self.field_text(fields, "title").strip() or f"Hermes changes from {branch}"
            body = self.field_text(fields, "body").strip() or "Summary: changes prepared through the Hermes/OASIS container.\n\nTests not run."
            body = body + "\n\nGenerated with Hermes in the OASIS container.\nHuman review required before merge."
            base = str(repo.get("default_branch") or "main")
            result = run_safe_command(["gh", "pr", "create", "--base", base, "--head", branch, "--title", title, "--body", body], cwd=path, timeout=120)
            if not result["ok"]:
                raise ValueError(command_summary(result) or "gh pr create failed")
            self.github_result("Pull request opened", command_summary(result), owner, name)
            return

        self.send_error(404)

    def send_html(self, title: str, body: str, status: int = 200) -> None:
        payload = render_page(title, body, gateway_url=self.gateway_url())
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def send_json(self, data: dict[str, Any], status: int = 200) -> None:
        payload = (json.dumps(data, indent=2, sort_keys=True) + "\n").encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def send_raw(self, root_name: str, rel: str) -> None:
        _, path = safe_path(root_name, rel)
        if path.is_dir():
            self.send_error(400, "Cannot fetch raw directory.")
            return
        content_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
        data = path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def send_container_raw(self, raw_path: str, download: bool = False) -> None:
        path = container_path(raw_path)
        if path.is_dir():
            self.send_error(400, "Cannot fetch raw directory.")
            return
        content_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
        data = path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        if download:
            self.send_header("Content-Disposition", f'attachment; filename="{path.name}"')
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def send_brand(self) -> None:
        candidates = [
            Path("/repo/docs/assets/brand/hermes.png"),
            Path(__file__).resolve().parents[1] / "docs" / "assets" / "brand" / "hermes.png",
        ]
        for candidate in candidates:
            if candidate.exists():
                data = candidate.read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", "image/png")
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)
                return
        self.send_error(404)

    def redirect(self, url: str) -> None:
        self.send_response(303)
        self.send_header("Location", url)
        self.end_headers()


def main() -> int:
    port = int(os.environ.get("HERMES_CMS_PORT", "8090"))
    server = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    print(f"Hermes CMS listening on http://0.0.0.0:{port}")
    print("Allowed roots:")
    for root in ROOTS:
        print(f"  {root.name}: {root.path}")
    server.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
