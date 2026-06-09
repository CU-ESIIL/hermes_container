#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace="${WORKSPACE_DIR:-}"
template_root="${TEMPLATE_ROOT:-${repo_root}/docker/seed-workspace}"
init_script="${INIT_SCRIPT:-${template_root}/scripts/init-working-group.sh}"
cleanup=0

if [ -z "${workspace}" ]; then
  workspace="$(mktemp -d)"
  cleanup=1
fi

cleanup_workspace() {
  if [ "${cleanup}" -eq 1 ]; then
    rm -rf "${workspace}"
  fi
}
trap cleanup_workspace EXIT

required_dirs=(
  documents
  config
  data
  datasets
  data/raw
  data/processed
  data/derived
  analysis
  figures
  maps
  outputs
  reports
  manuscripts
  presentations
  notebooks
  tasks
  reviews
  decisions
  assumptions
  literature
  meetings
  daily_notes
  agent_reports
  logs
  heartbeat
  soul
  memory
  memory/quarantine
  prompts
  runtime
  cache
  services
  services/pi_liaison
  scripts
)

required_files=(
  README.md
  WORKING_GROUP_COCKPIT.md
  MEMORY.md
  AGENTS.md
  IDENTITY.md
  USER.md
  SOUL.md
  TOOLS.md
  HEARTBEAT.md
  ROADMAP.md
  DECISIONS.md
  ASSUMPTIONS.md
  HUMAN_REVIEW.md
  CONTRIBUTION_GUIDE.md
  CONSENSUS_STATE.md
  CHECKPOINT.md
  config/working_group.yaml
  USER_CONTEXT.md
  PROJECT_INTAKE.md
  PROJECT_CHARTER.md
  TEAM_BRIEF.md
  INITIAL_TASKS.md
  QUESTIONS_FOR_USER.md
  MODEL_ASSIGNMENTS.md
  CONTINUOUS_IMPROVEMENT_LOG.md
  documents/TEAM_NORMS.md
  documents/DECISION_PROTOCOL.md
  documents/CONTINUOUS_IMPROVEMENT_PROTOCOL.md
  documents/MEMORY_QUARANTINE_PROTOCOL.md
  documents/ARTIFACT_REGISTRY.md
  documents/SOCIETAL_IMPACT_CHECKLIST.md
  meetings/TEMPLATE.md
  memory/quarantine/README.md
  agent_reports/role_reproducibility_index.md
  agent_reports/team_norms_review_packet.md
  agent_reports/continuous_improvement_review_template.md
  agent_reports/pi_liaison_reproducibility_notes.md
  agent_reports/scientific_director_reproducibility_notes.md
  agent_reports/deputy_integrator_reproducibility_notes.md
  agent_reports/data_engineer_reproducibility_notes.md
  agent_reports/quantitative_modeler_reproducibility_notes.md
  agent_reports/domain_scientist_reproducibility_notes.md
  agent_reports/scientific_narrative_lead_reproducibility_notes.md
  agent_reports/technical_communicator_reproducibility_notes.md
  agent_reports/citation_evidence_curator_reproducibility_notes.md
  agent_reports/skeptic_reproducibility_notes.md
  agent_reports/societal_impact_translation_reproducibility_notes.md
  prompts/README.md
  prompts/pi-liaison-startup.md
  services/README.md
  services/pi_liaison/README.md
  services/pi_liaison/.env.template
  scripts/init-working-group.sh
  scripts/start-pi-liaison.sh
  scripts/check-secrets.sh
  scripts/mask-secrets.sh
)

if [ ! -x "${init_script}" ]; then
  echo "Init script is missing or not executable: ${init_script}" >&2
  exit 1
fi

first_output="$("${init_script}" --workspace "${workspace}" --template-root "${template_root}")"
second_output="$("${init_script}" --workspace "${workspace}" --template-root "${template_root}")"

for dir in "${required_dirs[@]}"; do
  if [ ! -d "${workspace}/${dir}" ]; then
    echo "Missing required directory: ${workspace}/${dir}" >&2
    exit 1
  fi
  if [ ! -f "${workspace}/${dir}/README.md" ]; then
    echo "Missing directory README: ${workspace}/${dir}/README.md" >&2
    exit 1
  fi
done

for file in "${required_files[@]}"; do
  if [ ! -f "${workspace}/${file}" ]; then
    echo "Missing required file: ${workspace}/${file}" >&2
    exit 1
  fi
done

if [ ! -x "${workspace}/scripts/start-pi-liaison.sh" ]; then
  echo "PI Liaison startup script is not executable: ${workspace}/scripts/start-pi-liaison.sh" >&2
  exit 1
fi

if [ ! -x "${workspace}/scripts/check-secrets.sh" ]; then
  echo "Secret checker is not executable: ${workspace}/scripts/check-secrets.sh" >&2
  exit 1
fi

if ! grep -q "Files created: 0" <<< "${second_output}"; then
  echo "Init script is not idempotent; second run created files." >&2
  echo "${second_output}" >&2
  exit 1
fi

if ! grep -q "Files updated: 0" <<< "${second_output}"; then
  echo "Init script is not idempotent; second run updated files." >&2
  echo "${second_output}" >&2
  exit 1
fi

echo "${first_output}" >/dev/null
echo "Working group smoke test passed: ${workspace}"
