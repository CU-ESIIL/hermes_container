# Setup

Hermes expects Docker with Compose, Python 3 for local validation, and a writable workspace in this repository.

## Local loop

```bash
cp .env.example .env
make init-working-group
make doctor
make build
make up
```

## Multi-instance startup

```bash
scripts/start-instance.sh project-two 18790 8889 8091
```

The launcher preserves the reference appliance pattern:

- isolated `instances/<name>/` directories
- isolated runtime state
- explicit port assignment
- safe fallback when `HERMES_RUNTIME_ROOT` is unavailable or unwritable
