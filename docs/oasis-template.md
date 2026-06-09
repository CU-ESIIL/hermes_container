# OASIS Hermes Template

OASIS Hermes is the spawnable working-group layer of this repository. It treats GitHub as the control plane, the repository as institutional memory, and the container as an ephemeral runtime.

The central design goal is not to create another chatbot wrapper. The goal is to make a reusable, calm scientific organization that can be cloned, customized, and relaunched for environmental synthesis projects.

## Core Principles

| Principle | Meaning |
| --- | --- |
| GitHub = control plane | Issues, branches, commits, pull requests, workflows, releases, and Pages make project state inspectable. |
| Repo = memory | Durable scientific knowledge belongs in Markdown, scripts, configs, examples, docs, and reviewed outputs. |
| Container = runtime | Containers can be rebuilt or replaced without losing the working group. |
| Agents may recommend | Humans approve publication, deletion, broad access, sensitive claims, and costly actions. |
| Optimize for the next 5 groups | Keep the template understandable before making it highly generalized. |

## Working Group Cockpit

Every spawned workspace includes `/workspace/WORKING_GROUP_COCKPIT.md`. This file gives users a calm first orientation:

- What project this is
- What the mission is
- What changed recently
- What should happen next
- Which outputs and reviews need attention
- Which approvals are required

This cockpit is deliberately simpler than an infrastructure dashboard. It emphasizes mission, tasks, outputs, memory, and review before exposing advanced runtime details.

## Canonical Configuration

The template includes a version-controlled default at `config/working_group.yaml` and a workspace copy at `/workspace/config/working_group.yaml`.

The configuration describes:

- project metadata
- branding
- enabled agents
- deployment profile
- integrations
- storage posture
- lifecycle state
- workflow modes
- publication settings
- human-review gates

Secrets never belong in this YAML. Use `.env`, GitHub Secrets, Docker secrets, Kubernetes Secrets, or other deployment-specific secret stores.

## Canonical Workspace Structure

The seed workspace includes scientific folders for source materials, outputs, review, and lifecycle state:

| Folder | Purpose |
| --- | --- |
| `datasets/` | Dataset inventory and access notes. |
| `data/` | Raw, processed, and derived project data with provenance. |
| `outputs/` | Private generated artifacts and job outputs. |
| `figures/` | Figures with script/data provenance. |
| `maps/` | Spatial outputs and map metadata. |
| `reports/` | Private report drafts and review packets. |
| `manuscripts/` | Manuscripts, supplements, and publication packages. |
| `presentations/` | Slides and workshop materials. |
| `notebooks/` | Exploratory and review notebooks. |
| `tasks/` | Role handoffs, task specs, and worker job YAML. |
| `reviews/` | Skeptic, citation, QA, reproducibility, and societal impact reviews. |
| `decisions/` | Supporting decision records. |
| `assumptions/` | Supporting assumption evidence and updates. |
| `runtime/` | Runtime diagnostics and operational notes. |
| `cache/` | Temporary or reproducible cached files. |

## Organizational Pattern

The existing PI Liaison remains the default human-facing role. The broader OASIS Hermes pattern uses tiers:

- **Coordination and leadership:** PI Liaison, Working Group Director, Project Operations Manager, Scientific Review and QA Director.
- **Scientific and analytical work:** environmental data science, geospatial analysis, metadata, open science, manuscript, and visualization roles.
- **Infrastructure and scaling:** container, Kubernetes, storage, GitHub automation, literature synthesis, and team-science support.

The ordinary user experience should stay centered on the PI Liaison, outputs, and review packets. Infrastructure agents should remain mostly hidden unless the user asks for deployment or runtime work.

## Branding

The Control UI branding layer is installed at container startup when `HERMES_BRANDING=1`.

The default brand text is:

- Full title: **OASIS Hermes**
- Short title: **Hermes**
- Subtitle: **ESIIL's multi-agent workspace**

The interface remains powered by Hermes; upstream attribution should be preserved in docs and operational notes.

The branded Control UI includes a persistent current-working-group banner below the agent and model controls. The banner makes the active project identity visible when multiple Hermes instances are running side by side. Click the banner title or its Edit control to save a browser-local title, set `HERMES_PROJECT_TITLE` in `.env` to force a deployment-specific title, or leave it at the default and let the banner read the project title from `PROJECT_CHARTER.md`.

The sidebar includes **Files** and **GitHub Auth** workspace tools. These show compact CMS-backed summaries directly in the sidebar, so users can inspect the filesystem, configure GitHub credentials, and reach repository actions without relying on slash commands.

## Checkpoints

The template includes `/workspace/CHECKPOINT.md` to encourage recoverable work. A checkpoint should summarize:

- what changed
- which files were touched
- which decisions and assumptions changed
- which outputs need review
- whether sensitive material is present
- whether a commit, issue, pull request, or release is appropriate

## Non-Goals

OASIS Hermes is not a fully autonomous scientist, a peer-review replacement, a generic enterprise orchestration platform, or a high-frequency inference service. It is a scientific collaboration and reproducibility workspace with bounded agent assistance.
