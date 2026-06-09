#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
task_path="${1:-}"

usage() {
  cat <<'EOF'
Usage: scripts/run_worker_local.sh TASK.yaml [--offline]

Run a bounded Hermes spatiotemporal worker task locally.

The script prefers Docker so local execution resembles a Kubernetes Job. Set
HERMES_WORKER_MODE=direct to run the Python worker directly for debugging.
EOF
}

offline=0
if [ -z "${task_path}" ] || [ "${task_path}" = "-h" ] || [ "${task_path}" = "--help" ]; then
  usage
  exit 0
fi
shift || true
while [ "$#" -gt 0 ]; do
  case "$1" in
    --offline)
      offline=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "${task_path}" != /* ]]; then
  task_path="${repo_root}/${task_path}"
fi
if [ ! -f "${task_path}" ]; then
  echo "Task file not found: ${task_path}" >&2
  exit 1
fi

mkdir -p "${repo_root}/data" "${repo_root}/workspace"

worker_image="${HERMES_WORKER_IMAGE:-hermes-spatiotemporal-worker:local}"
worker_mode="${HERMES_WORKER_MODE:-docker}"
container_task="/data/workspace/.hermes-tasks/$(basename "${task_path}")"
mkdir -p "${repo_root}/workspace/.hermes-tasks"
cp "${task_path}" "${repo_root}/workspace/.hermes-tasks/$(basename "${task_path}")"

if [ "${worker_mode}" = "direct" ]; then
  direct_output="${repo_root}/data/outputs/jobs/$(basename "${task_path%.*}")-direct"
  args=(python3 "${repo_root}/workers/spatiotemporal-worker/run_task.py" --task "${task_path}" --output-dir "${direct_output}")
  if [ "${offline}" -eq 1 ]; then
    args+=(--offline)
  fi
  "${args[@]}"
  python3 "${repo_root}/scripts/build_output_index.py" --data-root "${repo_root}/data"
  exit 0
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not available; falling back to direct Python mode." >&2
  if [ "${offline}" -eq 1 ]; then
    HERMES_WORKER_MODE=direct "$0" "${task_path}" --offline
  else
    HERMES_WORKER_MODE=direct "$0" "${task_path}"
  fi
  exit $?
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not reachable; falling back to direct Python mode." >&2
  if [ "${offline}" -eq 1 ]; then
    HERMES_WORKER_MODE=direct "$0" "${task_path}" --offline
  else
    HERMES_WORKER_MODE=direct "$0" "${task_path}"
  fi
  exit $?
fi

if ! docker image inspect "${worker_image}" >/dev/null 2>&1; then
  docker build \
    -f "${repo_root}/workers/spatiotemporal-worker/Dockerfile" \
    -t "${worker_image}" \
    "${repo_root}"
fi

docker_args=(
  run
  --rm
  --name "hermes-worker-$(date -u +%Y%m%d%H%M%S)"
  --cpus "${HERMES_WORKER_CPUS:-2}"
  --memory "${HERMES_WORKER_MEMORY:-4g}"
  -e "HERMES_WORKER_IMAGE=${worker_image}"
  -v "${repo_root}/data:/data"
  -v "${repo_root}/workspace:/data/workspace"
  -v "${repo_root}/workspace:/workspace"
  "${worker_image}"
  --task "${container_task}"
)

if [ "${offline}" -eq 1 ]; then
  docker_args+=("--offline")
fi

docker "${docker_args[@]}"
python3 "${repo_root}/scripts/build_output_index.py" --data-root "${repo_root}/data"
