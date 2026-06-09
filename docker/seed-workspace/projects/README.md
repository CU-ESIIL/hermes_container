# Projects

Use `projects/` for durable project-level routing. A project folder is not a data dump. It is a small control folder that tells humans and agents where the active project lives, which GitHub repositories are authorized, which external data stores are linked, and which outputs are local snapshots versus remote or mounted resources.

Recommended layout:

```text
projects/<slug>/
  README.md
  PROJECT.yaml
  DATA_MANIFEST.md
  GITHUB_REPOS.md
  EXTERNAL_LINKS.md
  WORKSPACE_NOTES.md
```

Keep large files in `/external_storage`, remote object stores, STAC catalogs, WebDAV/iRODS mounts, or authorized GitHub repositories. Store only manifests, relative paths, citations, licenses, and reproducibility notes in the project folder.

Agents should treat project folders as routing maps:

- read `PROJECT.yaml` before starting work
- inspect `DATA_MANIFEST.md` before downloading or copying data
- inspect `GITHUB_REPOS.md` before git operations
- use `EXTERNAL_LINKS.md` to find mounted or remote data
- record handoffs and local assumptions in `WORKSPACE_NOTES.md`

Do not store credentials, OAuth callbacks, API keys, private tokens, or unrestricted external-drive mounts here.
