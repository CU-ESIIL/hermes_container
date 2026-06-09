# Distributed Spatial-Temporal Runtime

Hermes now includes a scaffold for bounded distributed analysis. The goal is an AI-native environmental workflow runtime, not an autonomous container swarm.

## Architecture

```text
Hermes UI / Agent
        |
        v
Task Config YAML
        |
        v
Local Worker or Kubernetes Job
        |
        v
Stream STAC / COG / Zarr Data
        |
        v
Write Reports, Figures, Tables, Logs
        |
        v
Output Viewer / Workspace UI
        |
        v
Human Review
```

The sub-agent is primarily an execution boundary. It receives explicit inputs, runs a bounded task, writes durable outputs, and exits.

## Local Execution

Local execution is the primary test path. It uses the same worker logic as Kubernetes and writes to the same output structure.

```bash
HERMES_WORKER_OFFLINE=1 ./scripts/run_worker_local.sh examples/spatiotemporal/tasks/example_stac_preview.yaml --offline
python3 scripts/build_output_index.py --data-root ./data
```

The runner prefers Docker and falls back to direct Python mode for debugging. Direct mode is useful for smoke tests but Docker mode better resembles a Kubernetes Job.

## Kubernetes Execution

Kubernetes is optional. The scaffold under `deploy/kubernetes/` includes:

- namespace pattern
- persistent volume claim pattern
- service account
- narrow Role and RoleBinding
- example analysis Job
- example worker Pod spec
- resource requests and limits
- job timeout and backoff settings
- ConfigMap task injection
- Secret mounting pattern

Render a bounded manifest without applying it:

```bash
python3 runtime/job-launcher/render_job_manifest.py \
  --task examples/spatiotemporal/tasks/example_stac_preview.yaml \
  --job-id example-stac-preview \
  --image hermes-spatiotemporal-worker:local
```

The submit helper is print-only by default. Use `--apply` only after human review and only with a configured namespace and cluster context.

## Task Configs

Task configs are YAML files. The initial example lives at `examples/spatiotemporal/tasks/example_stac_preview.yaml`.

Required fields:

- `task_name`
- `output_dir`
- `inputs`
- `analysis`
- `outputs`

Worker jobs should not accept arbitrary shell commands. Output directories should live under `/data/outputs/jobs/<job-id>/`.

## Output Structure

Each worker job writes:

- `task.yaml`
- `status.json`
- `logs.txt`
- `metadata.json`
- `report.md`
- `report.html`
- `figures/`
- `tables/`
- `maps/`

The output indexer scans `/data/outputs/jobs` and writes `/data/outputs/index.html`.

```bash
python3 scripts/build_output_index.py --data-root ./data
```

Start the browser workspace UI:

```bash
docker compose up workspace-ui
```

Open `http://127.0.0.1:8888` and inspect `/data/outputs/index.html`, job folders, reports, figures, CSV tables, JSON metadata, logs, notebooks, and maps.

## Stream-First Data Access

The runtime is oriented around cloud-native environmental data access:

- STAC catalog search before pixel reads
- COG window reads through HTTP range requests
- Zarr stores opened lazily with xarray
- object storage access through `fsspec`, `s3fs`, and `gcsfs`
- derived outputs persisted locally, not large source datasets

Installed core support includes GDAL, PROJ, GEOS, libspatialindex, rasterio, rioxarray, xarray, dask, zarr, geopandas, shapely, pyproj, fsspec, s3fs, gcsfs, aiohttp, requests, numpy, pandas, matplotlib, pyarrow, duckdb, pystac-client, odc-stac, stackstac, and folium.

Optional heavier packages to consider per deployment include `leafmap`, `rio-cogeo`, `cogeo-mosaic`, `planetary-computer`, `hvplot`, `holoviews`, and `datashader`.

## Safety

Do not:

- allow unbounded job spawning
- grant cluster-admin permissions
- bake credentials into images
- write secrets to logs
- let worker jobs recursively launch other jobs
- require Kubernetes for normal local use
- download giant source datasets in examples

Do:

- use bounded templates
- isolate namespaces
- use explicit task configs
- write outputs to known directories
- preserve logs and metadata
- keep artifacts browser-visible
- require human review before publication or downstream action
