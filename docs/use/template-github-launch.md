# Template GitHub Launch

This path is for turning Hermes into a reusable working-group appliance:

```text
use this repository as a template
  -> create or rename a project repository
  -> add GitHub Actions secrets
  -> run the launch workflow
  -> work inside Hermes with the same repository already visible
```

The goal is that the repository is the durable project memory, the container is the replaceable runtime, and credentials are injected at launch time instead of stored in git.

## 1. Create The Project Repository

On GitHub, use this repository as a template or fork it into the organization or account that owns the working group. Rename the new repository for the project, course, lab, workshop, or synthesis effort.

After creation, clone it locally if you want to edit docs or configuration from your laptop:

```bash
git clone https://github.com/<owner>/<new-repo>.git
cd <new-repo>
```

Do not commit local `.env` files, tokens, OAuth callbacks, workspace runtime state, or large private data.

## 2. Add Repository Secrets

In the new repository, open:

```text
Settings -> Secrets and variables -> Actions
```

Add these repository secrets:

| Secret | Required | Purpose |
| --- | --- | --- |
| `HERMES_GITHUB_TOKEN` | yes | Lets the running container fetch, branch, commit, push, and open pull requests against authorized repositories. |
| `HERMES_VERDE_LLM_API_KEY` or `VERDE_LLM_API_KEY` | yes for Verde | Authenticates the AI-VERDE model route. The workflow also accepts `HERMES_AI_VERDE_API_KEY` or `AI_VERDE_API_KEY`. |
| `SLACK_BOT_TOKEN` | optional | Enables Slack bot messaging. |
| `SLACK_APP_TOKEN` | optional | Enables Slack Socket Mode. |

Recommended variable:

| Variable | Purpose |
| --- | --- |
| `SLACK_DEFAULT_CHANNEL` | Default Slack channel or channel id for the PI Liaison. |

The workflow also accepts the longer `HERMES_...` names documented in [Security And Credentials](../security-and-credentials.md). The shorter names above match common local `.env` conventions.

## 3. Create The GitHub Token

Create a fine-grained personal access token for `HERMES_GITHUB_TOKEN`.

Use:

```text
Resource owner: the account or organization that owns the project repository
Repository access: only selected repositories
Selected repositories: the project repository, plus any extra repos agents should use
```

Minimum useful permissions:

| Permission | Level |
| --- | --- |
| Contents | Read and write |
| Metadata | Read |
| Pull requests | Read and write |
| Issues | Read and write, optional |

Scope the token narrowly. If agents later need another repository, update the token's selected repositories or add a new token, then add that repository in the Hermes GitHub manager.

## 4. Run The Launch Workflow

Open:

```text
Actions -> Hermes runtime from secrets -> Run workflow
```

Use the defaults for a smoke test. The workflow will:

- check out the repository
- write runner-local secret files
- seed `.env` from safe settings and secret-file paths
- add the launch repository to `/workspace/.hermes-github/authorized-repos.yaml`
- clone the launch repository into `/workspace/repos/<repo>`
- start the Hermes instance
- run Hermes and GitHub manager smoke checks

The launch repository is registered with `contribute` permission when `HERMES_GITHUB_TOKEN` is present. That means the GitHub manager and agents see the same cloned repository and can work on branches, push branches, and open pull requests through the managed workflow.

## 5. Choose The Runner Type

`ubuntu-latest` is useful for confirming that the template launches. It is ephemeral: the job starts a container, runs smoke checks, and then GitHub tears down the runner.

For a real shared working-group Gateway, use a self-hosted runner or another durable deployment host. A durable runner keeps Docker, workspace mounts, and the running services alive after launch. If the Gateway should be reachable by collaborators, add an approved network route such as a VPN, tunnel, reverse proxy, or institutional host.

## 6. Add More Repositories Later

Open the running Hermes UI and choose **GitHub Auth** in the sidebar.

Add additional repositories by `owner/repo`. They are recorded in:

```text
/workspace/.hermes-github/authorized-repos.yaml
```

Clones live under:

```text
/workspace/repos/
```

Humans, the sidebar GitHub panel, the full GitHub manager, and agents all read the same registry. Agents should only work inside authorized clones. Direct pushes to `main` and `master` are blocked by policy; use working branches and pull requests for review.

## 7. What Gets Saved

Keep durable project memory in git:

- reviewed docs under `docs/`
- project manifests under `projects/`
- small scripts, notebooks, metadata, and reproducibility notes
- branch and pull request history

Keep large or sensitive data outside git:

- remote drives
- object storage
- `/external_storage`
- mounted project data folders
- data manifests with source, license, access method, and citation notes

The container should be replaceable. The repository should explain how to rebuild the work.
