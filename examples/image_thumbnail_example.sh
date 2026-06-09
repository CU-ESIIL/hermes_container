#!/usr/bin/env bash
set -Eeuo pipefail

input="${1:?Usage: examples/image_thumbnail_example.sh INPUT_IMAGE [OUTPUT_IMAGE]}"
output="${2:-/data/outputs/figures/$(basename "${input%.*}")-thumb.png}"

mkdir -p "$(dirname "${output}")"
convert "${input}" -thumbnail 512x512 "${output}"
echo "Wrote ${output}"
