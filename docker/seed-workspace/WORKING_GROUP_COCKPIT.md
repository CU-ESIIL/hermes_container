# Working Group Cockpit

This is the default orientation page for an OASIS Hermes working group. It should help a scientist understand where they are, what changed recently, what needs review, and what to do next without first reading logs or managing infrastructure.

## Identity

| Field | Value |
| --- | --- |
| Working group | OASIS Hermes |
| Short name | Hermes |
| Subtitle | ESIIL's multi-agent workspace |
| Lifecycle state | proposed |
| Runtime | Containerized Hermes workspace |
| Control principle | GitHub = control plane; repo = memory; container = runtime |

## Mission

Use this workspace to support environmental data science, synthesis science, reproducible workflows, visible scientific outputs, and human-reviewed collaboration. The platform should feel like entering a scientific working group, not opening a generic chatbot.

## What To Do Next

1. Ask the PI Liaison to begin the project intake in `PROJECT_INTAKE.md`.
2. Draft or update `PROJECT_CHARTER.md`.
3. Review `TEAM_BRIEF.md`, `INITIAL_TASKS.md`, and `QUESTIONS_FOR_USER.md`.
4. Record major choices in `DECISIONS.md` and uncertainties in `ASSUMPTIONS.md`.
5. Use `documents/ARTIFACT_REGISTRY.md` to track scripts, figures, reports, maps, and manuscripts.
6. Run a checkpoint before publishing, pushing to GitHub, launching long jobs, or changing integrations.

## Current State Checklist

| Area | Status | Notes |
| --- | --- | --- |
| Project charter | not started | PI Liaison should interview the user first. |
| Team brief | template | Update after intake. |
| Active tasks | template | Update `INITIAL_TASKS.md`. |
| Decisions | template | Update `DECISIONS.md`. |
| Assumptions | starter set | Review `ASSUMPTIONS.md`. |
| Outputs | empty | Use `outputs/`, `reports/`, `figures/`, and `maps/`. |
| Storage | local first | Register external storage only after review. |
| Models | deployment-specific | See `MODEL_ASSIGNMENTS.md`. |
| Human review | required | See `HUMAN_REVIEW.md`. |

## Recent Changes

Use `daily_notes/`, `agent_reports/`, and `CONTINUOUS_IMPROVEMENT_LOG.md` for short updates. Important structural decisions belong in `DECISIONS.md`.

## Review Gates

Human approval is required before publication, deletion, GitHub pushes, installing new skills, mounting new folders, external API use with billing implications, or claims involving communities, Tribes, Indigenous knowledge, public health, legal rules, or policy recommendations.

## Powered By

OASIS Hermes is built on Hermes. Preserve Hermes attribution when documenting the runtime and gateway.
