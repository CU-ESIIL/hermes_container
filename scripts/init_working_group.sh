#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace="${HERMES_WORKSPACE_DIR:-${WORKSPACE_DIR:-${repo_root}/workspace}}"
template_root="${HERMES_TEMPLATE_ROOT:-${repo_root}/docker/seed-workspace}"

if [ ! -f "${template_root}/scripts/init-working-group.sh" ]; then
  echo "Missing template init script: ${template_root}/scripts/init-working-group.sh" >&2
  exit 1
fi

mkdir -p "${workspace}"
bash "${template_root}/scripts/init-working-group.sh" --workspace "${workspace}" --template-root "${template_root}"

echo
echo "Initialized OASIS Hermes working group workspace:"
echo "  ${workspace}"
echo
echo "Next safe checks:"
echo "  make doctor"
echo "  make checkpoint"

