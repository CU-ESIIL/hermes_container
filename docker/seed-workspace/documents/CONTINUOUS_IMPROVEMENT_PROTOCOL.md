# Continuous Improvement Protocol

The continuous improvement loop is a bounded review practice for Hermes working groups. It helps agents and humans notice stale assumptions, fragile scripts, unclear prose, missing provenance, and incomplete review packets.

It is not an autonomous permission system. It does not grant authority to publish, delete files, push to GitHub, install new Hermes skills or system tools, mount broad folders, spend money, or bypass human review.

## Objectives

- Improve reproducibility of scripts, data flows, figures, and reports.
- Tighten scientific claims so they match evidence.
- Improve explanations for both expert and novice readers.
- Identify missing assumptions, decisions, citations, and review needs.
- Propose next simulations, sensitivity checks, or literature searches.
- Preserve a concise audit trail in `CONTINUOUS_IMPROVEMENT_LOG.md`.

## Loop Steps

1. **Trigger**: PI Liaison starts the loop manually, by heartbeat, or by a reviewed automation.
2. **Scope**: PI Liaison names the files, milestone, or question being reviewed.
3. **Role review**: Relevant agents inspect their own outputs and write short findings in `agent_reports/`.
4. **Synthesis**: Deputy Director / Integrator merges overlapping findings and flags conflicts.
5. **Skeptic check**: Skeptic / Adversarial Reviewer identifies overclaims, missing controls, and brittle assumptions.
6. **Action proposal**: The team proposes small edits, tests, or next tasks.
7. **Human gate**: PI Liaison asks the user only for decisions that affect scope, publication, risk, cost, credentials, or scientific direction.
8. **Record**: PI Liaison updates `CONTINUOUS_IMPROVEMENT_LOG.md`, `DECISIONS.md`, `ASSUMPTIONS.md`, and `QUESTIONS_FOR_USER.md` as needed.

## Allowed Without Additional Human Approval

- Drafting review notes.
- Proposing edits.
- Adding missing provenance notes.
- Improving wording in private drafts.
- Adding small smoke tests for known behavior.
- Updating artifact registries and assumptions.

## Requires Human Approval

- Publishing or promoting public claims.
- Deleting files or overwriting user-edited artifacts.
- Pushing to GitHub.
- Installing third-party Hermes skills, system tools, or durable template dependencies.
- Mounting new host folders.
- Sending emails or messages outside the approved PI Liaison channel.
- Running expensive, long, or externally billed jobs.
- Making claims about communities, Tribes, Indigenous knowledge, public health, legal rules, policy, or governance.

Routine package installs inside the disposable running container may proceed when needed for analysis, provided the command and purpose are logged and the package is not a credential tool, external service client with billing implications, or broad execution framework.

## Output Expectations

Each loop should produce one short entry in `CONTINUOUS_IMPROVEMENT_LOG.md` and, when useful, one concise review packet in `agent_reports/`.

Avoid long unstructured transcripts. The point is to make the next human decision easier.
