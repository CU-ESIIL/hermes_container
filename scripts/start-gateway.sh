#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

mkdir -p "${HOME}/.openclaw" "${repo_root}/workspace"

"${repo_root}/scripts/check-secrets.sh"

container_id="$(
  docker compose run -d \
    --service-ports \
    -e OPENCLAW_START_PI_LIAISON=0 \
    hermes-local \
    openclaw gateway run --force
)"

echo "Hermes gateway container started: ${container_id}"
echo "Probe Slack health with:"
echo "  docker exec ${container_id} openclaw channels status --channel slack --probe --timeout 20000"
