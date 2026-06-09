#!/usr/bin/env bash
set -Eeuo pipefail

input="${1:?Usage: examples/markdown_to_html.sh INPUT.md [OUTPUT.html]}"
output="${2:-/data/outputs/reports/$(basename "${input%.*}").html}"

mkdir -p "$(dirname "${output}")"
pandoc "${input}" -o "${output}" --standalone
echo "Wrote ${output}"
