# Tasks, Decisions, And Checkpoints

Everyday Hermes work should leave a readable trail.

## Tasks

Use task files to describe what needs to happen, who is responsible, what inputs are expected, and what output should be created.

Good tasks are bounded:

- clear input,
- clear output,
- clear owner,
- review requirement,
- stop condition.

## Decisions

Put meaningful choices in `DECISIONS.md` or the appropriate project decision log.

Record:

- date,
- decision,
- alternatives considered,
- rationale,
- owner,
- review date.

## Checkpoints

Use checkpoints at the end of a session or before risky changes.

```bash
make checkpoint
```

A useful checkpoint says:

- what changed,
- what is unresolved,
- what files matter,
- what should happen next,
- what should not be lost.

!!! note "Checkpoint before remodels"
    Before rebuilding containers, changing mounts, or reorganizing the workspace, capture the current state in a checkpoint file and git status.
