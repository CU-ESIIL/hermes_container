#!/usr/bin/env bash
set -Eeuo pipefail

data_root="${DATA_ROOT:-/data}"
external_storage_root="${EXTERNAL_STORAGE_ROOT:-/external_storage}"

usage() {
  cat <<'EOF'
Usage: init-data-layout.sh [--data-root PATH]

Create the persistent Hermes /data layout.

The script is idempotent and does not overwrite existing user files.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --data-root)
      data_root="$2"
      shift 2
      ;;
    --external-storage-root)
      external_storage_root="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

dirs=(
  ".openclaw"
  "workspace"
  "downloads"
  "outputs"
  "outputs/reports"
  "outputs/figures"
  "outputs/tables"
  "outputs/maps"
  "outputs/logs"
  "outputs/jobs"
  "reports"
  "figures"
  "tables"
  "logs"
  "skills"
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

readme_for() {
  case "$1" in
    ".") echo "Persistent Hermes data root. Runtime state, workspaces, outputs, logs, skills, agents, notebooks, and optional catalogs live here." ;;
    ".openclaw") echo "Hermes runtime state and auth profiles. Do not commit this directory." ;;
    "workspace") echo "Primary scientific workspace. This is also mounted at /workspace for compatibility." ;;
    "downloads") echo "Temporary or user-approved downloads. Document provenance before analysis." ;;
    "outputs") echo "Generated artifacts that should be easy to inspect after runs." ;;
    "outputs/reports") echo "Rendered reports, exported documents, and review packets." ;;
    "outputs/figures") echo "Generated figures and image artifacts." ;;
    "outputs/tables") echo "Generated tables, CSV summaries, and tabular exports." ;;
    "outputs/maps") echo "Generated map previews, GeoJSON snippets, and lightweight map HTML." ;;
    "outputs/logs") echo "Worker and workflow logs that are safe for human inspection." ;;
    "outputs/jobs") echo "Per-job worker outputs, including task configs, status, logs, metadata, reports, figures, tables, and maps." ;;
    "reports") echo "Compatibility reports directory. Prefer /data/outputs/reports for new outputs." ;;
    "figures") echo "Compatibility figures directory. Prefer /data/outputs/figures for new outputs." ;;
    "tables") echo "Compatibility tables directory. Prefer /data/outputs/tables for new outputs." ;;
    "logs") echo "Persistent runtime and workflow logs. Do not store secrets in logs." ;;
    "skills") echo "Skill extension root. Keep trusted, experimental, and local skills separated." ;;
    "skills/core") echo "Trusted, maintained skills intended for shared deployments." ;;
    "skills/experimental") echo "Opt-in experimental skills. Review before enabling." ;;
    "skills/local") echo "Local custom skills for a deployment. Do not commit secrets." ;;
    "agents") echo "Future agent configuration and handoff scaffolding." ;;
    "memory") echo "Optional inspectable memory scaffolding. Do not store secrets or opaque credential material." ;;
    "notebooks") echo "Persistent notebooks for scientific workflows." ;;
    "stac") echo "STAC and geospatial catalog examples or local configuration." ;;
    "secrets-example") echo "Documentation-only placeholder for secret shapes. Never put real secrets here." ;;
    "workspace/cache") echo "Small approved cache for streamed subsets. Prefer streaming remote data and document cached provenance." ;;
    *) echo "Hermes persistent directory." ;;
  esac
}

mkdir -p "${data_root}"

root_readme="${data_root}/README.md"
if [ ! -e "${root_readme}" ]; then
  {
    echo "# Hermes Persistent Data"
    echo
    echo "$(readme_for ".")"
    echo
    echo "This directory is intended to survive container restarts."
  } > "${root_readme}"
fi

for dir in "${dirs[@]}"; do
  path="${data_root}/${dir}"
  mkdir -p "${path}"
  readme="${path}/README.md"
  if [ ! -e "${readme}" ]; then
    {
      echo "# ${dir}"
      echo
      echo "$(readme_for "${dir}")"
    } > "${readme}"
  fi
done

mkdir -p "${external_storage_root}/local"
external_readme="${external_storage_root}/README.md"
if [ ! -e "${external_readme}" ]; then
  {
    echo "# Hermes External Storage"
    echo
    echo "Optional large-data shelf for mounted or remote-backed artifacts. Keep large rasters, Zarr stores, Parquet collections, NetCDF files, model outputs, and private storage sync targets outside git and outside the container image."
    echo
    echo "Default local mount: ${external_storage_root}/local"
  } > "${external_readme}"
fi

echo "Hermes data layout initialized at ${data_root}"
