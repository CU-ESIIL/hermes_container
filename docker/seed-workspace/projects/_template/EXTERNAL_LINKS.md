# External Links

Record mounted drives, object stores, catalogs, and remote folders used by this project.

| Name | Kind | Location | Credential source | Read/write | Notes |
| --- | --- | --- | --- | --- | --- |
| Local external shelf | local mount | `/external_storage/local/example-project` | none | read/write | Host-mounted; keep large data here. |

Use `storage/storage.yml` or project-specific manifests for structured storage definitions. Use environment variables, Docker secrets, GitHub Secrets, or deployment secrets for credentials.
