# Stream-First Data

Hermes favors stream-first environmental workflows:

| Mode | Meaning | When to use |
|---|---|---|
| `stream` | Read chunks, windows, or metadata directly from a remote source | Default for STAC, COG, Zarr, and Parquet |
| `cache` | Copy only the needed subset into `/workspace/cache` | Useful when repeated analysis needs the same small subset |
| `download` | Explicitly copy a dataset into `/workspace` or `/external_storage` | Use only after human review and provenance notes |

Avoid downloading giant source datasets into the container. Prefer STAC search, COG window reads, Zarr chunk access, Parquet filtering, and derived outputs.

Good public dashboard patterns:

1. Commit small public data under `docs/assets/data/`.
2. Reference public external data by URL.
3. Stream public STAC, COG, Zarr, or Parquet endpoints.
4. Publish static HTML, PNG, CSV, and lightweight JSON outputs.
5. Summarize large private data with metadata, plots, and links rather than committing it.

