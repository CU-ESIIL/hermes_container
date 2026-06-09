#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_root="$(mktemp -d)"
cleanup() {
  if [ -n "${server_pid:-}" ]; then
    kill "${server_pid}" >/dev/null 2>&1 || true
    wait "${server_pid}" >/dev/null 2>&1 || true
  fi
  rm -rf "${tmp_root}"
}
trap cleanup EXIT

workspace="${tmp_root}/workspace"
outputs="${tmp_root}/outputs"
scratch="${tmp_root}/tmp"
port="${HERMES_CMS_TEST_PORT:-9876}"
base_url="http://127.0.0.1:${port}"
status=0

pass() { echo "ok: $1"; }
fail() { echo "fail: $1" >&2; status=1; }
warn() { echo "warn: $1"; }

if ! python3 - <<'PY' >/dev/null 2>&1
import socket
s = socket.socket()
try:
    s.bind(("127.0.0.1", 0))
finally:
    s.close()
PY
then
  warn "local listener sockets are blocked in this environment; skipping filesystem HTTP smoke test"
  exit 0
fi

mkdir -p "${workspace}" "${outputs}" "${scratch}"
python3 "${repo_root}/scripts/seed_file_manager_demo.py" --workspace "${workspace}" >/dev/null

HERMES_CMS_PORT="${port}" \
OPENCLAW_GATEWAY_PORT="18791" \
HERMES_CMS_ROOTS="${workspace},${outputs}" \
HERMES_FILE_WRITABLE_ROOTS="${workspace},${outputs},${scratch}" \
python3 "${repo_root}/cms/hermes_cms.py" >"${tmp_root}/cms.log" 2>&1 &
server_pid=$!

for _ in $(seq 1 40); do
  if curl -sSf "${base_url}/files?path=${workspace}" >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done

if curl -sSf "${base_url}/files?path=${workspace}" >/dev/null; then
  pass "file manager service starts"
else
  fail "file manager service did not start"
  cat "${tmp_root}/cms.log" >&2 || true
  exit "${status}"
fi

if curl -sSf "${base_url}/files?path=${workspace}" | grep -q 'href="http://127.0.0.1:18791/"'; then
  pass "file manager links back to Hermes"
else
  fail "file manager missing Hermes navigation link"
fi

if curl -sSf "${base_url}/api/file/list?path=${workspace}" | grep -q '"entries"'; then
  pass "API list returns entries"
else
  fail "API list did not return entries"
fi

if curl -sSf --data-urlencode "path=${workspace}" --data-urlencode "name=notes.md" "${base_url}/api/file/touch" >/dev/null; then
  pass "create text file"
else
  fail "create text file"
fi

if curl -sSf --data-urlencode "path=${workspace}/notes.md" --data-urlencode "content=# Edited Note" "${base_url}/api/file/save" >/dev/null; then
  pass "text editing save"
else
  fail "text editing save"
fi

if curl -sSf --data-urlencode "path=${workspace}" --data-urlencode "name=uploaded.csv" --data-urlencode "content=a,b"$'\n'"1,2" "${base_url}/api/file/upload" >/dev/null; then
  pass "upload endpoint"
else
  fail "upload endpoint"
fi

if curl -sSf "${base_url}/files?path=${workspace}/reports/demo_report.md" | grep -q "Demo Workspace Report"; then
  pass "Markdown preview"
else
  fail "Markdown preview"
fi

if curl -sSf "${base_url}/files?path=${workspace}/outputs/demo/demo_table.csv" | grep -q "<table>"; then
  pass "CSV preview"
else
  fail "CSV preview"
fi

if curl -sSf "${base_url}/files?path=${workspace}/outputs/demo/demo_preview.png" | grep -q "Dimensions"; then
  pass "image preview metadata"
else
  fail "image preview metadata"
fi

printf 'SECRET=do-not-show\n' >"${workspace}/.env"
if curl -sSf "${base_url}/files/raw?path=${workspace}/.env" >/dev/null 2>&1; then
  fail "sensitive file was exposed"
else
  pass "sensitive file blocked"
fi

if curl -sSf --data-urlencode "path=${workspace}/notes.md" "${base_url}/api/file/delete" >/dev/null 2>&1; then
  fail "delete without confirmation was allowed"
else
  pass "delete requires confirmation"
fi

if curl -sSf --data-urlencode "path=${workspace}/notes.md" --data-urlencode "confirm=yes" "${base_url}/api/file/delete" >/dev/null; then
  pass "confirmed delete"
else
  fail "confirmed delete"
fi

if curl -sSf --data-urlencode "path=/etc" --data-urlencode "name=blocked.md" "${base_url}/api/file/touch" >/dev/null 2>&1; then
  fail "system write was allowed"
else
  pass "system writes are blocked"
fi

if [ "${status}" -eq 0 ]; then
  echo "Hermes workspace file manager smoke test passed."
else
  echo "Hermes workspace file manager smoke test failed." >&2
fi

exit "${status}"
