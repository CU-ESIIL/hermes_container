#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

mkdir -p "${HOME}/.openclaw" "${repo_root}/workspace"

if [ "${OPENCLAW_START_PI_LIAISON:-1}" != "0" ]; then
  case "${1:-}" in
    ""|bash|/bin/bash|sh|/bin/sh)
      "${repo_root}/scripts/check-secrets.sh"
      ;;
  esac
fi

if [ "$#" -eq 0 ]; then
  docker compose run --rm --service-ports hermes-local
else
  docker compose run --rm --service-ports hermes-local "$@"
fi
