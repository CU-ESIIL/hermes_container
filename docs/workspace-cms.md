# Workspace CMS

The Hermes workspace CMS is a lightweight, file-backed review layer for moving from private work to public documentation. It also provides the integrated workspace file manager at `/files` and the GitHub repository manager at `/github`. It does not replace MkDocs, JupyterLab, or the Hermes gateway, and it does not execute arbitrary commands. Its job is to help humans inspect files, record review status, manage selected project repositories, and promote approved artifacts.

Start it locally with:

```bash
docker compose up workspace-cms
```

Then open `http://127.0.0.1:8090` for the review home page, `http://127.0.0.1:8090/files?path=/workspace` for the file manager, or `http://127.0.0.1:8090/github` for selected project repositories.

Every full CMS page includes header navigation back to the matching Hermes Control UI, plus links to CMS Home, Files, and GitHub. For spawned instances, `OPENCLAW_GATEWAY_PORT` or `HERMES_GATEWAY_URL` tells the CMS which Hermes page the **Back to Hermes** button should open.

The CMS can browse configured roots:

- `/workspace` for private drafts, notes, notebooks, and agent outputs.
- `/data/outputs` for generated job artifacts.
- `/repo/docs` for the public MkDocs source.
- `/repo/examples` for committed examples.
- `/repo/storage` for storage templates.
- `/external_storage/local` for optional large-data mounts.

The file manager can visually browse from `/`, while hiding sensitive paths and restricting writes to configured safe roots. See [Workspace File Manager](workspace-file-manager.md) for the user-facing file workflow.

The GitHub manager only operates on explicitly authorized repositories cloned under `/workspace/repos/`. See [GitHub Repository Manager](github-repository-manager.md) for authentication, registry, branch, and pull-request workflow details.

## Metadata

The CMS writes sidecar metadata files next to reviewed artifacts:

```json
{
  "status": "needs_review",
  "visibility": "private",
  "source_files": ["/workspace/analysis/example.ipynb"],
  "outputs": ["/workspace/figures/example.png"],
  "external_data": [
    {
      "store": "public_stac_demo",
      "href": "https://earth-search.aws.element84.com/v1"
    }
  ],
  "publish_target": "docs/reports/example.md"
}
```

Use this metadata to preserve provenance from prompts, agents, notebooks, scripts, source data, and review decisions.

## Promotion Workflow

1. Agent or user creates draft output in `/workspace` or `/data/outputs`.
2. CMS displays the draft and any provenance metadata.
3. User marks the artifact as `needs_review` or `approved`.
4. Approved Markdown is promoted into `docs/reports/` or `docs/dashboard/`.
5. Small approved assets are copied into `docs/assets/cms/`.
6. Large outputs stay in `/external_storage` or remote stores and are represented by metadata and links.
7. MkDocs builds the public site from `docs/`.

Public pages must not require a private workspace mount, local secrets, or private storage credentials.
