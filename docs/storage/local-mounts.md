# Local Mounts

For a laptop deployment, keep the private workspace and large-data shelf as explicit bind mounts:

```bash
docker run \
  -p 18789:18789 \
  -p 8888:8888 \
  -p 8090:8090 \
  -v "$PWD/workspace:/workspace" \
  -v "$HOME/HermesData:/external_storage/local" \
  --env-file .env \
  openclaw-local
```

With Docker Compose, use:

```dotenv
WORKSPACE_DIR=./workspace
EXTERNAL_STORAGE_DIR=~/HermesData
HERMES_CMS_PORT=8090
```

Then start the services:

```bash
docker compose up openclaw-local workspace-ui workspace-cms
```

Keep `./workspace` and `./external_storage` ignored. Do not mount your whole home directory into the container. Narrow mounts make the agent workspace easier to inspect and safer to reason about.

For project-specific local data, prefer:

```text
/external_storage/local/<project-slug>
```

Then add the mount or folder to `/workspace/projects/<project-slug>/EXTERNAL_LINKS.md` and cite it from `/workspace/projects/<project-slug>/DATA_MANIFEST.md`.
