# Hermes Storage Registry

Hermes separates three storage zones:

- `repo/` is the public template, docs site source, examples, and small public assets.
- `/workspace` is the private working lab for drafts, notes, notebooks, agent outputs, and review packets.
- `/external_storage` is the optional large-data shelf for mounted folders, object storage, STAC catalogs, COGs, Zarr stores, Parquet collections, NetCDF files, and model outputs.

Copy `storage.example.yml` to `storage.yml` for a local deployment. Keep `storage.yml` free of literal credentials. Use environment variable names for secrets, and keep real values in `.env`, shell environment, Docker secrets, or Kubernetes Secrets.

The first implementation is intentionally light. It gives agents and humans a shared vocabulary for registering, browsing, caching, and syncing storage targets without assuming AWS, iRODS, CyVerse, WebDAV, Kubernetes, or a particular institutional platform.

## Commands

Run from the repository root:

```bash
scripts/openclaw-storage list --config storage/storage.example.yml
scripts/openclaw-storage test --config storage/storage.example.yml
scripts/openclaw-storage browse public_stac_demo --config storage/storage.example.yml
scripts/openclaw-storage register --name my_dataset --href https://example.org/catalog.json --type stac --config storage/storage.yml
scripts/openclaw-storage cache --dataset public_stac_demo --config storage/storage.example.yml --dry-run
scripts/openclaw-storage sync-output /workspace/outputs/run_001 --store local_external --config storage/storage.example.yml --dry-run
```

The helper scripts avoid printing secret values. Live remote checks and data movement should be explicit, reviewed, and documented.
