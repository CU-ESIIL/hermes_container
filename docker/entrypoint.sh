#!/usr/bin/env bash
set -Eeuo pipefail

config_dir="${OPENCLAW_CONFIG_DIR:-/root/.openclaw}"
config_path="${OPENCLAW_CONFIG_PATH:-${config_dir}/openclaw.json}"
workspace="${OPENCLAW_WORKSPACE:-/workspace}"
seed_dir="/opt/openclaw/seed-workspace"
data_root="${DATA_ROOT:-/data}"

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
  SLACK_BOT_TOKEN \
  SLACK_APP_TOKEN \
  OPENAI_API_KEY \
  VERDE_LLM_API_KEY \
  AI_VERDE_API_KEY \
  GITHUB_TOKEN \
  GH_TOKEN \
  TAVILY_API_KEY; do
  load_secret_file_var "${secret_name}"
done

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
  git config --global --add safe.directory /workspace 2>/dev/null || true
  git config --global --add safe.directory /data/workspace 2>/dev/null || true
  git config --global --add safe.directory '/data/workspace/repos/*' 2>/dev/null || true
}

if command -v hermes-init-data-layout >/dev/null 2>&1; then
  hermes-init-data-layout --data-root "${data_root}" >/tmp/hermes-data-layout.log 2>&1 || {
    echo "Hermes data layout initialization failed. Recent log:" >&2
    tail -n 80 /tmp/hermes-data-layout.log >&2
    exit 1
  }
fi

if [ "${HERMES_BRANDING:-1}" != "0" ] && command -v hermes-install-control-ui-branding >/dev/null 2>&1; then
  hermes-install-control-ui-branding >/tmp/hermes-branding.log 2>&1 || {
    echo "Hermes Control UI branding failed. Recent log:" >&2
    tail -n 80 /tmp/hermes-branding.log >&2
    exit 1
  }
fi

mkdir -p \
  "${config_dir}" \
  "${config_dir}/auth-profile-secrets" \
  "${config_dir}/agents/main/sessions" \
  "${data_root}/logs" \
  "${workspace}"

if [ "${OPENCLAW_SEED_WORKSPACE:-1}" != "0" ] && [ -d "${seed_dir}" ]; then
  find "${seed_dir}" -type f | while IFS= read -r src; do
    rel="${src#${seed_dir}/}"
    dest="${workspace}/${rel}"
    mkdir -p "$(dirname "${dest}")"
    if [ ! -e "${dest}" ]; then
      cp "${src}" "${dest}"
    fi
  done
fi

if [ "${OPENCLAW_INIT_WORKING_GROUP:-1}" != "0" ]; then
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

if [ "${HERMES_BRANDING:-1}" != "0" ] && command -v hermes-install-control-ui-branding >/dev/null 2>&1; then
  hermes-install-control-ui-branding >/tmp/hermes-branding.log 2>&1 || {
    echo "Hermes Control UI branding failed. Recent log:" >&2
    tail -n 80 /tmp/hermes-branding.log >&2
    exit 1
  }
fi

node <<'NODE'
const fs = require("fs");
const crypto = require("crypto");

const configPath = process.env.OPENCLAW_CONFIG_PATH || `${process.env.OPENCLAW_CONFIG_DIR || "/root/.openclaw"}/openclaw.json`;
const workspace = process.env.OPENCLAW_WORKSPACE || "/workspace";
const defaultModel = process.env.OPENCLAW_MODEL || process.env.OPENCLAW_DEFAULT_MODEL || "codex/gpt-5.5";
const verdeProviderName = process.env.VERDE_LLM_PROVIDER_NAME || "verde";
const verdeApiKey = process.env.VERDE_LLM_API_KEY || process.env.AI_VERDE_API_KEY || "";
const verdeBaseUrl = process.env.VERDE_LLM_BASE_URL || "https://llm-api.cyverse.ai/v1";
const verdeDefaultModel = process.env.VERDE_LLM_DEFAULT_MODEL || "js2/gpt-oss-120b";
const gatewayBind = process.env.OPENCLAW_GATEWAY_BIND || "lan";
const gatewayPort = Number(process.env.OPENCLAW_GATEWAY_PORT || "18789");
const authMode = process.env.OPENCLAW_GATEWAY_AUTH_MODE || "token";
const origins = (process.env.OPENCLAW_CONTROL_ORIGINS || "http://127.0.0.1:18789,http://localhost:18789")
  .split(",")
  .map((value) => value.trim())
  .filter(Boolean);
const visibleRepliesMode = process.env.OPENCLAW_VISIBLE_REPLIES_MODE || "message_tool";
const verdeMinimalTools = process.env.OPENCLAW_VERDE_MINIMAL_TOOLS === "1";

let config = {};
try {
  config = JSON.parse(fs.readFileSync(configPath, "utf8"));
} catch (error) {
  if (error.code !== "ENOENT") throw error;
}

config.agents ||= {};
config.agents.defaults ||= {};
config.agents.defaults.workspace = workspace;
config.agents.defaults.models ||= {};
config.agents.defaults.models[defaultModel] ||= {};
config.agents.defaults.model ||= {};
config.agents.defaults.model.primary = defaultModel;

config.models ||= {};
config.models.mode ||= "merge";
config.models.providers ||= {};
if (verdeApiKey) {
  const configuredVerdeModel = defaultModel.startsWith(`${verdeProviderName}/`)
    ? defaultModel.slice(verdeProviderName.length + 1)
    : verdeDefaultModel;
  config.models.providers[verdeProviderName] ||= {};
  Object.assign(config.models.providers[verdeProviderName], {
    baseUrl: verdeBaseUrl,
    apiKey: verdeApiKey,
    auth: "api-key",
    authHeader: true,
    api: "openai-completions",
    contextWindow: 131072,
    contextTokens: 120000,
    maxTokens: 32768,
    timeoutSeconds: 180,
    agentRuntime: { id: "pi" },
  });
  const provider = config.models.providers[verdeProviderName];
  provider.models = Array.isArray(provider.models) ? provider.models : [];
  if (!provider.models.some((model) => model && model.id === configuredVerdeModel)) {
    provider.models.push({
      id: configuredVerdeModel,
      name: `AI-VERDE ${configuredVerdeModel.split("/").pop()}`,
      reasoning: false,
      input: ["text"],
      contextWindow: 131072,
      contextTokens: 120000,
      maxTokens: 32768,
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      compat: { supportsUsageInStreaming: true },
    });
  }
}

config.gateway ||= {};
config.gateway.mode = "local";
config.gateway.bind = gatewayBind;
config.gateway.port = gatewayPort;
config.gateway.auth ||= {};
config.gateway.auth.mode = authMode;
if (authMode === "token") {
  config.gateway.auth.token =
    process.env.OPENCLAW_GATEWAY_TOKEN ||
    config.gateway.auth.token ||
    crypto.randomBytes(24).toString("hex");
}
config.gateway.controlUi ||= {};
config.gateway.controlUi.allowedOrigins = origins;

config.plugins ||= {};
config.plugins.entries ||= {};
config.plugins.entries.openai ||= {};
config.plugins.entries.openai.enabled = true;
config.plugins.entries.codex ||= {};
config.plugins.entries.codex.enabled = true;

config.messages ||= {};
config.messages.visibleReplies = visibleRepliesMode;
config.messages.groupChat ||= {};
config.messages.groupChat.visibleReplies = visibleRepliesMode;

if (defaultModel.startsWith(`${verdeProviderName}/`) && verdeMinimalTools) {
  config.tools ||= {};
  config.tools.byProvider ||= {};
  config.tools.byProvider[verdeProviderName] ||= {};
  config.tools.byProvider[verdeProviderName].profile ||= "minimal";
  config.tools.byProvider[defaultModel] ||= {};
  config.tools.byProvider[defaultModel].profile ||= "minimal";
  config.tools.byProvider[defaultModel].deny ||= [
    "group:fs",
    "group:runtime",
    "group:ui",
    "group:web",
    "group:sessions",
    "group:automation",
    "group:nodes",
    "group:media",
    "write",
    "edit",
    "apply_patch",
  ];
}

config.meta ||= {};
config.meta.lastTouchedVersion ||= "container-bootstrap";

fs.mkdirSync(require("path").dirname(configPath), { recursive: true });
fs.writeFileSync(configPath, `${JSON.stringify(config, null, 2)}\n`, { mode: 0o600 });
NODE

chmod 700 "${config_dir}" || true
chmod 700 "${config_dir}/auth-profile-secrets" || true
configure_github_cli

if [ "${OPENCLAW_EXEC_POLICY_PRESET:-cautious}" != "none" ]; then
  openclaw exec-policy preset "${OPENCLAW_EXEC_POLICY_PRESET:-cautious}" >/tmp/openclaw-exec-policy.log 2>&1 || {
    echo "OpenClaw exec policy setup failed. Recent log:" >&2
    tail -n 80 /tmp/openclaw-exec-policy.log >&2
    exit 1
  }
fi

if [ "${OPENCLAW_CONFIGURE_SLACK:-1}" != "0" ] \
  && [ -n "${SLACK_BOT_TOKEN:-}" ] \
  && [ -n "${SLACK_APP_TOKEN:-}" ]; then
  echo "Configuring Slack channel from environment-backed credentials..."
  openclaw channels add --channel slack --use-env --name pi-liaison >/tmp/openclaw-slack-configure.log 2>&1 || {
    echo "Slack channel configuration failed. Recent log:" >&2
    sed -E 's/(xoxb-|xapp-)[A-Za-z0-9._-]+/\1****REDACTED/g' /tmp/openclaw-slack-configure.log | tail -n 80 >&2
    exit 1
  }
fi

if [ "${OPENCLAW_START_PI_LIAISON:-1}" != "0" ]; then
  case "${1:-}" in
    /bin/bash|bash|/bin/sh|sh)
      liaison_script="${workspace}/scripts/start-pi-liaison.sh"
      if [ -x "${liaison_script}" ]; then
        exec "${liaison_script}"
      elif [ -f "${seed_dir}/scripts/start-pi-liaison.sh" ]; then
        exec bash "${seed_dir}/scripts/start-pi-liaison.sh"
      fi
      ;;
  esac
fi

exec "$@"
