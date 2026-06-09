# Remote Storage

Remote storage should be configured through templates and environment variables, not hardcoded credentials.

Supported patterns include:

- STAC catalogs for metadata search.
- COG endpoints for HTTP range reads.
- Zarr stores over object storage or HTTP.
- Parquet collections read lazily with DuckDB or PyArrow.
- S3-compatible object storage, including institutional and OSN-style endpoints.
- WebDAV-backed shared drives.
- iRODS-backed research data systems.

Copy a profile from `storage/profiles/` into `storage/storage.yml`, then put real credentials in `.env`, Docker secrets, or Kubernetes Secrets. Use least-privilege scopes and read-only credentials when possible.

The first helper scripts validate configuration and provide safe dry-run behavior. Provider-specific syncing should be reviewed before enabling writes.

For active projects, also record the remote store in:

```text
/workspace/projects/<project-slug>/DATA_MANIFEST.md
/workspace/projects/<project-slug>/EXTERNAL_LINKS.md
```

That lets agents find and cite the data source without copying the whole dataset into `/workspace`.
