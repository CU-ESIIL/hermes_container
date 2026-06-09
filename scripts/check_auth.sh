#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="${SECRETS_ENV_FILE:-${repo_root}/.env}"

if [ -f "${env_file}" ]; then
  set -a
  # shellcheck disable=SC1090
  source "${env_file}"
  set +a
fi

present() {
  local value="${1:-}"
  [ -n "${value}" ]
}

status() {
  local name="$1"
  local value="${2:-}"
  if present "${value}"; then
    echo "${name}: configured"
  else
    echo "${name}: missing"
  fi
}

status "Slack bot token" "${SLACK_BOT_TOKEN:-}"
status "Slack app token" "${SLACK_APP_TOKEN:-}"
status "Slack default channel" "${SLACK_DEFAULT_CHANNEL:-}"
status "AI-VERDE base URL" "${VERDE_LLM_BASE_URL:-}"
status "AI-VERDE API key" "${VERDE_LLM_API_KEY:-}"
status "AI-VERDE default model" "${VERDE_LLM_DEFAULT_MODEL:-}"
status "OpenAI API key" "${OPENAI_API_KEY:-}"
status "GitHub token" "${GITHUB_TOKEN:-}"
status "Tavily API key" "${TAVILY_API_KEY:-}"

echo "No secret values were printed."
