# MEMORY.md - Working Group Memory

This workspace is a persistent environmental data science working group. The repository and mounted `/workspace` directory are the institutional memory for the project.

## Standards

- Claims must be tied to evidence.
- Analyses should be reproducible from documented scripts, data sources, and environment notes.
- Figures should trace back to scripts, data sources, and assumptions.
- Major decisions go in `DECISIONS.md`.
- Assumptions go in `ASSUMPTIONS.md`.
- Skeptic review is required before major claims are promoted into reports, manuscripts, presentations, or public pages.
- Human review is required before publishing, deleting data, installing new skills, mounting sensitive directories, modifying credentials, sending external messages, or making sensitive claims.
- The PI Liaison is the default human-facing role. Other agents should route routine questions through `QUESTIONS_FOR_USER.md`.

## Memory Practice

Use `daily_notes/` for dated notes and raw working memory. Promote only durable, project-level memory here. Keep entries concise, evidence-aware, and dated when possible.

## Quarantined Memory

When the group is exploring multiple projects that should not share assumptions or context by default, use `memory/quarantine/<project_slug>/`. Follow `documents/MEMORY_QUARANTINE_PROTOCOL.md`. Quarantined memory should not be promoted into shared project memory, decisions, assumptions, charters, or briefs until the destination owner reviews it and the promotion rule is satisfied.
