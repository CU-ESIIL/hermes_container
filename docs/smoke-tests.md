# Smoke Tests

Hermes ships lightweight validation for local work and GitHub Actions.

## Main commands

```bash
make doctor
make smoke-test
make workspace-smoke-test
make github-smoke-test
make test-working-group
make test-layout
make test-secrets
```

These checks cover workspace seeding, data-layout initialization, filesystem behavior, GitHub manager safety, demo outputs, and secret hygiene.
