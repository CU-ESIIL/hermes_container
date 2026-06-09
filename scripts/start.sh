#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

mkdir -p "${HOME}/.hermes" "${repo_root}/workspace"

if [ "$#" -eq 0 ]; then
  docker compose run --rm --service-ports hermes-local
else
  docker compose run --rm --service-ports hermes-local "$@"
fi
