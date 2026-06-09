#!/usr/bin/env bash
set -Eeuo pipefail

input="${1:?Usage: examples/pdf_to_images.sh INPUT.pdf [OUTPUT_DIR]}"
output_dir="${2:-/data/outputs/figures/$(basename "${input%.*}")}"

mkdir -p "${output_dir}"
pdftoppm -png "${input}" "${output_dir}/page"
echo "Wrote page images to ${output_dir}"
