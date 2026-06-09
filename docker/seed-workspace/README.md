# Environmental Data Science Working Group

This `/workspace` directory is the persistent scientific working area for OASIS Hermes inside the container. It is designed to behave like a small environmental data science synthesis center: bounded roles, shared memory, reproducible analysis, documented assumptions, explicit disagreement, and human review.

In the Hermes container this same working area is available at `/data/workspace` and `/workspace`. The broader `/data` root holds runtime state, outputs, logs, notebooks, skills, and other inspectable artifacts that should survive container restarts.

## Start Here

1. Start with the PI Liaison interview in `PROJECT_INTAKE.md`.
2. Open `WORKING_GROUP_COCKPIT.md` to orient the project mission, status, next actions, and review gates.
3. Review or edit `config/working_group.yaml` for project identity, lifecycle state, integrations, and workflow modes.
4. Read `RESOURCE_MAP.md` before filesystem, GitHub, or external-data work.
5. Draft or review `PROJECT_CHARTER.md`.
5. Let the PI Liaison create `TEAM_BRIEF.md` and `INITIAL_TASKS.md`.
6. Record initial assumptions in `ASSUMPTIONS.md`.
7. Check `MODEL_ASSIGNMENTS.md` before routing work to a model or provider.
8. Review `documents/TEAM_NORMS.md` and `documents/DECISION_PROTOCOL.md` before treating local governance as settled.
9. Use `ROADMAP.md` to choose the current project phase.
10. Put literature and citation notes in `literature/`.
11. Put reproducible scripts in `scripts/` and analysis outputs in `analysis/`.
12. Put figures and maps in `figures/` and `maps/`, with notes linking each output to scripts and data sources.
13. Require Skeptic review before promoting major claims.
14. Use `HUMAN_REVIEW.md` before any external, destructive, expensive, or sensitive action.

## Directory Map

- `documents/` - charters, reports, manuscripts, memos, and synthesis drafts
- `projects/` - small project control folders linking workspace material, GitHub repositories, external data, and handoff notes
- `config/` - human-readable working-group configuration
- `WORKING_GROUP_COCKPIT.md` - first orientation page for status, mission, next actions, and review gates
- `data/` - intentionally added raw, processed, and derived data with provenance notes
- `datasets/` - dataset inventory and access notes
- `outputs/` - private generated artifacts and job outputs
- `analysis/` - reproducible analysis outputs and notebooks
- `figures/` - generated figures and figure provenance notes
- `maps/` - spatial outputs, map previews, and map provenance
- `reports/` - private report drafts and review packets
- `manuscripts/` - manuscript drafts, supplements, and publication packages
- `presentations/` - slides, workshop decks, and presentation exports
- `notebooks/` - exploratory and review notebooks
- `tasks/` - role handoffs, worker job specs, and task YAML
- `reviews/` - skeptic, QA, citation, reproducibility, and societal impact reviews
- `decisions/` - supporting decision records
- `assumptions/` - supporting assumption notes
- `literature/` - papers, source notes, citation inventories, and evidence tables
- `meetings/` - agendas, minutes, and action items
- `daily_notes/` - dated working notes
- `agent_reports/` - role-specific memos, reviews, and handoff notes
- `logs/` - user-requested logs or summaries
- `heartbeat/` - periodic check notes and lightweight reminders
- `soul/` - role tone, continuity, and working norms
- `memory/` - structured memory and quarantined project-specific context
- `prompts/` - startup prompts and role-specific prompt templates
- `runtime/` - diagnostics and operational notes that should not become the only scientific memory
- `cache/` - temporary or reproducible cached files
- `scripts/` - initialization, checks, reproducible workflows, and utilities

## PI Liaison

The PI Liaison / User Interview Agent is the default human-facing role. Other agents should file questions in `QUESTIONS_FOR_USER.md` instead of interrupting the user directly. The PI Liaison deduplicates those questions, asks only the highest-value followups, and returns milestone reports or drafts to the user for review.

When Slack is enabled, Slack is an intake and review surface for the PI Liaison, not a direct execution channel for the whole working group. Slack users should be paired intentionally, and requests that affect credentials, filesystem access, publishing, external APIs, or sensitive claims still require human review.

## Model Routing

Use `MODEL_ASSIGNMENTS.md` to decide which model route each role should use. The PI Liaison and Scientific Director should stay on the most reliable approved route, while bounded specialist tasks can be used to evaluate open-model API endpoints. Record model changes and failures in `DECISIONS.md` or `agent_reports/model_evaluations.md`.

## Governance Templates

The seed includes reusable templates for team norms, decision protocol, artifact registry, memory quarantine, societal impact review, role reproducibility notes, and meeting records. These files make the container more reproducible, but local teams should still review them before treating them as approved governance.

## Security Notes

Do not treat agents as safe just because the workspace is structured. Third-party skills, broad filesystem mounts, autonomous shell access, external APIs, and credentials all require careful review. Keep the mounted workspace narrow; do not mount the whole home directory.
