#!/usr/bin/env bash
set -Eeuo pipefail

data_root="${DATA_ROOT:-/data}"
workspace="${HERMES_WORKSPACE:-${WORKSPACE_DIR:-/data/workspace}}"
hermes_home="${HERMES_HOME:-${HERMES_STATE_DIR:-/data/.hermes}}"
seed_dir="${HERMES_SEED_DIR:-/opt/hermes/seed-workspace}"

export HERMES_HOME="${hermes_home}"
export HERMES_STATE_DIR="${hermes_home}"
export HERMES_WORKSPACE="${workspace}"
export WORKSPACE_DIR="${workspace}"

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
  OPENAI_API_KEY \
  VERDE_LLM_API_KEY \
  AI_VERDE_API_KEY \
  NOUS_API_KEY \
  OPENROUTER_API_KEY \
  ANTHROPIC_API_KEY \
  GITHUB_TOKEN \
  GH_TOKEN \
  TAVILY_API_KEY; do
  load_secret_file_var "${secret_name}"
done

if [ -z "${OPENAI_API_KEY:-}" ] && [ -n "${VERDE_LLM_API_KEY:-}" ]; then
  export OPENAI_API_KEY="${VERDE_LLM_API_KEY}"
elif [ -z "${OPENAI_API_KEY:-}" ] && [ -n "${AI_VERDE_API_KEY:-}" ]; then
  export OPENAI_API_KEY="${AI_VERDE_API_KEY}"
fi

if [ -z "${OPENAI_BASE_URL:-}" ] && [ -n "${VERDE_LLM_BASE_URL:-}" ]; then
  export OPENAI_BASE_URL="${VERDE_LLM_BASE_URL}"
fi

if [ -z "${GH_TOKEN:-}" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
  export GH_TOKEN="${GITHUB_TOKEN}"
fi
if [ -z "${GITHUB_TOKEN:-}" ] && [ -n "${GH_TOKEN:-}" ]; then
  export GITHUB_TOKEN="${GH_TOKEN}"
fi

configure_github_cli() {
  [ "${HERMES_CONFIGURE_GITHUB:-1}" != "0" ] || return 0
  [ -n "${GH_TOKEN:-}" ] || return 0
  command -v gh >/dev/null 2>&1 || return 0

  mkdir -p "${HOME:-/root}/.config/gh" || true
  gh auth setup-git >/tmp/hermes-gh-setup.log 2>&1 || {
    echo "GitHub CLI git credential setup did not complete. Recent log:" >&2
    sed -E 's/(gh[pousr]_|github_pat_)[A-Za-z0-9_]+/\1****REDACTED/g' /tmp/hermes-gh-setup.log | tail -n 40 >&2
    echo "Continuing with environment-backed GH_TOKEN and explicit git credential helper." >&2
  }
  git config --global credential.https://github.com.helper '!gh auth git-credential' 2>/dev/null || true
  git config --global credential.https://gist.github.com.helper '!gh auth git-credential' 2>/dev/null || true
}

if command -v hermes-init-data-layout >/dev/null 2>&1; then
  hermes-init-data-layout --data-root "${data_root}" >/tmp/hermes-data-layout.log 2>&1 || {
    echo "Hermes data layout initialization failed. Recent log:" >&2
    tail -n 80 /tmp/hermes-data-layout.log >&2
    exit 1
  }
fi

mkdir -p \
  "${hermes_home}" \
  "${data_root}/logs" \
  "${workspace}" \
  /workspace \
  /external_storage/local

if [ "${HERMES_SEED_WORKSPACE:-1}" != "0" ] && [ -d "${seed_dir}" ]; then
  find "${seed_dir}" -type f | while IFS= read -r src; do
    rel="${src#${seed_dir}/}"
    dest="${workspace}/${rel}"
    mkdir -p "$(dirname "${dest}")"
    if [ ! -e "${dest}" ]; then
      cp "${src}" "${dest}"
    fi
  done
fi

if [ "${HERMES_INIT_WORKING_GROUP:-1}" != "0" ]; then
  init_script="${workspace}/scripts/init-working-group.sh"
  if [ -f "${init_script}" ]; then
    chmod +x "${init_script}" || true
    "${init_script}" --workspace "${workspace}" --template-root "${seed_dir}"
  elif [ -f "${seed_dir}/scripts/init-working-group.sh" ]; then
    bash "${seed_dir}/scripts/init-working-group.sh" --workspace "${workspace}" --template-root "${seed_dir}"
  fi
fi

if [ "${HERMES_SEED_FILE_MANAGER_DEMO:-1}" != "0" ] && command -v hermes-seed-file-manager-demo >/dev/null 2>&1; then
  hermes-seed-file-manager-demo --workspace "${workspace}" >/tmp/hermes-file-manager-demo.log 2>&1 || {
    echo "Hermes file-manager demo seeding failed. Recent log:" >&2
    tail -n 80 /tmp/hermes-file-manager-demo.log >&2
    exit 1
  }
fi

git config --global --add safe.directory /workspace 2>/dev/null || true
git config --global --add safe.directory /data/workspace 2>/dev/null || true
git config --global --add safe.directory '/data/workspace/repos/*' 2>/dev/null || true
configure_github_cli

cd "${workspace}"
exec "$@"
