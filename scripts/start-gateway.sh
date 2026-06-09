#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

mkdir -p "${HOME}/.hermes" "${repo_root}/workspace"

docker compose up -d hermes-local

container_id="$(docker compose ps -q hermes-local)"
echo "Hermes Agent container started: ${container_id}"
echo "Open: http://127.0.0.1:${HERMES_PORT:-18789}/"
