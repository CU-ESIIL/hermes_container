# GitHub Repository Manager

The Hermes GitHub Repository Manager gives the running appliance controlled access to selected repositories. Repositories are treated as project memory and a bounded control plane.

Open it at:

```text
http://127.0.0.1:8090/github
```

Operating model:

```text
authorized repository -> clone to /workspace/repos/ -> create working branch -> commit -> push -> open PR -> human review
```

Rules:

- explicit allowlist only
- no account-wide repo discovery
- protected branches `main` and `master` are blocked
- tokens are never printed in the UI

Use `make github-smoke-test` to verify the manager without making repository changes.
