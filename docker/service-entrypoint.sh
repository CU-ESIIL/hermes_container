#!/usr/bin/env bash
set -Eeuo pipefail

load_secret_file_var() {
  local name="$1"
  local file_var="${name}_FILE"
  local file_path="${!file_var:-}"
  local value

  if [ -n "${!name:-}" ] || [ -z "${file_path}" ]; then
    return 0
  fi
  if [ ! -r "${file_path}" ]; then
    echo "Secret file for ${name} is not readable: ${file_path}" >&2
    exit 1
  fi
  value="$(head -n 1 "${file_path}" | tr -d '\r\n')"
  export "${name}=${value}"
}

for secret_name in \
  GITHUB_TOKEN \
  GH_TOKEN; do
  load_secret_file_var "${secret_name}"
done

if [ -z "${GH_TOKEN:-}" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
  export GH_TOKEN="${GITHUB_TOKEN}"
fi
if [ -z "${GITHUB_TOKEN:-}" ] && [ -n "${GH_TOKEN:-}" ]; then
  export GITHUB_TOKEN="${GH_TOKEN}"
fi

if [ "${HERMES_CONFIGURE_GITHUB:-1}" != "0" ] \
  && [ -n "${GH_TOKEN:-}" ] \
  && command -v gh >/dev/null 2>&1; then
  gh auth setup-git >/tmp/hermes-gh-setup.log 2>&1 || {
    echo "GitHub CLI git credential setup did not complete. Recent log:" >&2
    sed -E 's/(gh[pousr]_|github_pat_)[A-Za-z0-9_]+/\1****REDACTED/g' /tmp/hermes-gh-setup.log | tail -n 40 >&2
    echo "Continuing with environment-backed GH_TOKEN and explicit git credential helper." >&2
  }
  git config --global credential.https://github.com.helper '!gh auth git-credential' 2>/dev/null || true
  git config --global credential.https://gist.github.com.helper '!gh auth git-credential' 2>/dev/null || true
fi

git config --global --add safe.directory /workspace 2>/dev/null || true
git config --global --add safe.directory /data/workspace 2>/dev/null || true
git config --global --add safe.directory '/workspace/repos/*' 2>/dev/null || true
git config --global --add safe.directory '/data/workspace/repos/*' 2>/dev/null || true

exec "$@"
