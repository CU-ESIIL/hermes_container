# GitHub Repo As Memory

The repository is the source of truth for the reusable template and any project files you choose to version.

It stores:

- documentation,
- startup scripts,
- container configuration,
- seed workspace files,
- agent role definitions,
- public reports and dashboards,
- tests and health checks.

## What Should Be Committed

- Reusable template improvements.
- Public documentation.
- Small text-based project memory files.
- Scripts, tests, and configuration examples.
- Reviewed reports intended for publication.

## What Should Stay Local Or External

- `.env` files.
- API keys and Slack tokens.
- private data,
- large raw data,
- generated caches,
- unreviewed sensitive notes.

GitHub is powerful because it gives history and recovery. It is risky when secrets or restricted data are committed. When unsure, pause and document the uncertainty.

