#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "${tmp_root}"' EXIT

data_root="${tmp_root}/data"
job_dir="${data_root}/outputs/jobs/example-stac-preview-test"

python3 -m py_compile \
  "${repo_root}/scripts/build_output_index.py" \
  "${repo_root}/examples/spatiotemporal/stac_search_example.py" \
  "${repo_root}/examples/spatiotemporal/cog_window_read_example.py" \
  "${repo_root}/examples/spatiotemporal/xarray_zarr_example.py" \
  "${repo_root}/examples/spatiotemporal/stac_quicklook_report.py"

task="${repo_root}/examples/spatiotemporal/tasks/example_stac_preview.yaml"
mkdir -p "${job_dir}/figures" "${job_dir}/tables" "${job_dir}/maps"
cp "${task}" "${job_dir}/task.yaml"
cat > "${job_dir}/status.json" <<'JSON'
{"job_id":"example-stac-preview-test","task_name":"example_stac_ndvi","status":"completed","started_at":"2026-06-09T22:00:00Z"}
JSON
cat > "${job_dir}/metadata.json" <<'JSON'
{"task_name":"example_stac_ndvi","created_at":"2026-06-09T22:00:00Z"}
JSON
cat > "${job_dir}/logs.txt" <<'EOF'
offline smoke test
EOF
cat > "${job_dir}/report.md" <<'EOF'
# Example STAC Preview
EOF
cat > "${job_dir}/report.html" <<'EOF'
<html><body><h1>Example STAC Preview</h1></body></html>
EOF
printf 'fakepng' > "${job_dir}/figures/quicklook.png"
cat > "${job_dir}/tables/summary.csv" <<'EOF'
metric,value
items,5
EOF
cat > "${job_dir}/maps/footprint.geojson" <<'EOF'
{"type":"FeatureCollection","features":[]}
EOF

python3 "${repo_root}/scripts/build_output_index.py" --data-root "${data_root}" >/tmp/hermes-output-index.log
if [ ! -f "${data_root}/outputs/index.html" ]; then
  echo "Output index was not created." >&2
  exit 1
fi

if ! grep -q "example-stac-preview-test" "${data_root}/outputs/index.html"; then
  echo "Output index is missing the sample job." >&2
  exit 1
fi

if ! grep -q "figures/quicklook.png" "${data_root}/outputs/index.html"; then
  echo "Output index is missing figure links." >&2
  exit 1
fi

echo "Spatiotemporal runtime smoke test passed."
