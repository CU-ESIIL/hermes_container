#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="${repo_root}/.env"
profile="interactive"
noninteractive=0

usage() {
  cat <<'EOF'
Usage: scripts/setup_env.sh [--profile local-only|slack-verde] [--noninteractive]

Create .env from .env.example when missing and optionally prompt for local values.
Secrets are never printed back to the terminal.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile)
      profile="$2"
      shift 2
      ;;
    --noninteractive)
      noninteractive=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ ! -f "${env_file}" ]; then
  cp "${repo_root}/.env.example" "${env_file}"
  chmod 600 "${env_file}" || true
  echo "Created .env from .env.example"
else
  echo ".env already exists; leaving existing values in place."
fi

set_env_value() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" "${env_file}"; then
    perl -0pi -e "s/^${key}=.*$/${key}=${value}/m" "${env_file}"
  else
    printf '%s=%s\n' "${key}" "${value}" >> "${env_file}"
  fi
}

prompt_secret() {
  local key="$1"
  local label="$2"
  local value
  printf "%s (leave blank to skip): " "${label}"
  IFS= read -rs value || true
  printf "\n"
  if [ -n "${value}" ]; then
    set_env_value "${key}" "${value}"
    echo "${key}: configured"
  else
    echo "${key}: skipped"
  fi
}

prompt_value() {
  local key="$1"
  local label="$2"
  local default="${3:-}"
  local value
  printf "%s [%s]: " "${label}" "${default}"
  IFS= read -r value || true
  value="${value:-${default}}"
  if [ -n "${value}" ]; then
    set_env_value "${key}" "${value}"
    echo "${key}: set"
  fi
}

if [ "${noninteractive}" -eq 1 ]; then
  case "${profile}" in
    local-only)
      set_env_value OPENCLAW_START_PI_LIAISON 0
      ;;
    slack-verde)
      set_env_value VERDE_LLM_BASE_URL "https://llm-api.cyverse.ai/v1"
      set_env_value VERDE_LLM_PROVIDER_NAME "verde"
      ;;
  esac
  echo "Noninteractive setup complete for profile: ${profile}"
  exit 0
fi

echo "Hermes environment setup"
echo "Profile: ${profile}"
echo "Press Enter to skip optional values."

case "${profile}" in
  local-only)
    prompt_value WORKSPACE_UI_PORT "Workspace UI port" "8888"
    ;;
  slack-verde|interactive)
    prompt_secret SLACK_BOT_TOKEN "Slack bot token"
    prompt_secret SLACK_APP_TOKEN "Slack Socket Mode app token"
    prompt_value SLACK_DEFAULT_CHANNEL "Slack default channel" "#science-working-group"
    prompt_value VERDE_LLM_BASE_URL "AI-VERDE base URL" "https://llm-api.cyverse.ai/v1"
    prompt_secret VERDE_LLM_API_KEY "AI-VERDE API key"
    prompt_value VERDE_LLM_DEFAULT_MODEL "AI-VERDE default model" ""
    ;;
  *)
    echo "Unknown profile: ${profile}" >&2
    exit 2
    ;;
esac

echo "Environment setup complete. Run scripts/check_auth.sh to inspect configured integrations."
