# Secrets and Authorization

Hermes keeps secrets out of git and out of the image. Use `.env` for local development only, and prefer mounted secret files for deployment.

## Supported patterns

- direct environment variables
- `_FILE` variants such as `GITHUB_TOKEN_FILE`, `VERDE_LLM_API_KEY_FILE`, and `AI_VERDE_API_KEY_FILE`
- Docker Compose secrets overlay

## Local GitHub token example

```bash
mkdir -p secrets
printf '%s\n' 'github_pat_or_fine_grained_token' > secrets/github_token
chmod 600 secrets/github_token
docker compose -f docker-compose.yml -f docker-compose.secrets.yml up -d
```

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
