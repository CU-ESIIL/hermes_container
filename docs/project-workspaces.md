# Project Workspaces

Hermes keeps the appliance definition in the repository and active project work in the mounted workspace.

Standard shape:

```text
repository root/
  Dockerfile
  docker-compose.yml
  docs/
  scripts/
  workspace/
```

Use the workspace for active project context, drafts, outputs, and connected repos. Use the repository for reusable appliance infrastructure.
