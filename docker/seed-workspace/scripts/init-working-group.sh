#!/usr/bin/env bash
set -Eeuo pipefail

workspace="${WORKSPACE_DIR:-/workspace}"
template_root="/opt/openclaw/seed-workspace"
force=0

usage() {
  cat <<'EOF'
Usage: init-working-group.sh [--workspace PATH] [--template-root PATH] [--force]

Create or refresh the scientific working group scaffold.

Default behavior is non-destructive: existing files are left untouched.
Use --force to overwrite existing starter files from the template root.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace)
      workspace="$2"
      shift 2
      ;;
    --template-root)
      template_root="$2"
      shift 2
      ;;
    --force)
      force=1
      shift
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

if [ ! -d "${template_root}" ]; then
  echo "Template root not found: ${template_root}" >&2
  exit 1
fi

mkdir -p "${workspace}"

created_dirs=()
created_files=()
updated_files=()
skipped_files=()

ensure_dir() {
  local rel="$1"
  local dest="${workspace}/${rel}"
  if [ ! -d "${dest}" ]; then
    mkdir -p "${dest}"
    created_dirs+=("${rel}")
  fi
}

seed_file() {
  local rel="$1"
  local src="${template_root}/${rel}"
  local dest="${workspace}/${rel}"

  if [ ! -f "${src}" ]; then
    echo "Template file missing: ${src}" >&2
    exit 1
  fi

  mkdir -p "$(dirname "${dest}")"

  if [ -e "${dest}" ] && [ "${force}" -ne 1 ]; then
    skipped_files+=("${rel}")
    return
  fi

  if [ -e "${dest}" ] && [ "${force}" -eq 1 ]; then
    updated_files+=("${rel}")
  else
    created_files+=("${rel}")
  fi

  cp "${src}" "${dest}"
}

required_dirs=(
  "documents"
  "projects"
  "projects/_template"
  "config"
  "data"
  "datasets"
  "data/raw"
  "data/processed"
  "data/derived"
  "analysis"
  "figures"
  "maps"
  "outputs"
  "reports"
  "manuscripts"
  "presentations"
  "notebooks"
  "tasks"
  "reviews"
  "decisions"
  "assumptions"
  "literature"
  "meetings"
  "daily_notes"
  "agent_reports"
  "logs"
  "heartbeat"
  "soul"
  "memory"
  "memory/quarantine"
  "prompts"
  "runtime"
  "cache"
  "services"
  "services/pi_liaison"
  "scripts"
)

starter_files=(
  "README.md"
  "WORKING_GROUP_COCKPIT.md"
  "MEMORY.md"
  "AGENTS.md"
  "IDENTITY.md"
  "USER.md"
  "SOUL.md"
  "TOOLS.md"
  "HEARTBEAT.md"
  "USER_CONTEXT.md"
  "RESOURCE_MAP.md"
  "PROJECT_INTAKE.md"
  "PROJECT_CHARTER.md"
  "TEAM_BRIEF.md"
  "INITIAL_TASKS.md"
  "QUESTIONS_FOR_USER.md"
  "MODEL_ASSIGNMENTS.md"
  "CONTINUOUS_IMPROVEMENT_LOG.md"
  "ROADMAP.md"
  "DECISIONS.md"
  "ASSUMPTIONS.md"
  "HUMAN_REVIEW.md"
  "CONTRIBUTION_GUIDE.md"
  "CONSENSUS_STATE.md"
  "CHECKPOINT.md"
  "config/README.md"
  "config/working_group.yaml"
  "documents/README.md"
  "documents/TEAM_NORMS.md"
  "documents/DECISION_PROTOCOL.md"
  "documents/CONTINUOUS_IMPROVEMENT_PROTOCOL.md"
  "documents/MEMORY_QUARANTINE_PROTOCOL.md"
  "documents/ARTIFACT_REGISTRY.md"
  "documents/SOCIETAL_IMPACT_CHECKLIST.md"
  "projects/README.md"
  "projects/_template/README.md"
  "projects/_template/PROJECT.yaml"
  "projects/_template/DATA_MANIFEST.md"
  "projects/_template/GITHUB_REPOS.md"
  "projects/_template/EXTERNAL_LINKS.md"
  "projects/_template/STORAGE.yml"
  "projects/_template/WORKSPACE_NOTES.md"
  "data/README.md"
  "datasets/README.md"
  "data/raw/README.md"
  "data/processed/README.md"
  "data/derived/README.md"
  "analysis/README.md"
  "figures/README.md"
  "maps/README.md"
  "outputs/README.md"
  "reports/README.md"
  "manuscripts/README.md"
  "presentations/README.md"
  "notebooks/README.md"
  "tasks/README.md"
  "reviews/README.md"
  "decisions/README.md"
  "assumptions/README.md"
  "literature/README.md"
  "meetings/README.md"
  "meetings/TEMPLATE.md"
  "daily_notes/README.md"
  "agent_reports/README.md"
  "agent_reports/role_reproducibility_index.md"
  "agent_reports/team_norms_review_packet.md"
  "agent_reports/continuous_improvement_review_template.md"
  "agent_reports/pi_liaison_reproducibility_notes.md"
  "agent_reports/scientific_director_reproducibility_notes.md"
  "agent_reports/deputy_integrator_reproducibility_notes.md"
  "agent_reports/data_engineer_reproducibility_notes.md"
  "agent_reports/quantitative_modeler_reproducibility_notes.md"
  "agent_reports/domain_scientist_reproducibility_notes.md"
  "agent_reports/scientific_narrative_lead_reproducibility_notes.md"
  "agent_reports/technical_communicator_reproducibility_notes.md"
  "agent_reports/citation_evidence_curator_reproducibility_notes.md"
  "agent_reports/skeptic_reproducibility_notes.md"
  "agent_reports/societal_impact_translation_reproducibility_notes.md"
  "logs/README.md"
  "heartbeat/README.md"
  "soul/README.md"
  "memory/README.md"
  "memory/quarantine/README.md"
  "prompts/README.md"
  "prompts/pi-liaison-startup.md"
  "runtime/README.md"
  "cache/README.md"
  "services/README.md"
  "services/pi_liaison/README.md"
  "services/pi_liaison/.env.template"
  "scripts/README.md"
  "scripts/init-working-group.sh"
  "scripts/start-pi-liaison.sh"
  "scripts/check-secrets.sh"
  "scripts/mask-secrets.sh"
)

for dir in "${required_dirs[@]}"; do
  ensure_dir "${dir}"
done

for file in "${starter_files[@]}"; do
  seed_file "${file}"
done

chmod +x "${workspace}/scripts/init-working-group.sh" 2>/dev/null || true
chmod +x "${workspace}/scripts/start-pi-liaison.sh" 2>/dev/null || true
chmod +x "${workspace}/scripts/check-secrets.sh" 2>/dev/null || true
chmod +x "${workspace}/scripts/mask-secrets.sh" 2>/dev/null || true

echo "Scientific working group scaffold initialized at ${workspace}"
echo "Directories created: ${#created_dirs[@]}"
if [ "${#created_dirs[@]}" -gt 0 ]; then
  printf '  - %s\n' "${created_dirs[@]}"
fi
echo "Files created: ${#created_files[@]}"
if [ "${#created_files[@]}" -gt 0 ]; then
  printf '  - %s\n' "${created_files[@]}"
fi
echo "Files updated: ${#updated_files[@]}"
if [ "${#updated_files[@]}" -gt 0 ]; then
  printf '  - %s\n' "${updated_files[@]}"
fi
echo "Existing files left unchanged: ${#skipped_files[@]}"
