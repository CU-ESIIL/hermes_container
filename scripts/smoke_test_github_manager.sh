#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_root="$(mktemp -d)"
server_pid=""
port="${HERMES_GITHUB_TEST_PORT:-9877}"
base_url="http://127.0.0.1:${port}"
status=0

cleanup() {
  if [ -n "${server_pid}" ]; then
    kill "${server_pid}" >/dev/null 2>&1 || true
    wait "${server_pid}" >/dev/null 2>&1 || true
  fi
  rm -rf "${tmp_root}"
}
trap cleanup EXIT

pass() { echo "ok: $1"; }
warn() { echo "warn: $1"; }
fail() { echo "fail: $1" >&2; status=1; }

if ! python3 - <<'PY' >/dev/null 2>&1
import socket
s = socket.socket()
try:
    s.bind(("127.0.0.1", 0))
finally:
    s.close()
PY
then
  warn "local listener sockets are blocked in this environment; skipping GitHub manager HTTP smoke test"
  exit 0
fi

workspace="${tmp_root}/workspace"
mkdir -p "${workspace}/repos"

if command -v git >/dev/null 2>&1; then
  pass "git installed on host"
else
  fail "git missing on host"
fi

if command -v gh >/dev/null 2>&1; then
  pass "gh installed on host"
elif grep -Eq '(^|[[:space:]])gh([[:space:]\\]|$)' "${repo_root}/Dockerfile"; then
  warn "gh missing on host but installed in the container image"
else
  fail "gh missing from host and Dockerfile"
fi

OPENCLAW_WORKSPACE="${workspace}" \
HERMES_CMS_ROOTS="${workspace}" \
HERMES_FILE_WRITABLE_ROOTS="${workspace},${tmp_root}/tmp" \
python3 - <<'PY' && pass "registry and policy functions" || fail "registry and policy functions"
import os
from pathlib import Path
from cms import hermes_cms as cms

repo = cms.upsert_authorized_repo({
    "owner": "CU-ESIIL",
    "repo": "demo-project",
    "permission_tier": "contribute",
    "notes": "test registry",
})
assert repo["local_path"].endswith("/workspace/repos/demo-project")
registry = cms.read_github_registry()
assert registry["repositories"][0]["owner"] == "CU-ESIIL"
try:
    cms.validate_repo_parts("../bad", "repo")
    raise AssertionError("invalid owner accepted")
except ValueError:
    pass
try:
    cms.safe_repo_local_path("CU-ESIIL", "demo-project", "/tmp/escape")
    raise AssertionError("path escape accepted")
except ValueError:
    pass
try:
    cms.validate_branch_name("main")
    raise AssertionError("protected branch accepted")
except ValueError:
    pass
masked = cms.mask_secret_text("token ghp_abcdefghijklmnopqrstuvwxyz123456")
assert "abcdefghijklmnopqrstuvwxyz" not in masked
assert cms.github_setup_git_credentials()["ok"] is False
PY

HERMES_CMS_PORT="${port}" \
OPENCLAW_GATEWAY_PORT="18791" \
OPENCLAW_WORKSPACE="${workspace}" \
HERMES_CMS_ROOTS="${workspace}" \
HERMES_FILE_WRITABLE_ROOTS="${workspace},${tmp_root}/tmp" \
python3 "${repo_root}/cms/hermes_cms.py" >"${tmp_root}/cms.log" 2>&1 &
server_pid=$!

for _ in $(seq 1 40); do
  if curl -sSf "${base_url}/api/github/status" >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done

if curl -sSf "${base_url}/api/github/status" | grep -q '"git_installed"'; then
  pass "GitHub status endpoint returns safe JSON"
else
  fail "GitHub status endpoint failed"
  cat "${tmp_root}/cms.log" >&2 || true
fi

if curl -sSf "${base_url}/github" | grep -q 'href="http://127.0.0.1:18791/"'; then
  pass "GitHub manager links back to Hermes"
else
  fail "GitHub manager missing Hermes navigation link"
fi

if curl -sSf "${base_url}/api/github/status" | grep -q '"token_available"'; then
  pass "GitHub status reports token visibility without printing tokens"
else
  fail "GitHub status endpoint did not report token visibility"
fi

if curl -sSf \
  --data-urlencode "owner=CU-ESIIL" \
  --data-urlencode "repo=smoke-repo" \
  --data-urlencode "permission_tier=read" \
  "${base_url}/api/github/repos" >/dev/null; then
  pass "authorized repo can be added through endpoint"
else
  fail "authorized repo endpoint failed"
fi

if grep -R -E 'gh[pousr]_|github_pat_|xoxb-|xapp-' "${workspace}/.openclaw-github" >/dev/null 2>&1; then
  fail "registry contains token-like value"
else
  pass "registry does not contain token-like values"
fi

if [ "${status}" -eq 0 ]; then
  echo "Hermes GitHub manager smoke test passed."
else
  echo "Hermes GitHub manager smoke test failed." >&2
fi

exit "${status}"
