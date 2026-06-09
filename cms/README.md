# Hermes Workspace CMS

This is a deliberately small, file-backed content-management layer for Hermes deployments. It does not replace MkDocs. It helps users browse the private workspace, inspect outputs, edit Markdown drafts, attach status metadata, and promote approved files into the public MkDocs tree.

Run through Docker Compose:

```bash
docker compose up workspace-cms
```

Then open `http://127.0.0.1:8090`.

The CMS is scoped to configured roots and performs path checks before reading or writing files. It should remain a human-review tool, not a direct arbitrary execution surface.

