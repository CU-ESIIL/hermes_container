#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

if [ ! -f ".env.example" ]; then
  echo "Missing .env.example" >&2
  exit 1
fi

if ! grep -qxF ".env" .gitignore; then
  echo ".gitignore does not contain .env" >&2
  exit 1
fi

if ! grep -qxF ".env.*" .gitignore; then
  echo ".gitignore does not contain .env.*" >&2
  exit 1
fi

if [ ! -x "scripts/check-secrets.sh" ]; then
  echo "scripts/check-secrets.sh is missing or not executable" >&2
  exit 1
fi

tmp_env="$(mktemp)"
trap 'rm -f "${tmp_env}"' EXIT

set +e
output="$(
  env -u SLACK_BOT_TOKEN -u SLACK_APP_TOKEN -u SLACK_DEFAULT_CHANNEL \
    SECRETS_ENV_FILE="${tmp_env}" \
    scripts/check-secrets.sh 2>&1
)"
exit_code="$?"
set -e

if [ "${exit_code}" -eq 0 ]; then
  echo "Secret check unexpectedly passed with missing Slack tokens" >&2
  exit 1
fi

if ! grep -q "Slack secret validation failed" <<< "${output}"; then
  echo "Secret check did not fail gracefully" >&2
  echo "${output}" >&2
  exit 1
fi

if grep -Eq 'xoxb-[A-Za-z0-9-]{8,}|xapp-[A-Za-z0-9-]{8,}' <<< "${output}"; then
  echo "Secret check output appears to contain an unmasked Slack token" >&2
  exit 1
fi

echo "Secret smoke test passed."
