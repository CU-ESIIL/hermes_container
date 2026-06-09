# ARTIFACT_REGISTRY.md - Project Artifact Map

Use this registry to track important project artifacts, their owners, dependencies, review status, and provenance. Keep entries concise enough to scan and specific enough to audit.

| Artifact ID | Owner | Type | Location | Version/date | Dependencies | Review status | Description |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `[ID]` | `[Role]` | `[data/script/figure/report/memo/model]` | `[path]` | `[date or version]` | `[inputs]` | `[draft/reviewed/blocked/approved]` | `[brief description]` |

## Rules

- Every analysis output should link back to scripts, data sources, and assumptions.
- Every figure should link back to the script or workflow that created it.
- Every major claim should link to evidence, citations, analysis outputs, or a documented assumption.
- Do not mark an artifact as approved unless the relevant review gate has happened.
