# OASIS Hermes Container

Hermes Container is an ESIIL/OASIS research appliance for running Hermes in a reproducible, authorized, workspace-aware container.

```text
GitHub = control plane
repo = memory
container = runtime
```

The repository holds durable project memory and appliance code. The container provides the runtime. The mounted workspace, visible filesystem panel, GitHub manager, and Verde-aware model configuration make that runtime inspectable.

## Quick Start

```bash
cp .env.example .env
make init-working-group
make doctor
make build
make up
```

Open:

- Hermes gateway: `http://127.0.0.1:18789`
- Filesystem and GitHub manager host: `http://127.0.0.1:8090`
- JupyterLab: `http://127.0.0.1:8888/lab?token=hermes`

## Included Capabilities

- Hermes Agent workbench installed from the upstream Nous Research Hermes runtime
- Docker and Compose setup with separate secrets overlay
- visible filesystem browser for `/workspace`, outputs, docs, and storage roots
- GitHub manager with explicit repository allowlisting and safe branch/PR flow
- Verde API provider and secrets model with `_FILE` support
- multi-instance launcher with safe runtime-root fallback
- MkDocs documentation site
- smoke tests and GitHub Actions validation

## Secrets

Keep secrets out of git. For local deployment, the intended pattern is:

```bash
mkdir -p secrets
printf '%s\n' 'github_pat_or_fine_grained_token' > secrets/github_token
chmod 600 secrets/github_token
docker compose -f docker-compose.yml -f docker-compose.secrets.yml up -d
```

The same `_FILE` contract works for Verde credentials such as `VERDE_LLM_API_KEY_FILE` and `AI_VERDE_API_KEY_FILE`.

## Workspace Model

- repository root: appliance code, docs, scripts, tests
- `./workspace` -> `/workspace`: active project workspace
- `workspace/outputs/` and `/data/outputs/`: generated outputs
- `${HERMES_STATE_DIR}` -> `/data/.hermes`: Hermes runtime state
- `./secrets`: local secret source for the optional secrets overlay

## Core Commands

| Command | Purpose |
| --- | --- |
| `make build` | Build the local image |
| `make up` | Start the compose stack |
| `make down` | Stop the compose stack |
| `make shell` | Open a shell in the Hermes container |
| `make doctor` | Run local health checks |
| `make smoke-test` | Run the validation suite |
| `make workspace-smoke-test` | Validate the filesystem panel |
| `make github-smoke-test` | Validate the GitHub manager |
| `scripts/start-instance.sh name 18790 8889 8091` | Launch an isolated second instance |

## Docs

Start with [`docs/index.md`](/Users/tuff/Library/CloudStorage/OneDrive-UCB-O365/Documents/github/hermes_container/docs/index.md), [`docs/start-here/first-10-minutes.md`](/Users/tuff/Library/CloudStorage/OneDrive-UCB-O365/Documents/github/hermes_container/docs/start-here/first-10-minutes.md), and [`docs/security-and-credentials.md`](/Users/tuff/Library/CloudStorage/OneDrive-UCB-O365/Documents/github/hermes_container/docs/security-and-credentials.md).

## Current Assumptions

- Hermes uses the upstream Nous Research Hermes Agent runtime and dashboard.
- Verde and GitHub credentials are deployment-specific and injected at runtime.
- The filesystem and GitHub panels are intentionally lightweight control surfaces, not full IDE replacements.
