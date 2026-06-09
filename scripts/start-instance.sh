#!/usr/bin/env bash
set -Eeuo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <instance-name> [gateway-port] [workspace-ui-port] [cms-port]" >&2
  echo "Example: $0 project-two 18790 8889 8091" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

instance_name="$1"
gateway_port="${2:-18790}"
workspace_ui_port="${3:-8889}"
cms_port="${4:-8091}"
instance_root="${repo_root}/instances/${instance_name}"

mkdir -p \
  "${instance_root}/data" \
  "${instance_root}/workspace" \
  "${instance_root}/external_storage" \
  "${instance_root}/runtime"

project_name="hermes-${instance_name}"

compose_args=(
  --project-name "${project_name}"
)

secret_file="${HERMES_GITHUB_TOKEN_FILE:-${repo_root}/secrets/github_token}"
if [ "${HERMES_USE_SECRETS_OVERLAY:-0}" = "1" ] || [ -f "${secret_file}" ]; then
  export HERMES_GITHUB_TOKEN_FILE="${secret_file}"
  compose_args+=(
    -f docker-compose.yml
    -f docker-compose.secrets.yml
  )
fi

export HERMES_CONTAINER_NAME="hermes-${instance_name}"
export DATA_DIR="${instance_root}/data"
export WORKSPACE_DIR="${instance_root}/workspace"
export EXTERNAL_STORAGE_DIR="${instance_root}/external_storage"
if [ -z "${HERMES_STATE_DIR:-}" ]; then
  runtime_parent="${HERMES_RUNTIME_ROOT:-}"
  if [ -z "${runtime_parent}" ]; then
    if [ -d /private/tmp ] && [ -w /private/tmp ]; then
      runtime_parent="/private/tmp"
    else
      runtime_parent="${RUNNER_TEMP:-/tmp}"
    fi
  fi

  if [ ! -d "${runtime_parent}" ] || [ ! -w "${runtime_parent}" ]; then
    fallback_parent="${RUNNER_TEMP:-/tmp}"
    if [ ! -d "${fallback_parent}" ] || [ ! -w "${fallback_parent}" ]; then
      fallback_parent="/tmp"
    fi
    echo "Warning: HERMES_RUNTIME_ROOT='${runtime_parent}' is unavailable; using '${fallback_parent}' instead." >&2
    runtime_parent="${fallback_parent}"
  fi

  export HERMES_STATE_DIR="${runtime_parent%/}/hermes-${instance_name}"
else
  export HERMES_STATE_DIR
fi
export HERMES_PORT="${gateway_port}"
export WORKSPACE_UI_PORT="${workspace_ui_port}"
workspace_ui_token="${WORKSPACE_UI_TOKEN:-hermes}"
export HERMES_CMS_PORT="${cms_port}"
mkdir -p "${HERMES_STATE_DIR}"

docker compose "${compose_args[@]}" up -d hermes-local workspace-ui workspace-cms
gateway_container_id="$(docker compose "${compose_args[@]}" ps -q hermes-local)"

cat <<EOF
Hermes instance '${instance_name}' started.

Gateway container: ${gateway_container_id}
Gateway:          http://127.0.0.1:${gateway_port}
Workspace UI:     http://127.0.0.1:${workspace_ui_port}/lab?token=${workspace_ui_token}
Workspace CMS:    http://127.0.0.1:${cms_port}
GitHub manager:   http://127.0.0.1:${cms_port}/github

Instance files:
  ${instance_root}

Validate before project work:
  docker exec ${gateway_container_id} hermes --version
  docker exec ${gateway_container_id} hermes status

Expected: Hermes Agent is installed and the local dashboard/gateway is reachable.
EOF
