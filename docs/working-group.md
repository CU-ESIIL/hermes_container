# Scientific Working Group

A good scientific agent system is not ten chatbots. It is a small institution with roles, memory, evidence standards, disagreement, and human review.

The working group scaffold in this repository creates a reproducible environmental data science workspace under `/workspace` inside the Hermes container. It is intended for synthesis work where claims need provenance, figures need traceability, and autonomous capabilities need clear boundaries. The scaffold does not make autonomy safe by itself; it creates a better operating structure for human-supervised work.

The core files are simple Markdown registers. `MEMORY.md` holds durable institutional memory. `ROADMAP.md` organizes work from project charter through release package. `ASSUMPTIONS.md` records assumptions and their risks. `DECISIONS.md` records major decisions. `HUMAN_REVIEW.md` defines actions that require explicit human approval.

`MODEL_ASSIGNMENTS.md` records which model route each role should use. The PI Liaison and Scientific Director should stay on the most reliable approved route, while open-model API endpoints can be evaluated for bounded specialist tasks before they become defaults.

The seed also includes reusable governance templates: team norms, decision protocol, memory quarantine protocol, artifact registry, societal impact checklist, role reproducibility notes, and a meeting template. These make the container reproducible without requiring every new deployment to recreate working-group norms from scratch.

Analyses belong in `analysis/` and reproducible utilities belong in `scripts/`. Figures belong in `figures/`, with enough provenance to trace them back to scripts and data sources. Literature, citation notes, and evidence tables belong in `literature/`. Daily working memory belongs in `daily_notes/`, while role-specific memos and skeptic reviews belong in `agent_reports/`.

The design is intentionally bounded. Each role has expected inputs, expected outputs, and limits. Third-party skills, broad filesystem mounts, autonomous shell access, external APIs, and credentials should be treated as high-trust capabilities. Human review is required before publication, destructive file operations, new mounts, new skills, external messages, expensive jobs, billed APIs, or sensitive claims.

## PI Liaison Gateway

The user should not have to manage ten agents. The PI Liaison turns a multi-agent scientific working group into a single coherent conversation.

The PI Liaison / User Interview Agent is the default human-facing role. It greets the user, asks the project-start questions in `PROJECT_INTAKE.md`, records preferences and constraints in `USER_CONTEXT.md`, drafts `PROJECT_CHARTER.md`, and writes `TEAM_BRIEF.md` for the scientific team. The rest of the working group communicates through that brief and through task assignments rather than competing for the user's attention.

When other agents need user input, they write questions in `QUESTIONS_FOR_USER.md`. The PI Liaison deduplicates the queue, merges related questions, and asks only the highest-value followups. The same role returns milestone summaries, draft reports, and release packets to the user for review. It does not invent scientific goals or approve publication, deletion, GitHub pushes, external API use, or sensitive claims.

For Slack-connected use, the Liaison is the only Slack-facing component. Slack messages should enter queues and workspace memory before they are routed to the team. Slack must never directly trigger arbitrary shell execution, and Slack tokens must stay in local environment variables rather than markdown, logs, screenshots, prompts, or git.

Operationally, Slack use has a few distinct gates: Socket Mode must be healthy, the Slack sender must be paired, and the running Gateway must have a fresh model login. Keep those checks separate when diagnosing failures. The reproducible command sequence is documented in the [Operations guide](operations.md).

## Role Summary

| Role | Primary purpose | Main outputs |
| --- | --- | --- |
| PI Liaison / User Interview Agent | Serve as the human-facing gateway and coordinate the team through structured briefs. | Project intake, `PROJECT_CHARTER.md`, `TEAM_BRIEF.md`, user question batches |
| Scientific Director | Maintain scientific coherence, scope, and standards. | Charter updates, phase decisions, scope notes |
| Deputy Director / Integrator | Integrate parallel work into coherent artifacts. | Integration memos, dependency lists, artifact inventories |
| Data Engineer / Infrastructure Scientist | Make data access and infrastructure reproducible. | Data inventories, provenance notes, script documentation |
| Quantitative Modeler | Design and explain quantitative analysis with uncertainty. | Analysis plans, model scripts, diagnostics |
| Domain Scientist | Ground interpretation in environmental science context. | Mechanism notes, confounder checklists, domain interpretation |
| Scientific Narrative Lead | Turn reviewed evidence into a clear scientific argument. | Outlines, claim-evidence maps, draft synthesis sections |
| Technical Communicator | Keep technical artifacts readable and navigable. | READMEs, walkthroughs, internal documentation |
| Citation & Evidence Curator | Maintain citation traceability and evidence quality. | Citation inventories, evidence audits, license notes |
| Skeptic / Adversarial Reviewer | Stress-test claims, assumptions, and methods. | Skeptic review memos, objection lists, revision requirements |
| Societal Impact / Translation Agent | Translate reviewed findings responsibly for audiences. | Impact memos, audience maps, misuse and risk notes |

## Working Pattern

Start with a project charter. Identify the research question, theory of change, candidate data sources, expected outputs, and review gates. Put the charter in `documents/` and record any early assumptions in `ASSUMPTIONS.md`.

Move through the phases in `ROADMAP.md`. The phases are not a promise that the work is complete or correct; they are a checklist for what should exist before claims become stronger. A claim should not move from exploratory notes into a report or public artifact until it has evidence, citation review, skeptic review, and human review when required.

Use disagreement deliberately. The Skeptic role is not a blocker by default; it is a structured way to find weak evidence, hidden assumptions, and alternative explanations before they harden into project conclusions.

Use impact translation carefully. Societal relevance is not automatic just because a result is technically interesting. Claims about communities, Tribes, Indigenous knowledge, public health, law, or policy require human review and, when appropriate, additional domain or community review.
