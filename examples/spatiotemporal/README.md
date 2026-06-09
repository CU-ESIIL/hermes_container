# Stream-First Spatial-Temporal Examples

These examples show the Hermes runtime pattern for cloud-native environmental data:

- query STAC metadata before reading pixels
- read small COG windows instead of downloading full rasters
- open Zarr stores lazily
- write derived outputs under `/data/outputs`
- keep artifacts inspectable through JupyterLab or `outputs/index.html`

The examples use public, keyless sources where possible. Network availability and upstream catalog changes can still affect live runs, so the worker supports deterministic offline mode for smoke tests.

## Local Worker Example

```bash
HERMES_WORKER_OFFLINE=1 ./scripts/run_worker_local.sh examples/spatiotemporal/tasks/example_stac_preview.yaml --offline
python3 scripts/build_output_index.py --data-root ./data
```

Open `data/outputs/index.html` directly or through the optional `workspace-ui` service.

## Live STAC Examples

```bash
python3 examples/spatiotemporal/stac_search_example.py
python3 examples/spatiotemporal/stac_quicklook_report.py
```

These examples should remain small and quick. They should not download full source scenes into the repository.
