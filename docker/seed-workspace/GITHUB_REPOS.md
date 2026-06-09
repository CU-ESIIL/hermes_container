# GitHub Repositories

This workspace uses the Hermes GitHub manager as the shared repository
control surface for humans and agents.

## Shared State

Authorized repositories are recorded here:

```text
/workspace/.openclaw-github/authorized-repos.yaml
```

Local clones live here:

```text
/workspace/repos/
```

The Hermes sidebar GitHub Auth panel, the CMS GitHub manager, and agents all
read this same workspace state.

## Agent Rules

- Treat the registry as an allowlist. Do not operate on repositories that are
  not listed there.
- Inspect and edit cloned repositories under `/workspace/repos/<repo>`.
- Use branches for contribution work. Do not push directly to `main` or
  `master`.
- Prefer the human-facing GitHub manager buttons for clone, fetch, pull, push,
  and pull request actions when the user is present.
- If shell git commands are needed, explain the action and use the normal
  Hermes approval flow.
- Never store GitHub tokens or credentials in workspace files.
