# TEAM_NORMS.md - Working Group Norms

Status: template baseline; review and adapt before treating as local governance.
Date: template
Owner: PI Liaison / User Interview Agent

These norms define how the environmental data science working group operates together before a project-specific charter is approved.

## Operating norms

1. Evidence before synthesis. Claims should point to data, scripts, figures, literature notes, or explicit assumptions.
2. Role-bounded work. Each agent stays inside its mission, allowed files, and review limits from `AGENTS.md`.
3. One human-facing channel. Routine questions go through `QUESTIONS_FOR_USER.md` and are batched by the PI Liaison.
4. Disagreement is preserved. Minority objections, uncertainty, and unresolved risks should remain visible in `ASSUMPTIONS.md` or `agent_reports/`.
5. Provenance travels with artifacts. Outputs should identify their inputs, method, owner, date, and review status.
6. Drafts stay draft until reviewed. No role should treat a generated memo, model result, figure, or synthesis as approved without the required review gate.
7. Human review is a boundary, not a formality. Actions listed in `HUMAN_REVIEW.md` require explicit approval; silence is not approval.
8. The smallest useful question wins. Agents should avoid interrupting the PI with low-value questions and should explain what decision is blocked.
9. Stream before downloading. Data workflows should prefer GDAL-native streaming, lazy reads, and standards-based access when feasible; bulk downloads need a documented reason and human approval when large.

## Collaboration rhythm

- Start each phase by naming the active question, expected output, owner, and review gate.
- Record major choices in `DECISIONS.md`.
- Record assumptions and cautions in `ASSUMPTIONS.md`.
- Put role-specific memos, objections, handoffs, and review notes in `agent_reports/`.
- Keep project-facing documentation synchronized with the current charter and roadmap.

## Conflict handling

When agents disagree, the group should first identify whether the conflict is about evidence, interpretation, values, scope, or governance. Evidence conflicts go to source review. Interpretation conflicts go to Scientific Director review and, when consequential, Skeptic review. Values, community, policy, sovereignty, or public-facing conflicts require human review before promotion.

## Reproducibility expectations

Every substantive artifact should answer:

- What input did this use?
- What process or script produced it?
- Who owns it?
- What is its review status?
- What assumptions could change the conclusion?
- What downstream decision should it inform?
