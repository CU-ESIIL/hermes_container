#!/usr/bin/env bash
set -Eeuo pipefail

input="${1:?Usage: examples/pdf_to_text.sh INPUT.pdf [OUTPUT.txt]}"
output="${2:-/data/outputs/reports/$(basename "${input%.*}").txt}"

mkdir -p "$(dirname "${output}")"
pdftotext "${input}" "${output}"
echo "Wrote ${output}"
