#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace="${HERMES_WORKSPACE_DIR:-${WORKSPACE_DIR:-${repo_root}/workspace}}"
checkpoint_file="${HERMES_CHECKPOINT_FILE:-${workspace}/CHECKPOINT.md}"
timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

mkdir -p "$(dirname "${checkpoint_file}")"

git_branch="$(cd "${repo_root}" && git branch --show-current 2>/dev/null || echo unknown)"
git_status="$(cd "${repo_root}" && git status --short 2>/dev/null || true)"

{
  echo "# Hermes Checkpoint"
  echo
  echo "- Created: ${timestamp}"
  echo "- Repository: $(basename "${repo_root}")"
  echo "- Branch: ${git_branch:-unknown}"
  echo "- Workspace: ${workspace}"
  echo
  echo "## What changed"
  echo
  echo "- [ ] Summarize changes from this work session."
  echo
  echo "## Decisions to record"
  echo
  echo "- [ ] Add any durable decisions to DECISIONS.md."
  echo
  echo "## Tasks to update"
  echo
  echo "- [ ] Update active tasks, blocked questions, or next actions."
  echo
  echo "## Files to preserve"
  echo
  echo "- [ ] Confirm important files are in git, the mounted workspace, a volume, or external storage."
  echo
  echo "## Git status at checkpoint"
  echo
  echo '```text'
  if [ -n "${git_status}" ]; then
    echo "${git_status}"
  else
    echo "No local git changes detected."
  fi
  echo '```'
  echo
  echo "## Suggested commit message"
  echo
  echo '```text'
  echo "Update OASIS Hermes working group template"
  echo '```'
} > "${checkpoint_file}"

echo "Wrote checkpoint:"
echo "  ${checkpoint_file}"
echo
echo "Review the checkpoint, then update decisions/tasks if needed."

