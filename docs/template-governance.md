# Template Governance

The container now seeds more than folders and role names. It includes a small governance kit so new deployments start with reusable norms, decision rules, role handoff notes, and review checklists.

These files are templates, not automatic approval. A local team should review them during project intake and record any adopted changes in `/workspace/DECISIONS.md`.

## Seeded Governance Files

| File | Purpose |
| --- | --- |
| `/workspace/documents/TEAM_NORMS.md` | Shared operating norms for evidence, provenance, disagreement, and human review. |
| `/workspace/documents/DECISION_PROTOCOL.md` | Decision classes and escalation rules. |
| `/workspace/documents/CONTINUOUS_IMPROVEMENT_PROTOCOL.md` | Bounded self-review loop for improving drafts, scripts, provenance, tests, and assumptions without bypassing human review. |
| `/workspace/documents/MEMORY_QUARANTINE_PROTOCOL.md` | Rules for keeping parallel project memory separated until deliberately promoted. |
| `/workspace/documents/ARTIFACT_REGISTRY.md` | A lightweight register for scripts, data, figures, reports, and review status. |
| `/workspace/documents/SOCIETAL_IMPACT_CHECKLIST.md` | Review checklist for sensitive claims and public translation. |
| `/workspace/CONTINUOUS_IMPROVEMENT_LOG.md` | Short log of self-review loops, findings, actions proposed, and human-review needs. |
| `/workspace/agent_reports/role_reproducibility_index.md` | Index of role-specific reproducibility notes. |
| `/workspace/agent_reports/*_reproducibility_notes.md` | Per-role inputs, outputs, decision rights, handoffs, and failure checks. |
| `/workspace/agent_reports/continuous_improvement_review_template.md` | Reusable format for role-specific self-review findings. |
| `/workspace/meetings/TEMPLATE.md` | Meeting structure for review, decisions, and action items. |
| `/workspace/data/` | Raw, processed, and derived data directories with provenance expectations. |
| `/workspace/memory/quarantine/` | Project-scoped memory area for isolated exploratory work. |

## Adoption Pattern

1. The PI Liaison introduces the governance files during intake.
2. The user approves, revises, or defers local governance.
3. Approved decisions are recorded in `/workspace/DECISIONS.md`.
4. Role reports and artifact registries are updated as the project progresses.

The aim is repeatable scientific work, not bureaucracy. If a file does not help preserve evidence, decisions, assumptions, or review state, simplify it.

## Continuous Improvement Loop

The continuous improvement loop is for private, bounded self-review. It can be triggered manually, by heartbeat, or by an approved automation. The PI Liaison scopes the review, relevant roles write findings, the Deputy Director integrates them, the Skeptic checks overclaims, and the PI Liaison asks the user only for decisions that matter.

The loop may propose edits, tests, clearer prose, provenance updates, or new simulations. It does not authorize publication, deletion, GitHub pushes, new skills, new mounts, paid API use, or sensitive claims.
