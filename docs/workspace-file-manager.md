# Workspace File Manager

The Hermes workspace file manager is the visible filesystem surface for the appliance.

Open it at:

```text
http://127.0.0.1:8090/files?path=/workspace
```

Key paths:

| Path | Meaning |
| --- | --- |
| `/workspace` | active project workspace |
| `/workspace/outputs` | generated outputs in the project area |
| `/data/outputs` | durable output mount |
| `/external_storage/local` | large-data shelf |
| `/tmp` | scratch space |

The service hides `.env`, token-like files, secret mounts, and unsafe system paths. Use `make workspace-smoke-test` to validate it.
