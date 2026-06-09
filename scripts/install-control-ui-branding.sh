#!/usr/bin/env bash
set -Eeuo pipefail

control_ui_dir="${OPENCLAW_CONTROL_UI_DIR:-/usr/local/lib/node_modules/openclaw/dist/control-ui}"
brand_dir="${HERMES_BRANDING_DIR:-/opt/hermes/branding/control-ui}"
asset_dir="${HERMES_BRANDING_ASSET_DIR:-/opt/hermes/branding/assets}"

if [ ! -d "${control_ui_dir}" ]; then
  echo "Control UI directory not found: ${control_ui_dir}" >&2
  exit 1
fi

if [ ! -d "${brand_dir}" ]; then
  echo "Hermes branding directory not found: ${brand_dir}" >&2
  exit 1
fi

copy_if_present() {
  local src="$1"
  local dest="$2"
  if [ -f "${src}" ]; then
    cp "${src}" "${dest}"
  fi
}

copy_if_present "${brand_dir}/hermes-brand.css" "${control_ui_dir}/hermes-brand.css"
copy_if_present "${brand_dir}/hermes-brand.js" "${control_ui_dir}/hermes-brand.js"
copy_if_present "${brand_dir}/favicon.svg" "${control_ui_dir}/favicon.svg"
copy_if_present "${asset_dir}/hermes.svg" "${control_ui_dir}/hermes-icon.svg"

python3 - "${control_ui_dir}/hermes-config.js" <<'PY'
from pathlib import Path
import json
import os
import re
import sys

path = Path(sys.argv[1])
default_title = "OASIS Hermes Working Group"


def configured_title():
    value = os.environ.get("HERMES_PROJECT_TITLE", "").strip()
    if value and value != default_title:
        return value
    return ""


def charter_title():
    workspace = Path(os.environ.get("OPENCLAW_WORKSPACE", "/workspace"))
    charter_path = workspace / "PROJECT_CHARTER.md"
    try:
        text = charter_path.read_text()
    except OSError:
        return ""

    match = re.search(r"(?ims)^##\s+Project title\s+`([^`]+)`", text)
    if not match:
        match = re.search(r"(?ims)^##\s+Project title\s+(.+?)(?:\n##|\Z)", text)
    if not match:
        return ""

    title = re.sub(r"[\r\n]+", " ", match.group(1)).strip(" `\t")
    if not title or title.lower() in {"[to be provided]", "to be provided", "tbd"}:
        return ""
    return title


config = {
    "projectTitle": configured_title() or charter_title() or default_title,
    "cmsPort": os.environ.get("HERMES_CMS_PORT", "8090"),
}
path.write_text(
    "window.HERMES_CONFIG = "
    + json.dumps(config, ensure_ascii=True)
    + ";\n"
    + "window.HERMES_PROJECT_TITLE = window.HERMES_CONFIG.projectTitle;\n"
)
PY

index_path="${control_ui_dir}/index.html"
if [ -f "${index_path}" ]; then
  python3 - "${index_path}" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
html = path.read_text()
html = html.replace("<title>OpenClaw Control</title>", "<title>Hermes</title>")

css = '    <link rel="stylesheet" href="./hermes-brand.css" />'
config_js = '    <script defer src="./hermes-config.js"></script>'
js = '    <script defer src="./hermes-brand.js?v=20260524d"></script>'

if "hermes-brand.css" not in html:
    marker = '</head>'
    html = html.replace(marker, f"{css}\n{marker}")
if "hermes-config.js" not in html:
    marker = '    <script defer src="./hermes-brand.js"></script>'
    if marker in html:
        html = html.replace(marker, f"{config_js}\n{marker}")
    else:
        html = html.replace('</head>', f"{config_js}\n</head>")
html = re.sub(
    r'    <script defer src="\./hermes-brand\.js(?:\?v=[^"]*)?"></script>',
    js,
    html,
)

if "hermes-brand.js" not in html:
    marker = '</head>'
    html = html.replace(marker, f"{js}\n{marker}")

path.write_text(html)
PY
fi

manifest_path="${control_ui_dir}/manifest.webmanifest"
if [ -f "${manifest_path}" ]; then
  python3 - "${manifest_path}" <<'PY'
from pathlib import Path
import json
import sys

path = Path(sys.argv[1])
try:
    data = json.loads(path.read_text())
except Exception:
    data = {}

data["name"] = "OASIS Hermes"
data["short_name"] = "Hermes"
data["description"] = "ESIIL's multi-agent workspace"
data["theme_color"] = "#234a65"
data["background_color"] = "#f7faf9"

icons = data.get("icons")
if isinstance(icons, list):
    for icon in icons:
        if isinstance(icon, dict) and icon.get("src") in {"./favicon.svg", "./favicon-32.png", "./apple-touch-icon.png"}:
            continue
else:
    data["icons"] = [
        {"src": "./favicon.svg", "sizes": "any", "type": "image/svg+xml", "purpose": "any"},
    ]

path.write_text(json.dumps(data, indent=2) + "\n")
PY
fi

python3 - "${control_ui_dir}" <<'PY'
from pathlib import Path
import os
import re
import sys

control_ui_dir = Path(sys.argv[1])
cms_port = os.environ.get("HERMES_CMS_PORT", "8090")
cms_origins = [
    f"http://127.0.0.1:{cms_port}",
    f"http://localhost:{cms_port}",
]

for path in control_ui_dir.parent.glob("control-ui-*.js"):
    text = path.read_text()
    original = text

    def widen_connect_src(match: re.Match[str]) -> str:
        directive = match.group(1)
        for origin in cms_origins:
            if origin not in directive:
                directive += f" {origin}"
        return f'"{directive}"'

    text = re.sub(
        r'"(connect-src [^"]*)"',
        widen_connect_src,
        text,
        count=1,
    )
    if text != original:
        path.write_text(text)
PY

echo "Installed OASIS Hermes Control UI branding into ${control_ui_dir}"
