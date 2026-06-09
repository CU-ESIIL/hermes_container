# Kubernetes Workers

Kubernetes support is optional and experimental. It is included so future deployments can run bounded spatial-temporal jobs in isolated worker containers without changing the local-first workflow.

## Concept

A trusted human or agent writes a task configuration. A local worker or Kubernetes Job runs the task, streams data when possible, writes outputs to persistent storage, and exits. The worker is an execution boundary, not a new autonomous personality.

## Safety Defaults

The scaffold avoids cluster-admin permissions, baked kubeconfig, broad host mounts, recursive job spawning, and real secrets. Use namespaces, minimal RBAC, resource limits, explicit output directories, and human review before applying manifests.

## Local First

Use local workers before a cluster:

```bash
HERMES_WORKER_OFFLINE=1 ./scripts/run_worker_local.sh examples/spatiotemporal/tasks/example_stac_preview.yaml --offline
```

Only move to Kubernetes when the local task is clear, bounded, and reproducible.

