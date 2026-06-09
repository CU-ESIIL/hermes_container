#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "${tmp_root}"' EXIT

data_root="${tmp_root}/data"
external_storage_root="${tmp_root}/external_storage"

"${repo_root}/scripts/init-data-layout.sh" --data-root "${data_root}" --external-storage-root "${external_storage_root}" >/tmp/hermes-layout-1.log
"${repo_root}/scripts/init-data-layout.sh" --data-root "${data_root}" --external-storage-root "${external_storage_root}" >/tmp/hermes-layout-2.log

required_dirs=(
  ".hermes"
  "workspace"
  "downloads"
  "outputs"
  "outputs/reports"
  "outputs/figures"
  "outputs/tables"
  "outputs/maps"
  "outputs/logs"
  "outputs/jobs"
  "logs"
  "skills/core"
  "skills/experimental"
  "skills/local"
  "agents"
  "memory"
  "notebooks"
  "stac"
  "secrets-example"
  "workspace/cache"
)

for dir in "${required_dirs[@]}"; do
  if [ ! -d "${data_root}/${dir}" ]; then
    echo "Missing Hermes data directory: ${data_root}/${dir}" >&2
    exit 1
  fi
  if [ ! -f "${data_root}/${dir}/README.md" ]; then
    echo "Missing README for Hermes data directory: ${data_root}/${dir}" >&2
    exit 1
  fi
done

if [ ! -d "${external_storage_root}/local" ]; then
  echo "Missing external storage local directory: ${external_storage_root}/local" >&2
  exit 1
fi

required_scripts=(
  "scripts/init-data-layout.sh"
  "scripts/setup_env.sh"
  "scripts/init_working_group.sh"
  "scripts/doctor.sh"
  "scripts/checkpoint.sh"
  "scripts/check_auth.sh"
  "examples/pdf_to_text.sh"
  "examples/pdf_to_images.sh"
  "examples/markdown_to_html.sh"
  "examples/image_thumbnail_example.sh"
  "examples/playwright_screenshot_example.py"
  "scripts/build_output_index.py"
  "scripts/run_worker_local.sh"
  "scripts/test-spatiotemporal-runtime.sh"
  "scripts/test-storage-cms.sh"
  "storage/scripts/storage_common.py"
  "storage/scripts/browse_storage.py"
  "storage/scripts/list_storage.py"
  "storage/scripts/test_storage.py"
  "storage/scripts/register_dataset.py"
  "storage/scripts/cache_dataset.py"
  "storage/scripts/sync_outputs.py"
  "cms/hermes_cms.py"
)

for script in "${required_scripts[@]}"; do
  if [ ! -x "${repo_root}/${script}" ]; then
    echo "Expected executable script: ${script}" >&2
    exit 1
  fi
done

python3 -m py_compile "${repo_root}/examples/playwright_screenshot_example.py"
python3 -m py_compile "${repo_root}/cms/hermes_cms.py" "${repo_root}/storage/scripts/storage_common.py" "${repo_root}/storage/scripts/browse_storage.py" "${repo_root}/storage/scripts/list_storage.py" "${repo_root}/storage/scripts/test_storage.py" "${repo_root}/storage/scripts/register_dataset.py" "${repo_root}/storage/scripts/cache_dataset.py" "${repo_root}/storage/scripts/sync_outputs.py"

echo "Hermes layout smoke test passed."
