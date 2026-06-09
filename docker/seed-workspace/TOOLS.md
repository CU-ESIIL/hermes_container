# TOOLS.md - Local Tool Notes

Use this file to document local, non-secret tool details for a deployment.

Do not store credentials, API keys, passwords, OAuth callbacks, SSH private keys, tokens, or sensitive host paths here. Store secrets only in approved local secret mechanisms such as `.env` or Hermes's local auth store.

## Tool Inventory

| Tool or service | Purpose | Access method | Notes | Review needed |
| --- | --- | --- | --- | --- |
| Hermes Gateway | Local agent gateway and Slack connection | Docker service | Started by repo scripts | Human approval for auth changes |
| Slack | PI Liaison intake and review surface | Socket Mode env vars | PI Liaison only | Human approval for external messaging scope |
| AI-VERDE / CyVerse | Optional open-model API experiments | `.env` placeholders | See `MODEL_ASSIGNMENTS.md` | Human approval for provider changes |
| Spatiotemporal worker | Bounded STAC/COG/Zarr analysis jobs | Task YAML and worker image | Local worker runs and optional Kubernetes Jobs | Human approval before cluster execution, new mounts, or broad RBAC |
| Hermes file manager | Inspect and edit safe workspace files | CMS sidebar or `/files` | Uses the same `/workspace` and `/external_storage` mounts agents see | Human approval for deletion or sensitive changes |
| Hermes GitHub manager | Manage authorized project repositories | CMS sidebar or `/github` | Registry: `/workspace/.openclaw-github/authorized-repos.yaml`; clones: `/workspace/repos/` | Human approval for push/PR/repo scope changes |
| Project resource map | Route projects to files, repos, and remote data | `RESOURCE_MAP.md` plus `projects/<slug>/` manifests | Read before filesystem, GitHub, or external-data work | Human approval for new mounts, credentials, or large transfers |

## Local Notes

Add deployment-specific notes here only when they are safe to commit or safe to keep in the local workspace. If a note would expose private infrastructure or credentials, do not put it here.
