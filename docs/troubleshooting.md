# Troubleshooting

## Gateway page does not load

- confirm `make up` is still running
- check `docker compose ps`
- confirm the port in `.env` matches the port you are opening

## Filesystem or GitHub page loads but looks unbranded

Restart the stack. The upstream runtime UI is patched at container startup by the Hermes branding installer.

## Verde or GitHub auth looks missing

Run:

```bash
scripts/check_auth.sh
```

Confirm that you configured the expected environment variable or `_FILE` mount.

## Multi-instance launch fails

Check whether `HERMES_RUNTIME_ROOT` is writable. The launcher will fall back automatically, but a locked-down environment can still block temp-directory writes.
