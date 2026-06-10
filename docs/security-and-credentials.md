# Secrets and Authorization

Hermes keeps secrets out of git and out of the image. Use `.env` for local development only, and prefer mounted secret files for deployment.

## Supported patterns

- direct environment variables
- `_FILE` variants such as `GITHUB_TOKEN_FILE`, `VERDE_LLM_API_KEY_FILE`, and `AI_VERDE_API_KEY_FILE`
- Docker Compose secrets overlay
- GitHub Actions secrets materialized into runner-local secret files before the container starts

## Local GitHub token example

```bash
mkdir -p secrets
printf '%s\n' 'github_pat_or_fine_grained_token' > secrets/github_token
chmod 600 secrets/github_token
docker compose -f docker-compose.yml -f docker-compose.secrets.yml up -d
```

## GitHub Actions launch secrets

The `Hermes runtime from secrets` workflow reads repository secrets and writes them into runner-local files under `./secrets/`. The files are mounted into the container and exposed through `_FILE` variables, so secret values are never committed to git or baked into the image.

Supported repository secret names:

- `HERMES_GITHUB_TOKEN` or `SCIENCECLAW_GITHUB_TOKEN`
- `HERMES_VERDE_LLM_API_KEY`, `SCIENCECLAW_VERDE_LLM_API_KEY`, `VERDE_LLM_API_KEY`, `HERMES_AI_VERDE_API_KEY`, or `AI_VERDE_API_KEY`
- `HERMES_SLACK_BOT_TOKEN`, `SCIENCECLAW_SLACK_BOT_TOKEN`, or `SLACK_BOT_TOKEN`
- `HERMES_SLACK_APP_TOKEN`, `SCIENCECLAW_SLACK_APP_TOKEN`, or `SLACK_APP_TOKEN`

Repository secrets are not copied when a repository is forked, templated, or copied from `CU-ESIIL/openclaw_container`. Add the secrets to the Hermes repository directly, or move shared values to organization secrets and grant the Hermes repository access.

## Verde authorization

Configure:

- `VERDE_LLM_BASE_URL`
- `VERDE_LLM_API_KEY` or `VERDE_LLM_API_KEY_FILE`
- optional `AI_VERDE_API_KEY` or `AI_VERDE_API_KEY_FILE`
- `VERDE_LLM_DEFAULT_MODEL`
- `VERDE_LLM_PROVIDER_NAME`

## Safe validation

```bash
scripts/check_auth.sh
```

The script reports configured or missing status only. It does not print secret values.
