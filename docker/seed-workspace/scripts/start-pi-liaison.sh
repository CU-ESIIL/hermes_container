#!/usr/bin/env bash
set -Eeuo pipefail

workspace="${OPENCLAW_WORKSPACE:-${WORKSPACE_DIR:-/workspace}}"
template_root="${OPENCLAW_TEMPLATE_ROOT:-/opt/openclaw/seed-workspace}"
session="${OPENCLAW_PI_LIAISON_SESSION:-main}"
prompt_path="${workspace}/prompts/pi-liaison-startup.md"
init_script="${workspace}/scripts/init-working-group.sh"
check_secrets_script="${workspace}/scripts/check-secrets.sh"
config_dir="${OPENCLAW_CONFIG_DIR:-/root/.openclaw}"
config_path="${OPENCLAW_CONFIG_PATH:-${config_dir}/openclaw.json}"
gateway_port="${OPENCLAW_GATEWAY_PORT:-18789}"
gateway_bind="${OPENCLAW_GATEWAY_BIND:-lan}"
gateway_auth="${OPENCLAW_GATEWAY_AUTH_MODE:-token}"
gateway_url="${OPENCLAW_GATEWAY_URL:-ws://127.0.0.1:${gateway_port}}"

if [ -x "${init_script}" ]; then
  "${init_script}" --workspace "${workspace}" --template-root "${template_root}"
elif [ -f "${template_root}/scripts/init-working-group.sh" ]; then
  bash "${template_root}/scripts/init-working-group.sh" --workspace "${workspace}" --template-root "${template_root}"
else
  echo "Working group initializer not found." >&2
  exit 1
fi

if [ ! -f "${prompt_path}" ]; then
  echo "PI Liaison startup prompt not found: ${prompt_path}" >&2
  exit 1
fi

if [ ! -x "${check_secrets_script}" ]; then
  echo "Slack secret checker not found or not executable: ${check_secrets_script}" >&2
  exit 1
fi

"${check_secrets_script}"

prompt="$(cat "${prompt_path}")"
gateway_token="${OPENCLAW_GATEWAY_TOKEN:-}"
if [ -z "${gateway_token}" ] && [ -f "${config_path}" ]; then
  gateway_token="$(
    node -e '
      const fs = require("fs");
      const path = process.argv[1];
      try {
        const config = JSON.parse(fs.readFileSync(path, "utf8"));
        process.stdout.write(config.gateway?.auth?.token || "");
      } catch {
        process.stdout.write("");
      }
    ' "${config_path}"
  )"
fi

cat <<EOF

OpenClaw Scientific Working Group
PI Liaison is the default human-facing agent.

The PI Liaison will interview you, draft PROJECT_CHARTER.md and TEAM_BRIEF.md,
collect team questions in QUESTIONS_FOR_USER.md, and bring you batched review
requests instead of letting every role interrupt you.

EOF

if [ "${OPENCLAW_PI_LIAISON_START_GATEWAY:-1}" != "0" ]; then
  mkdir -p "${workspace}/logs"
  gateway_args=(gateway --bind "${gateway_bind}" --port "${gateway_port}" --auth "${gateway_auth}")
  if [ "${gateway_auth}" = "token" ] && [ -n "${gateway_token}" ]; then
    gateway_args+=(--token "${gateway_token}")
  fi
  gateway_args+=(run --force)

  openclaw "${gateway_args[@]}" >"${workspace}/logs/openclaw-gateway.log" 2>&1 &
  echo "Starting OpenClaw Gateway on ${gateway_url}; logs: ${workspace}/logs/openclaw-gateway.log"
  sleep "${OPENCLAW_PI_LIAISON_GATEWAY_WAIT_SECONDS:-2}"
fi

if [ -n "${OPENCLAW_PI_LIAISON_AGENT_ID:-}" ] && openclaw agent --help 2>/dev/null | grep -q -- "--agent"; then
  exec openclaw agent \
    --agent "${OPENCLAW_PI_LIAISON_AGENT_ID}" \
    --session-id "${session}" \
    --message "${prompt}"
fi

if openclaw tui --help 2>/dev/null | grep -q -- "--message"; then
  tui_args=(tui --session "${session}" --url "${gateway_url}" --message "${prompt}")
  if [ "${gateway_auth}" = "token" ] && [ -n "${gateway_token}" ]; then
    tui_args+=(--token "${gateway_token}")
  fi
  exec openclaw "${tui_args[@]}"
fi

cat <<EOF
OpenClaw did not advertise a supported startup-message option.
Start OpenClaw normally, then begin with the PI Liaison prompt:

  ${prompt_path}

EOF

exec openclaw chat
