#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "${tmp_root}"' EXIT

python3 -m py_compile \
  "${repo_root}/cms/hermes_cms.py" \
  "${repo_root}/storage/scripts/storage_common.py" \
  "${repo_root}/storage/scripts/browse_storage.py" \
  "${repo_root}/storage/scripts/list_storage.py" \
  "${repo_root}/storage/scripts/test_storage.py" \
  "${repo_root}/storage/scripts/register_dataset.py" \
  "${repo_root}/storage/scripts/cache_dataset.py" \
  "${repo_root}/storage/scripts/sync_outputs.py"

python3 "${repo_root}/storage/scripts/list_storage.py" \
  --config "${repo_root}/storage/storage.example.yml" \
  --json > "${tmp_root}/stores.json"

python3 "${repo_root}/storage/scripts/test_storage.py" \
  --config "${repo_root}/storage/storage.example.yml" > "${tmp_root}/storage-test.log"

python3 "${repo_root}/storage/scripts/register_dataset.py" \
  --config "${repo_root}/storage/storage.example.yml" \
  --name smoke_stac \
  --href https://example.org/catalog.json \
  --type stac \
  --out "${tmp_root}/datasets.json" >/tmp/hermes-register-dataset.log

python3 "${repo_root}/storage/scripts/cache_dataset.py" \
  --config "${repo_root}/storage/storage.example.yml" \
  --dataset public_stac_demo \
  --cache-dir "${tmp_root}/cache" \
  --dry-run >/tmp/hermes-cache-dataset.log

mkdir -p "${tmp_root}/outputs/example"
printf 'ok\n' > "${tmp_root}/outputs/example/report.md"
python3 "${repo_root}/storage/scripts/sync_outputs.py" \
  "${tmp_root}/outputs/example" \
  --store local_external \
  --config "${repo_root}/storage/storage.example.yml" \
  --dry-run >/tmp/hermes-sync-outputs.log

required_files=(
  "cms/hermes_cms.py"
  "docs/workspace-cms.md"
  "docs/storage/index.md"
  "docs/publishing-workflow.md"
  "docs/dashboard-patterns.md"
  "docs/reports/sample-promoted-report.md"
  "docs/dashboard/sample-storage-dashboard.md"
  "storage/storage.example.yml"
  "storage/schemas/storage.schema.json"
)

for file in "${required_files[@]}"; do
  if [ ! -f "${repo_root}/${file}" ]; then
    echo "Missing storage/CMS file: ${file}" >&2
    exit 1
  fi
done

echo "Hermes storage/CMS smoke test passed."
