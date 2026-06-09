#!/usr/bin/env python3
"""Build a simple browser-inspectable Hermes output index."""

from __future__ import annotations

import argparse
import html
import json
from datetime import datetime, timezone
from pathlib import Path


def read_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def link_list(job_dir: Path, names: list[str]) -> str:
    links = []
    for name in names:
        path = job_dir / name
        if path.exists():
            links.append(f"<a href='{html.escape(str(path.relative_to(job_dir.parent.parent)))}'>{html.escape(name)}</a>")
    return ", ".join(links) or "none"


def collect_files(job_dir: Path, subdir: str, suffixes: tuple[str, ...]) -> str:
    base = job_dir / subdir
    if not base.exists():
        return "none"
    links = []
    for path in sorted(base.rglob("*")):
        if path.is_file() and path.suffix.lower() in suffixes:
            rel = path.relative_to(job_dir.parent.parent)
            links.append(f"<a href='{html.escape(str(rel))}'>{html.escape(str(path.relative_to(job_dir)))}</a>")
    return ", ".join(links) or "none"


def build_index(data_root: Path) -> Path:
    outputs = data_root / "outputs"
    jobs_root = outputs / "jobs"
    outputs.mkdir(parents=True, exist_ok=True)
    jobs_root.mkdir(parents=True, exist_ok=True)

    rows = []
    for job_dir in sorted([p for p in jobs_root.iterdir() if p.is_dir()]):
        status = read_json(job_dir / "status.json")
        metadata = read_json(job_dir / "metadata.json")
        job_id = status.get("job_id") or job_dir.name
        task_name = status.get("task_name") or metadata.get("task_name") or job_dir.name
        state = status.get("status", "unknown")
        created = status.get("started_at") or metadata.get("created_at") or ""
        rows.append(
            "<tr>"
            f"<td>{html.escape(str(task_name))}</td>"
            f"<td>{html.escape(str(job_id))}</td>"
            f"<td>{html.escape(str(state))}</td>"
            f"<td>{html.escape(str(created))}</td>"
            f"<td>{link_list(job_dir, ['report.html', 'report.md', 'metadata.json', 'status.json', 'logs.txt'])}</td>"
            f"<td>{collect_files(job_dir, 'figures', ('.png', '.jpg', '.jpeg', '.svg'))}</td>"
            f"<td>{collect_files(job_dir, 'tables', ('.csv', '.parquet', '.json'))}</td>"
            f"<td>{collect_files(job_dir, 'maps', ('.html', '.geojson', '.json'))}</td>"
            "</tr>"
        )

    generated = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    html_doc = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Hermes Outputs</title>
  <style>
    body {{ font-family: system-ui, -apple-system, sans-serif; margin: 2rem; color: #161A19; }}
    h1 {{ color: #234A65; }}
    table {{ border-collapse: collapse; width: 100%; }}
    th, td {{ border: 1px solid #E3E3E3; padding: 0.55rem; vertical-align: top; }}
    th {{ background: #234A65; color: white; text-align: left; }}
    a {{ color: #006c8c; }}
    .empty {{ padding: 1rem; border: 1px solid #E3E3E3; }}
  </style>
</head>
<body>
  <h1>Hermes Outputs</h1>
  <p>Generated {html.escape(generated)}. All worker outputs require human review before publication or downstream action.</p>
  {("<div class='empty'>No jobs found under outputs/jobs.</div>" if not rows else "")}
  {("<table><thead><tr><th>Job</th><th>ID</th><th>Status</th><th>Started</th><th>Reports and logs</th><th>Figures</th><th>Tables</th><th>Maps</th></tr></thead><tbody>" + "".join(rows) + "</tbody></table>" if rows else "")}
</body>
</html>
"""
    index = outputs / "index.html"
    index.write_text(html_doc, encoding="utf-8")
    return index


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data-root", default="/data", help="Hermes data root.")
    args = parser.parse_args()
    index = build_index(Path(args.data_root))
    print(index)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
