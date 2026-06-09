#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "${tmp_root}"' EXIT

status=0

pass() { echo "ok: $1"; }
warn() { echo "warn: $1"; }
fail() { echo "fail: $1" >&2; status=1; }

cd "${repo_root}"

echo "== Required files and directories =="
for path in Dockerfile docker-compose.yml Makefile .env.example README.md docs config docker/seed-workspace scripts/demo_environmental_workflow.py; do
  if [ -e "${path}" ]; then
    pass "${path}"
  else
    fail "${path} missing"
  fi
done

echo
echo "== Template smoke tests =="
scripts/test-working-group.sh >/tmp/hermes-smoke-working-group.log 2>&1 && pass "working-group scaffold" || fail "working-group scaffold failed"
scripts/test-hermes-layout.sh >/tmp/hermes-smoke-layout.log 2>&1 && pass "data layout scaffold" || fail "data layout scaffold failed"
scripts/smoke_test_workspace.sh >/tmp/hermes-smoke-file-manager.log 2>&1 && pass "workspace file manager" || fail "workspace file manager failed"
scripts/smoke_test_github_manager.sh >/tmp/hermes-smoke-github-manager.log 2>&1 && pass "GitHub repository manager" || fail "GitHub repository manager failed"

echo
echo "== Secret hygiene =="
if git ls-files --error-unmatch .env >/dev/null 2>&1; then
  fail ".env is tracked by git"
else
  pass ".env is not tracked"
fi

if git grep -nE 'xoxb-[A-Za-z0-9._-]{20,}|xapp-[A-Za-z0-9._-]{20,}|sk-[A-Za-z0-9._-]{20,}' -- \
  ':!*.example' \
  ':!*.template' \
  ':!scripts/check-secrets.sh' \
  ':!docker/seed-workspace/scripts/check-secrets.sh' \
  ':!docs/security.md' \
  ':!docs/security-and-credentials.md' \
  >/tmp/hermes-smoke-secrets.log 2>&1; then
  fail "possible committed secret detected; see /tmp/hermes-smoke-secrets.log"
else
  pass "no obvious committed token patterns detected"
fi

echo
echo "== Python and geospatial imports =="
python3 -m py_compile scripts/demo_environmental_workflow.py && pass "demo workflow compiles" || fail "demo workflow does not compile"
python3 - <<'PY' && pass "core Python geospatial imports available" || warn "geospatial imports are not all available in this host Python; they are expected inside the container image"
mods = ["numpy", "rasterio", "geopandas", "shapely", "pyproj"]
for mod in mods:
    __import__(mod)
PY

echo
echo "== Demo workflow =="
demo_workspace="${tmp_root}/workspace"
python3 scripts/demo_environmental_workflow.py --workspace "${demo_workspace}" >/tmp/hermes-smoke-demo.log
for path in \
  "${demo_workspace}/outputs/demo/demo_habitat_suitability.csv" \
  "${demo_workspace}/outputs/demo/figures/demo_habitat_suitability.svg" \
  "${demo_workspace}/outputs/demo/metadata.json" \
  "${demo_workspace}/outputs/demo/report.md"; do
  if [ -s "${path}" ]; then
    pass "created ${path#${demo_workspace}/}"
  else
    fail "missing expected demo output ${path}"
  fi
done

echo
if [ "${status}" -eq 0 ]; then
  echo "Hermes smoke test passed."
else
  echo "Hermes smoke test failed." >&2
fi

exit "${status}"
