# Example Snapshots

The repository keeps the live `/workspace` directory ignored because it can contain local source materials, generated notes, runtime state, credentials, and project-specific files. When a workspace run produces outputs that should be preserved, copy a curated snapshot into `examples/`.

The first captured snapshot is `examples/urban_wildlife_corridors/`. It includes agent-generated documents, reports, a simulation script, analysis tables, and a figure from a Phase 0 urban wildlife corridor project. It intentionally excludes the original source uploads, `.env` files, Hermes auth state, Slack state, and broad runtime logs.

Use snapshots for reviewable examples of how the PI Liaison and working group structure behave. Do not treat a snapshot as default seed material for all new users unless the files belong in `docker/seed-workspace`.

## Pre-Remodel Capture Audit

Before shutting down the live container for the next remodel, inspect the ignored workspace and decide which files belong in the reusable template.

Captured as default template material:

- continuous improvement protocol, starter log, and role review template in `docker/seed-workspace`
- workspace CMS, publishing workflow, external storage registry, and public dashboard/report patterns
- bounded spatial-temporal runtime, worker job scaffold, output index, and Kubernetes templates
- generic team governance, role notes, security posture, model routing notes, and human-review gates

Captured as curated example material:

- `examples/urban_wildlife_corridors/` contains the first urban wildlife corridor project snapshot, including manuscript draft, synthesis notes, simulation code, outputs, figure, and project-state files.

Kept private in `/workspace` and backed up locally:

- uploaded source documents
- local virtual environments
- gateway logs
- runtime memory and dream-state files
- project-specific generated data not intended as default seed material
- one-off analysis scripts that are specific to the urban wildlife corridor project

The pre-remodel local safety snapshot is stored under `data/backups/` and remains ignored by git.
