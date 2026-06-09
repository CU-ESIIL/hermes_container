# Storage Model

Hermes uses three storage zones so users can tell what is durable, what is private, and what can be rebuilt.

## Repository Infrastructure

The repository contains the reproducible appliance: Docker files, scripts, MkDocs pages, seed workspace templates, examples, tests, and public reviewed artifacts. It should not contain secrets, local auth state, large raw data, or private working notes.

## `/workspace`

`/workspace` is the active working group area. Agents and humans use it for project charters, task files, assumptions, decisions, reports, notes, drafts, and small reproducible artifacts. In local development, it is mounted from `./workspace`, which is ignored by git unless a file is intentionally promoted into the repository.

## `/external_storage`

`/external_storage` is the large-data shelf. Use it for mounted data, local institutional storage, remote-backed datasets, or large outputs that should not be committed. The repository should store manifests, provenance, access methods, licenses, and citations rather than bulk data.

## `/workspace/projects`

`/workspace/projects/<project-slug>` is the project routing layer. Keep these folders small: they should point to imported snapshots, active workspace folders, authorized GitHub repositories, and external data stores. They should not contain full external drives, credentials, Hermes runtime state, or large raw data.

Use a project folder when one Hermes instance needs to take over work from another instance, coordinate several GitHub repositories, or connect to remote/mounted data without copying everything into the container.

## Practical Rule

If it is a reusable template improvement, commit it. If it is active project work, keep it in `/workspace` and route it through `/workspace/projects/<project-slug>`. If it is large or institutionally managed data, put it in `/external_storage` or a registered remote store and document it in the project manifest. If it is secret, keep it in `.env`, GitHub Secrets, Docker secrets, or the deployment secret system.
