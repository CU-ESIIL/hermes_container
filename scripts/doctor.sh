#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

status=0

section() {
  echo
  echo "== $1 =="
}

pass() {
  echo "ok: $1"
}

warn() {
  echo "warn: $1"
}

fail() {
  echo "fail: $1" >&2
  status=1
}

section "Repository"
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  pass "inside a git repository"
  echo "branch: $(git branch --show-current 2>/dev/null || echo unknown)"
  if git diff --quiet --ignore-submodules -- 2>/dev/null && git diff --cached --quiet --ignore-submodules -- 2>/dev/null; then
    pass "working tree has no unstaged or staged diffs"
  else
    warn "working tree has local changes; checkpoint before large edits"
  fi
else
  fail "not inside a git repository"
fi

section "Docker"
if command -v docker >/dev/null 2>&1; then
  pass "docker command is available"
  if docker info >/dev/null 2>&1; then
    pass "docker engine is reachable"
  else
    warn "docker command exists, but the engine is not reachable"
  fi
else
  warn "docker command is not available on this machine"
fi

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  pass "docker compose is available"
else
  warn "docker compose is not available"
fi

section "Local Files"
for path in Dockerfile docker-compose.yml .env.example README.md mkdocs.yml config/working_group.yaml docker/seed-workspace; do
  if [ -e "${path}" ]; then
    pass "${path} exists"
  else
    fail "${path} is missing"
  fi
done

if [ -f ".env" ]; then
  pass ".env exists locally"
else
  warn ".env is missing; copy .env.example to .env before using integrations"
fi

section "Template Structure"
if scripts/test-working-group.sh >/tmp/hermes-doctor-working-group.log 2>&1; then
  pass "working-group scaffold test passed"
else
  fail "working-group scaffold test failed; see /tmp/hermes-doctor-working-group.log"
fi

if scripts/test-hermes-layout.sh >/tmp/hermes-doctor-layout.log 2>&1; then
  pass "data layout smoke test passed"
else
  fail "data layout smoke test failed; see /tmp/hermes-doctor-layout.log"
fi

section "Secrets"
if [ -f ".env" ]; then
  if scripts/check-secrets.sh >/tmp/hermes-doctor-secrets.log 2>&1; then
    pass "Slack secret validation passed"
  else
    warn "Slack secrets are missing or incomplete; this is fine unless Slack is enabled"
  fi
else
  warn "skipping secret validation because .env is missing"
fi

if git ls-files --error-unmatch .env >/dev/null 2>&1; then
  fail ".env is tracked by git; remove it from the index immediately"
else
  pass ".env is not tracked by git"
fi

section "Summary"
if [ "${status}" -eq 0 ]; then
  echo "Hermes doctor completed without required-check failures."
else
  echo "Hermes doctor found required-check failures." >&2
fi

exit "${status}"

