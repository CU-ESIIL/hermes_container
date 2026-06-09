# GitHub Repositories

List project repositories authorized for this project. The machine-readable allowlist remains:

```text
/workspace/.openclaw-github/authorized-repos.yaml
```

| Repository | Local path | Permission tier | Purpose | Branch policy |
| --- | --- | --- | --- | --- |
| `owner/repo` | `/workspace/repos/repo` | `read` | source or collaboration repo | create branches for edits |

Agents should not push directly to `main` or `master`. Prefer the Hermes GitHub manager buttons for clone, pull, push branch, and PR creation.
