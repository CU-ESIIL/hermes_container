#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "${tmp_root}"' EXIT

python3 -m py_compile \
  "${repo_root}/workers/spatiotemporal-worker/run_task.py" \
  "${repo_root}/scripts/build_output_index.py" \
  "${repo_root}/runtime/job-launcher/render_job_manifest.py" \
  "${repo_root}/runtime/job-launcher/submit_k8s_job.py" \
  "${repo_root}/examples/spatiotemporal/stac_search_example.py" \
  "${repo_root}/examples/spatiotemporal/cog_window_read_example.py" \
  "${repo_root}/examples/spatiotemporal/xarray_zarr_example.py" \
  "${repo_root}/examples/spatiotemporal/stac_quicklook_report.py"

task="${repo_root}/examples/spatiotemporal/tasks/example_stac_preview.yaml"
output_dir="${tmp_root}/data/outputs/jobs/example-stac-preview-test"

python3 "${repo_root}/workers/spatiotemporal-worker/run_task.py" \
  --task "${task}" \
  --output-dir "${output_dir}" \
  --offline

for required in task.yaml status.json logs.txt metadata.json report.md report.html figures/quicklook.png; do
  if [ ! -e "${output_dir}/${required}" ]; then
    echo "Missing worker output: ${required}" >&2
    exit 1
  fi
done

python3 "${repo_root}/scripts/build_output_index.py" --data-root "${tmp_root}/data" >/tmp/hermes-output-index.log
if [ ! -f "${tmp_root}/data/outputs/index.html" ]; then
  echo "Output index was not created." >&2
  exit 1
fi

python3 "${repo_root}/runtime/job-launcher/render_job_manifest.py" \
  --task "${task}" \
  --job-id example-stac-preview-test \
  --image hermes-spatiotemporal-worker:local \
  >/tmp/hermes-rendered-job.yaml

if ! grep -q "kind: Job" /tmp/hermes-rendered-job.yaml; then
  echo "Rendered manifest does not include a Job." >&2
  exit 1
fi

echo "Spatiotemporal runtime smoke test passed."
