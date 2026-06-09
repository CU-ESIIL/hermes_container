#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

mkdir -p "${HOME}/.openclaw" "${repo_root}/workspace"

docker compose run --rm hermes-local \
  openclaw models auth login --provider openai-codex --set-default "$@"

# Fallback for upstream runtime versions that document onboarding as the Codex OAuth path:
# docker compose run --rm hermes-local \
#   openclaw onboard --auth-choice openai-codex
