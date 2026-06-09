# Quick Start

This page is the stable happy path for a new OASIS Hermes checkout. It assumes you are comfortable enough to run a few terminal commands, but it does not assume deep Docker or GitHub knowledge.

If you want the GitHub-hosted template path, where a forked or renamed repository launches Hermes from GitHub Actions with secrets and its own repository already visible to agents, use [Template GitHub Launch](use/template-github-launch.md).

## 1. Prepare Local Settings

```bash
cp .env.example .env
```

The `.env` file is local. Put tokens and local ports there, and do not commit it.

## 2. Initialize And Check The Workspace

```bash
make init-working-group
make doctor
```

`make init-working-group` creates the expected working-group scaffold. `make doctor` runs safe checks for repository structure, Docker availability, workspace files, and secret hygiene. Optional integrations may warn when they are not configured; warnings are not always failures.

## 3. Build And Start

```bash
make build
make up
```

The container starts with the PI Liaison workflow, a seeded `/workspace`, and the OASIS Hermes branding. When multiple instances are running, use `docker compose ps` to confirm ports.

After the stack is up, treat the three local URLs as separate surfaces:

| URL | Purpose |
| --- | --- |
| `http://127.0.0.1:18789/` | Main Hermes chat and control UI |
| `http://127.0.0.1:8090/` | Workspace CMS, file browser, and GitHub manager |
| `http://127.0.0.1:8888/lab` | JupyterLab workspace UI |

To open the main chat in a browser that can connect immediately, ask Hermes for the tokenized dashboard URL:

```bash
docker compose exec openclaw-local openclaw dashboard --no-open
```

Open the printed `http://127.0.0.1:18789/...` URL in your browser. That is the main Hermes chat surface. The `8090` page is useful, but it is the CMS sidecar rather than the primary chat UI.

On the first Control UI connection from a new browser, Hermes may require one-time device approval even when the gateway token is correct. If the page says `Device pairing required`, approve the exact request id from the gateway host:

```bash
docker compose exec openclaw-local openclaw devices list
docker compose exec openclaw-local openclaw devices approve <REQUEST_ID>
```

Then reload the `18789` chat page or reconnect from the tokenized dashboard URL.

## Restart Or Start Another Working Group

To restart the default local stack:

```bash
make up
```

To stop it:

```bash
make down
```

To start a separate working-group instance while another one is already open, use the instance helper with a unique name and ports:

```bash
scripts/start-instance.sh project-two 18790 8889 8091
```

This creates an isolated instance directory:

```text
instances/project-two/
  data/
  workspace/
  external_storage/
  openclaw/
```

The helper prints three links when it finishes:

| Link | Purpose |
| --- | --- |
| Gateway | Hermes chat and control UI for that instance |
| Workspace UI | JupyterLab file browser for that instance |
| Workspace CMS | Review and promote outputs for that instance |

Use a different instance name and different ports for each additional working group.

## 4. Run The Demo Workflow

```bash
make demo
```

The demo writes a deterministic toy habitat-suitability workflow to:

```text
workspace/outputs/demo/
  demo_habitat_suitability.csv
  figures/demo_habitat_suitability.svg
  metadata.json
  report.md
```

This demo is not intended to make a scientific claim. It proves that the workspace can run a reproducible scientific workflow and produce inspectable artifacts.

## 5. Review Outputs

Click **Files** in the Hermes sidebar to see a compact workspace listing. You can also open it directly:

```text
http://127.0.0.1:8090/files?path=/workspace
```

The file manager shows the container filesystem from `/`, but it treats `/workspace` as the normal project area. Browse to `workspace/outputs/demo/` to inspect the demo report, CSV table, and figure outputs. The CMS/output review layer is where private outputs become reviewed public artifacts. Approved reports can be promoted into `docs/reports/`; small approved figures can move into `docs/assets/`.

## 6. Connect Project Repositories

Click **GitHub Auth** in the Hermes sidebar to see credential status and setup actions. You can also open it directly:

```text
http://127.0.0.1:8090/github
```

Use this tab for other repositories that the working group should inspect or contribute to. The current container repository remains infrastructure. Connected repositories are project workspaces and clone into:

```text
/workspace/repos/
```

For local GitHub CLI authentication inside the container, run:

```bash
gh auth login
gh auth setup-git
gh auth status
```

For repeatable appliance-style launches, use a local Docker secret instead of interactive login:

```bash
mkdir -p secrets
printf '%s\n' 'github_pat_or_fine_grained_token' > secrets/github_token
chmod 600 secrets/github_token
docker compose -f docker-compose.yml -f docker-compose.secrets.yml up -d
```

The token should be fine-grained and scoped to the organization repositories this working group is allowed to use. On startup, Hermes reads the secret file, configures GitHub CLI for git credential use, and makes the same credential available to the Hermes agent runtime and the GitHub manager service.

For a spawned prototype instance such as gateway 3, use the same token file with the instance helper:

```bash
HERMES_GITHUB_TOKEN_FILE=./secrets/github_token \
HERMES_USE_SECRETS_OVERLAY=1 \
scripts/start-instance.sh project-three 18791 8890 8092
```

Then expand **GitHub Auth** in the sidebar and click **Configure git credentials**. The sidebar, the full GitHub manager, and the agents all refer to the same shared registry at `/workspace/.openclaw-github/authorized-repos.yaml` and cloned repositories under `/workspace/repos/`.

Add repositories explicitly by `owner/repo`. Use the `read` tier for inspection and the `contribute` tier when the working group may create branches, commit changes, push branches, and open pull requests. Direct pushes to `main` and `master` are blocked by default.

For template repositories launched from GitHub Actions, the launch workflow seeds the current repository into that registry and clones it under `/workspace/repos/<repo>`. Add other repositories later from **GitHub Auth**.

## 7. Validate And Checkpoint

```bash
make smoke-test
make checkpoint
```

`make smoke-test` checks structure, secret hygiene, demo execution, and expected outputs. `make checkpoint` writes a local `workspace/CHECKPOINT.md` summary so the state of the session can survive rebuilds and handoffs.

## Core Commands

| Command | Purpose |
| --- | --- |
| `make build` | Build the local container image |
| `make up` | Start the local Compose stack |
| `make down` | Stop the local Compose stack |
| `make shell` | Open a shell in the Hermes container |
| `make init-working-group` | Create or refresh the local workspace scaffold |
| `make doctor` | Run safe local health checks |
| `make demo` | Run the deterministic environmental demo |
| `make smoke-test` | Run lightweight operational validation |
| `make workspace-smoke-test` | Validate the workspace file manager |
| `make github-smoke-test` | Validate the GitHub repository manager |
| `make checkpoint` | Write a local checkpoint summary |
