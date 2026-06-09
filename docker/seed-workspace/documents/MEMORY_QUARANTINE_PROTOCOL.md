# MEMORY_QUARANTINE_PROTOCOL.md - Scoped Memory for Parallel Projects

Status: template baseline; review and adapt before treating as local governance.
Date: template
Owner: PI Liaison / User Interview Agent

This protocol keeps memory from different projects separate until the PI or working group intentionally promotes shared facts, decisions, or assumptions.

## Why quarantine memory

Use quarantined memory when the team is exploring multiple projects, research questions, hypotheses, datasets, audiences, or outputs that should not contaminate each other. Quarantine is especially useful when early assumptions, literature leads, model choices, or interpretation frames might be valid for one project but misleading for another.

## Directory pattern

Each scoped project gets its own directory:

`memory/quarantine/<project_slug>/`

Recommended files:

- `README.md`: project scope, owner, status, and boundaries.
- `working_memory.md`: raw notes, leads, partial findings, and context.
- `assumptions.md`: assumptions local to this project.
- `decisions.md`: decisions local to this project.
- `evidence.md`: sources, data leads, citations, and provenance.
- `handoff.md`: what another role needs to know before continuing.

## Minimum README fields

Each quarantine README should state:

- Project thread and any current research questions inside it.
- Owner or coordinating role.
- Status: exploratory, active, paused, merged, archived, or blocked.
- Scope boundary: what belongs here and what does not.
- Shared-memory rule: what must be true before content can move into `MEMORY.md`, `DECISIONS.md`, `ASSUMPTIONS.md`, `PROJECT_CHARTER.md`, or `TEAM_BRIEF.md`.
- Sensitive constraints or human-review gates.

## Promotion rule

Content can leave quarantine only when it is:

1. Clearly relevant beyond the scoped project.
2. Supported by evidence, a documented user decision, or a marked assumption.
3. Reviewed by the role that owns the destination artifact.
4. Not sensitive, external-facing, destructive, credential-related, or approval-gated unless explicitly approved by the human PI.

Promotions should preserve provenance by linking back to the quarantined source file.

## Cross-contamination rule

Agents should not use quarantined memory from one project to answer or guide another project unless the PI Liaison, Scientific Director, or human PI explicitly marks it as shared context.

## Naming

Use short, stable slugs:

- `salmon_temperature`
- `urban_heat_tree_canopy`
- `wetlands_methane`

Avoid vague names like `project1` once the topic is known.

## When to archive

Mark a quarantine as archived when the project is no longer active. Do not delete it without human approval. If durable lessons were promoted to shared memory, record where they went in `handoff.md`.
