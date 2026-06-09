# Publishing Workflow

Hermes separates private scientific work from public publishing.

```text
/workspace draft
        |
        v
CMS review and provenance metadata
        |
        v
approved small artifacts
        |
        v
docs/reports, docs/dashboard, docs/assets
        |
        v
MkDocs build
        |
        v
GitHub Pages
```

Only approved material should move from `/workspace` into `docs/`. The public site must build without private mounts, local credentials, or unpublished datasets.

Use `docs/reports/` for narrative reports and synthesis products. Use `docs/dashboard/` for dashboard pages, static maps, output indexes, and browser-friendly summaries. Use `docs/assets/` for small public images, JSON, CSV, and supporting media.

Large private artifacts should stay in `/external_storage` or remote storage. Public pages can link to public endpoints or describe private artifacts with metadata when redistribution is not appropriate.

