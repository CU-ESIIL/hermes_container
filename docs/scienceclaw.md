# OASIS Hermes Workspace

<div class="hermes-hero" markdown>

<div markdown>

OASIS Hermes is the branded template layer for this Hermes container: a persistent environmental synthesis workspace with a PI Liaison, bounded scientific roles, durable memory, reproducible folders, and cautious human review gates.

Hermes remains one interface into the workspace. The repository is the source of truth, `/data` is the persistent runtime root, `/workspace` is the private scientific working area, and `/external_storage` is the optional large-data shelf.

</div>

![Hermes logo](assets/brand/hermes.png)

</div>

## Brand Foundation

The visual direction follows the provided Hermes and ESIIL materials: modern environmental science, clean information hierarchy, restrained colors, and visible links between computation, evidence, and ecological context. The default user-facing lockup is **OASIS Hermes** with the subtitle **ESIIL's multi-agent workspace**.

<div class="hermes-palette" markdown>

<div class="hermes-swatch" markdown><span style="background:#234a65"></span>`#234A65` Primary blue</div>
<div class="hermes-swatch" markdown><span style="background:#42bcdc"></span>`#42BCDC` Accent blue</div>
<div class="hermes-swatch" markdown><span style="background:#007135"></span>`#007135` Accent green</div>
<div class="hermes-swatch" markdown><span style="background:#161a19"></span>`#161A19` Body text</div>
<div class="hermes-swatch" markdown><span style="background:#e3e3e3"></span>`#E3E3E3` Relief gray</div>

</div>

Brand assets are tracked under `docs/assets/brand/` for documentation and future interface work. They are not used for secrets, auth, or runtime configuration.

## Persistent Layout

The container initializes a `/data` root for persistent runtime state and scientific artifacts:

| Path | Purpose |
| --- | --- |
| `/data/.openclaw` | Hermes state and auth profile storage. |
| `/data/workspace` | Primary scientific workspace, also available as `/workspace`. |
| `/external_storage/local` | Optional large local or institutional storage mounted outside git. |
| `/data/downloads` | User-approved downloads awaiting provenance review. |
| `/data/outputs/reports` | Rendered reports and review packets. |
| `/data/outputs/figures` | Generated figures and images. |
| `/data/outputs/tables` | Generated tables and CSV summaries. |
| `/data/skills/core` | Trusted shared skills. |
| `/data/skills/experimental` | Opt-in skills that need review before use. |
| `/data/skills/local` | Local deployment-specific skills. |
| `/data/notebooks` | Persistent notebooks. |
| `/data/stac` | STAC/geospatial catalog examples or configuration. |

The initializer is idempotent:

```bash
scripts/init-data-layout.sh --data-root /tmp/hermes-data
```

## Three-Zone Model

| Zone | Purpose | Publication rule |
| --- | --- | --- |
| Repository | Public template, docs, examples, small public assets, storage templates. | Committed and published intentionally. |
| `/workspace` | Private working lab for drafts, prompt logs, notebooks, notes, intermediate analysis, and review packets. | Ignored by git and promoted only after review. |
| `/external_storage` | Large rasters, Zarr stores, Parquet collections, NetCDF files, COGs, model outputs, and synced storage targets. | Ignored by git; public pages link to metadata or public endpoints. |

This separation keeps the public site reproducible while protecting private work and avoiding large accidental commits.

## Workspace Interface

The Hermes service exposes the Gateway and Control UI on `127.0.0.1:18789`. The optional `workspace-ui` service exposes JupyterLab on `127.0.0.1:8888` and points at `/data` so outputs, logs, notebooks, and the mounted workspace are browser-inspectable. The optional `workspace-cms` service exposes a small review interface on `127.0.0.1:8090`.

```bash
docker compose up openclaw-local
docker compose up workspace-ui
docker compose up workspace-cms
```

The default Jupyter token is `hermes`; set `WORKSPACE_UI_TOKEN` in `.env` for a local deployment.

Use the [Workspace CMS](workspace-cms.md) when a private artifact is ready for review. The CMS can mark status, preserve metadata sidecars, and promote approved content into `docs/reports/`, `docs/dashboard/`, or `docs/assets/`.

## Tools

The image includes baseline developer and scientific utilities: `git`, `gh`, `curl`, `wget`, `jq`, `ripgrep`, `tree`, `tmux`, `vim`, `nano`, `pandoc`, a lean LaTeX/PDF toolchain (`latexmk`, `lmodern`, `texlive-latex-base`, `texlive-latex-recommended`, `texlive-fonts-recommended`, `texlive-xetex`), `poppler-utils`, `imagemagick`, `ghostscript`, `qpdf`, `gdal-bin`, `proj-bin`, LibreOffice, Python, `uv`, JupyterLab, and Playwright Python bindings.

Document conversion examples live in `examples/`. Playwright browser binaries are intentionally not baked in by default; install them in a running container when that workflow is needed.

## Distributed Runtime

The [Distributed Spatial-Temporal Runtime](distributed-runtime.md) adds a bounded worker execution pattern for STAC, COG, Zarr, and object-storage workflows. It supports local worker runs first, with optional Kubernetes Job manifests for future lab or cloud execution.

## Safety Boundary

Hermes keeps workspace access narrow by default. Mount the specific project folder you want agents to inspect, not a whole home directory. Secrets stay in `.env` or service-specific credential stores and must not be copied into Markdown memory, reports, screenshots, or logs.
