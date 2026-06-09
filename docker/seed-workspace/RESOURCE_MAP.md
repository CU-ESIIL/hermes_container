# Resource Map

This file tells agents where to read, write, push, pull, mount, and document resources. Read it before filesystem, GitHub, or external-data work.

## Read And Write Surfaces

| Surface | Path or URL | Use for | Agent default |
| --- | --- | --- | --- |
| Active workspace | `/workspace` | working notes, reports, scripts, small outputs, project control files | read/write within project scope |
| Project routing | `/workspace/projects/<slug>` | project manifests, repo map, external links, handoff notes | read first, update when project resources change |
| Imported snapshots | `/workspace/imports/<source-date>` | preserved source material from other gateways/containers | read-only unless human approves promotion |
| GitHub clones | `/workspace/repos/<repo>` | authorized Git repositories cloned by the GitHub manager | read/write branches only when authorized |
| External shelf | `/external_storage/local/<project-slug>` | large local data, mounted remote-drive content, heavy outputs | read/write only after source and policy are documented |
| Private outputs | `/workspace/outputs/<project-slug>` | small generated reports, tables, figures, logs | write with provenance |
| Public docs source | `/repo/docs` | reviewed public website content | write only after review/approval |

## What To Read First

For a project-specific task:

1. `/workspace/projects/<slug>/PROJECT.yaml`
2. `/workspace/projects/<slug>/DATA_MANIFEST.md`
3. `/workspace/projects/<slug>/GITHUB_REPOS.md`
4. `/workspace/projects/<slug>/EXTERNAL_LINKS.md`
5. `/workspace/projects/<slug>/WORKSPACE_NOTES.md`
6. `/workspace/GITHUB_REPOS.md`

If no project slug is named, ask the PI Liaison or inspect `/workspace/projects/README.md`.

## GitHub Rules

- Authorized repositories are listed in `/workspace/.openclaw-github/authorized-repos.yaml`.
- Local clones live under `/workspace/repos/`.
- Use the Hermes GitHub manager when the user is present.
- Do not operate on repositories outside the allowlist.
- Do not push directly to `main` or `master`.
- Do not store tokens, callback URLs, or credentials in workspace files.

## External Data Rules

- Prefer stream-first or mount-first access over copying data into `/workspace`.
- Document every data source in `DATA_MANIFEST.md` before ingesting, caching, or transforming it.
- Put large data under `/external_storage/local/<project-slug>` or a registered remote store.
- Record source, access method, format, license, citation requirements, sensitivity, and storage mode.
- New host mounts, credentialed remote drives, billed APIs, or bulk downloads require human approval.

## When To Use Skills Or Jobs

Use static manifests for orientation. Use skills or jobs only when behavior needs to be repeated reliably.

- Create a skill for repeated expert workflows, such as "sync a project repo safely", "register a dataset", or "prepare a project release".
- Create a job for long-running or scheduled work, such as pulling remote data, refreshing a cache, running simulations, or syncing outputs.
- Keep skills and jobs bounded by the same human-approval rules as this file.
