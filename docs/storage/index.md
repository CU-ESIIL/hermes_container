# Storage Architecture

Hermes uses a three-zone storage model:

| Zone | Purpose | Git status |
|---|---|---|
| Repository | Public template, code, docs, examples, small public assets | Committed |
| `/workspace` | Private working lab for drafts, notes, notebooks, agent outputs, prompt logs, and intermediate analysis | Ignored |
| `/external_storage` | Optional large-data shelf for mounted or remote-backed artifacts | Ignored |

The repository is the home base and public story. `/workspace` is where the working group thinks and drafts. `/external_storage` is where large rasters, Zarr stores, Parquet collections, NetCDF files, COGs, and model outputs can live without being committed or baked into the image.

Storage locations are described in `storage/storage.yml`, copied from `storage/storage.example.yml`. The registry stores provider type, public URLs, local paths, and names of environment variables that contain secrets. It should not contain real credential values.

Useful commands:

```bash
scripts/openclaw-storage list --config storage/storage.example.yml
scripts/openclaw-storage test --config storage/storage.example.yml
scripts/openclaw-storage register --name my_dataset --href https://example.org/catalog.json --type stac
```

The default path works locally and anonymously. Advanced storage providers are optional.
