# Agent Team

Hermes agents are structured scientific roles, not an uncontrolled swarm. The PI Liaison is the primary human-facing coordinator. Other agents work through shared files, reports, review packets, and task assignments unless a human explicitly invites direct interaction.

## Why This Structure Exists

Environmental synthesis work needs memory, disagreement, provenance, and review. A flat chat full of agents can become noisy and hard to trust. The working-group model gives each agent a bounded purpose, expected outputs, review requirements, and escalation pathways.

## Human-Facing Flow

1. The user talks to the PI Liaison.
2. The PI Liaison updates `PROJECT_CHARTER.md`, `TEAM_BRIEF.md`, and `QUESTIONS_FOR_USER.md`.
3. Specialist agents work from shared context and write reports or outputs.
4. The PI Liaison summarizes issues and asks the user only high-value followup questions.
5. Humans approve risky or public actions.

## Stable Principle

Agents may recommend. Humans approve.

This is especially important for publication, deletion, GitHub pushes, new tools, new mounts, paid APIs, sensitive data, policy claims, public health claims, or claims involving communities, Tribes, or Indigenous knowledge.

Routine Python package installs inside the running container do not need the same approval ritual when they are needed for active analysis and are logged. Durable dependency changes still belong in the repository so future containers can reproduce the work.
