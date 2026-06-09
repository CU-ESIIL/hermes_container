# Outputs And Reports

Outputs should be visible, inspectable, and traceable.

## Output Types

- figures,
- tables,
- maps,
- notebooks,
- markdown reports,
- HTML reports,
- logs,
- metadata files.

## Trust Requires Provenance

A useful output should answer:

- What data source did it use?
- What script or workflow produced it?
- What model or agent contributed?
- What assumptions were made?
- What review has happened?
- What should a human check before reuse?

## Recommended Structure

```text
/data/outputs/jobs/<job-id>/
  task.yaml
  status.json
  logs.txt
  metadata.json
  report.md
  report.html
  figures/
  tables/
  maps/
```

Use the workspace CMS and publishing workflow to move reviewed outputs into public documentation.

