# Alpha Baseline

Version `0.1.0-alpha.1` is the first reproducible Hermes scientific working group baseline for this repository.

The default container image seeds `/workspace` with the scientific working group structure, PI Liaison workflow, bounded agent role definitions, project memory files, intake documents, and human-review rules. It also initializes `/data` as the persistent runtime root for Hermes state, outputs, logs, notebooks, skills, and other inspectable artifacts. Users should not need to recreate the agent setup manually after launching the container.

Slack credentials are not part of the image or git history. The image expects local environment-backed credentials from `.env`, registers the Slack channel with Hermes using `--use-env`, and validates required Slack variables before the PI Liaison starts.

## Reproduce the Alpha

```bash
cp .env.example .env
scripts/check-secrets.sh
docker compose build
scripts/start.sh
```

For a long-running Gateway service:

```bash
scripts/start-gateway.sh
```

For Slack-connected operation, follow the Gateway, Slack pairing, and live OAuth verification sequence in the [Operations guide](operations.md).

## What Is Included

- Eleven role definitions in `AGENTS.md`.
- PI Liaison startup prompt in `prompts/pi-liaison-startup.md`.
- Working-group memory files: `MEMORY.md`, `ROADMAP.md`, `DECISIONS.md`, `ASSUMPTIONS.md`, and `HUMAN_REVIEW.md`.
- Intake and routing files: `PROJECT_INTAKE.md`, `PROJECT_CHARTER.md`, `TEAM_BRIEF.md`, `INITIAL_TASKS.md`, `QUESTIONS_FOR_USER.md`, and `USER_CONTEXT.md`.
- Role-based model routing file: `MODEL_ASSIGNMENTS.md`.
- Governance and reproducibility templates: `TEAM_NORMS.md`, `DECISION_PROTOCOL.md`, `MEMORY_QUARANTINE_PROTOCOL.md`, `ARTIFACT_REGISTRY.md`, `SOCIETAL_IMPACT_CHECKLIST.md`, role reproducibility notes, and meeting templates.
- Directory READMEs for documents, analysis, figures, literature, meetings, daily notes, agent reports, logs, heartbeat, soul, prompts, services, and scripts.
- Hermes `/data` layout, optional JupyterLab workspace UI, document conversion examples, and brand assets.
- Slack secret validation and masking helpers.

## What Is Not Included

- Real Slack tokens.
- Real OpenAI API keys.
- User-specific Hermes auth profiles.
- Runtime logs, generated drafts, project outputs, or private workspace memory.
