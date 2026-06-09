# CMS And Output Review

The CMS/output review layer is the bridge between private scientific work and public documentation. It exists because chat output is not enough for reproducible science. Figures, tables, reports, logs, metadata, and review status need to be visible and inspectable.

## Demo Workflow

Run:

```bash
make demo
```

The demo creates `workspace/outputs/demo/` with a CSV table, SVG figure, metadata JSON, and Markdown report. Open those files in the workspace UI or CMS. The point is operational proof: the appliance can run a workflow, write artifacts, and expose them for review.

## Review Pattern

1. Work starts in `/workspace` or `/data/outputs`.
2. The CMS previews the artifact and records metadata.
3. A human marks the artifact as draft, needs review, approved, or published.
4. Approved Markdown moves to `docs/reports/` or `docs/dashboard/`.
5. Small approved public assets move to `docs/assets/`.
6. Large or restricted outputs stay in external storage with documented provenance.

The CMS should not execute arbitrary shell commands. Its purpose is review, provenance, and promotion.

