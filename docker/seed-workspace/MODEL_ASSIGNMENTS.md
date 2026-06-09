# MODEL_ASSIGNMENTS.md - Role-Based Model Routing

This register documents which model route each working-group role should use by default and where open-model API experiments are allowed.

Do not store API keys, OAuth callback URLs, access tokens, refresh tokens, provider secrets, or billing credentials in this file. Keep credentials in the local `.env` file or in Hermes's local auth store.

## Default Policy

- Keep the PI Liaison / User Interview Agent on the most reliable human-facing route available.
- Keep the Scientific Director on a high-trust route unless the human PI approves a change.
- Use open-model API experiments first for bounded specialist work, such as data inventories, literature triage, first-pass skeptic questions, and internal memos.
- Do not change the default model for the PI Liaison, Scientific Director, or Slack-facing route without human approval.
- Record model changes, evaluation notes, failures, and reversions in `DECISIONS.md` or `agent_reports/model_evaluations.md`.
- Never use an unevaluated model route for publication approval, sensitive claims, irreversible filesystem actions, credential changes, or external messaging.

## Assignment Table

| Role | Default route | Open-model API experiments | Notes |
| --- | --- | --- | --- |
| PI Liaison / User Interview Agent | OpenAI/Codex OAuth or another approved high-reliability route | No, unless explicitly approved | Human-facing, Slack-facing, and responsible for question batching. |
| Scientific Director | OpenAI/Codex OAuth or another approved high-reliability route | No, unless explicitly approved | Responsible for scientific direction and claim promotion. |
| Deputy Director / Integrator | High-reliability route | Yes, for integration drafts after review | Must preserve coherence across roles. |
| Data Engineer / Infrastructure Scientist | Approved open-model API route allowed | Yes | Good candidate for bounded data inventory and reproducibility checks. |
| Quantitative Modeler | Approved open-model API route allowed | Yes | Use for scaffold review and diagnostics; human review for modeling decisions. |
| Domain Scientist | Approved open-model API route allowed | Yes | Must cite evidence and flag uncertainty. |
| Scientific Narrative Lead | Approved open-model API route allowed | Yes | Use for internal drafts, not final claims. |
| Technical Communicator | Approved open-model API route allowed | Yes | Good candidate for summaries and README-style drafts. |
| Citation & Evidence Curator | Approved open-model API route allowed | Yes | Must preserve citation provenance and avoid invented citations. |
| Skeptic / Adversarial Reviewer | Approved open-model API route allowed | Yes | Useful for second opinions; findings still need evidence checks. |
| Societal Impact / Translation Agent | High-reliability route preferred | Limited | Sensitive community, policy, public-health, legal, or sovereignty claims require human review. |

## Open-Model API Placeholders

For Verde/CyVerse experiments, use the OpenAI-compatible base URL `https://llm-api.cyverse.ai/v1` and put local credentials in `.env`. The AI-VERDE API documentation is at <https://aiverde-docs.cyverse.ai/api/>. Keep keys out of git:

```dotenv
VERDE_LLM_BASE_URL=https://llm-api.cyverse.ai/v1
VERDE_LLM_API_KEY=
VERDE_LLM_DEFAULT_MODEL=
VERDE_LLM_PROVIDER_NAME=verde
```

These variables are placeholders for local experiments. They do not by themselves register a provider in Hermes. When provider registration is automated, document the exact Hermes version, model IDs, and validation command.

After setting a local key, list available models:

```bash
curl -s -L "${VERDE_LLM_BASE_URL}/models" \
  -H "Authorization: Bearer ${VERDE_LLM_API_KEY}" \
  -H "Content-Type: application/json"
```

## Current AI-VERDE Candidate Models

The following model IDs were reported as available for the current API key context on 2026-05-18. Availability can vary by course, team, quota, and provider changes, so confirm with the `/models` endpoint before assigning a role:

| Model ID | Candidate use |
| --- | --- |
| `nrp/glm-4.7` | General specialist-agent evaluation |
| `nrp/glm-5` | General specialist-agent evaluation |
| `nrp/kimi` | Literature triage, summaries, and long-context checks |
| `nrp/gemma` | Lightweight drafts and comparison tests |
| `nrp/qwen3` | General specialist-agent evaluation |
| `nrp/qwen3-small` | Fast, low-risk smoke tests and simple routing checks |
| `nrp/minimax-m2` | General specialist-agent evaluation |
| `nrp/gpt-oss` | Open-model comparison tests |
| `Meta-Llama-3.1-70B-Instruct-quantized` | Larger-model baseline comparisons |
| `llama-3.3-70b-instruct-quantized` | Larger-model baseline comparisons |
| `phi-4` | Lightweight technical drafts and checks |
| `Llama-3.3-70B-Instruct-quantized` | Larger-model baseline comparisons |
| `phi-4-multimodal-instruct` | Multimodal experiments only when inputs and privacy are reviewed |
| `gemma-3-12b-it` | Lightweight drafts and comparison tests |
| `Llama-3.2-11B-Vision-Instruct` | Vision experiments only when images are appropriate to share |
| `esiil/GLM-4.7-Flash` | Fast ESIIL-context experiments and smoke tests |
| `js2/llama-4-scout` | Jetstream2-hosted model experiments |
| `js2/gpt-oss-120b` | Larger open-model comparison tests |

Do not treat this table as approval to use a model for sensitive claims or external actions. It is an inventory for bounded experiments.

## Evaluation Checklist

Before promoting a model route from experiment to default:

1. Run a bounded task with known expected behavior.
2. Check whether the model follows the role limits in `AGENTS.md`.
3. Check whether it preserves citations and avoids invented sources.
4. Check whether it asks for human review when required by `HUMAN_REVIEW.md`.
5. Compare outputs against the current high-reliability route.
6. Record the result in `agent_reports/model_evaluations.md` or `DECISIONS.md`.

## Failure Modes To Watch

- Inventing citations, datasets, approvals, or user preferences.
- Treating Slack as permission to execute arbitrary shell commands.
- Ignoring `QUESTIONS_FOR_USER.md` and interrupting the user directly.
- Making strong scientific, policy, community, legal, public-health, or sovereignty claims without review.
- Silently using external APIs that create cost, data-transfer, or licensing issues.
