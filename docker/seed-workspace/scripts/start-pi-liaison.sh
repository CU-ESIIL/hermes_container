#!/usr/bin/env bash
set -Eeuo pipefail

workspace="${HERMES_WORKSPACE:-${WORKSPACE_DIR:-/workspace}}"
template_root="${HERMES_SEED_DIR:-/opt/hermes/seed-workspace}"
prompt_path="${workspace}/prompts/pi-liaison-startup.md"
init_script="${workspace}/scripts/init-working-group.sh"

if [ -x "${init_script}" ]; then
  "${init_script}" --workspace "${workspace}" --template-root "${template_root}"
elif [ -f "${template_root}/scripts/init-working-group.sh" ]; then
  bash "${template_root}/scripts/init-working-group.sh" --workspace "${workspace}" --template-root "${template_root}"
else
  echo "Working group initializer not found." >&2
  exit 1
fi

cat <<EOF

Hermes Scientific Working Group
PI Liaison is the default human-facing workflow prompt.

If you want the PI Liaison startup flow, open Hermes Agent and begin with:

  ${prompt_path}

EOF

if [ -f "${prompt_path}" ]; then
  sed -n '1,220p' "${prompt_path}"
fi

exec hermes chat
