# Launch Locally

This page is for running OASIS Hermes on your own machine.

## Prerequisites

- Docker Desktop or a compatible Docker engine.
- Git.
- A local checkout of this repository.
- Optional model or integration credentials in `.env`.

## Start

```bash
cp .env.example .env
docker compose up --build
```

After the first build, use:

```bash
docker compose up
```

## Stop

```bash
docker compose down
```

This stops services. It does not automatically delete named volumes.

## Check Running Services

```bash
docker compose ps
```

## Common Local Interfaces

| Interface | Typical Use |
| --- | --- |
| Hermes Control UI | Chat, agents, sessions, gateway status |
| JupyterLab | Browse and edit workspace files |
| Workspace CMS | Review and promote reports into public docs |

If a port is already in use, start a second instance with the instance helper or adjust the port variables in `.env`.

## Start A Second Instance

Use this when one Hermes container is already running and you want a separate working group for a different project.

```bash
scripts/start-instance.sh project-two 18790 8889 8091
```

Arguments are:

| Argument | Example | Meaning |
| --- | --- | --- |
| instance name | `project-two` | folder name under `instances/` and Docker Compose project suffix |
| gateway port | `18790` | Hermes Gateway / Control UI |
| workspace UI port | `8889` | JupyterLab file browser |
| CMS port | `8091` | workspace CMS |

The instance stores its state separately under `instances/project-two/`, including its own `workspace`, `data`, `external_storage`, and Hermes state. This lets you keep multiple working groups open without mixing files.

After launching an additional instance, validate it before project work:

```bash
docker exec <gateway-container> openclaw agents list
docker exec <gateway-container> openclaw status
docker exec <gateway-container> openclaw agent \
  --agent main \
  --session-id instance-smoke-$(date +%s) \
  --message 'Reply with exactly: OK' \
  --timeout 120
```

The agent list should show the 11-role working group with `main` named PI Liaison. Use a unique smoke-test session id so the CLI does not collide with the browser's active chat transcript. See the [multi-instance runbook](../instance-runbook.md) for recovery steps if the dropdown is missing or the session locks.

!!! tip "Name instances after projects"
    Use memorable names such as `wildfire-synthesis`, `urban-greenspace`, or `workshop-demo`. The title banner inside the UI can be edited after launch.

!!! warning "Mount narrowly"
    Mount only the folders the working group needs. Avoid mounting your whole home directory into an agent-accessible container.
