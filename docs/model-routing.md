# Model Routing

A scientific working group does not need every role to use the same model route. In this container, the PI Liaison and Scientific Director should stay on the most reliable human-facing route available, while narrower specialist agents can be evaluated against open-model APIs.

The practical pattern is conservative: keep the user-facing and decision-setting roles on OpenAI/Codex OAuth or another approved high-reliability route, then experiment with hosted open models for bounded work such as data inventories, literature triage, first-pass technical drafts, and skeptic checklists. This follows the same bounded-role idea used throughout the working group: agents get specific jobs, expected outputs, and explicit limits.

The workspace seed includes `/workspace/MODEL_ASSIGNMENTS.md` as the role-level routing register. Update that file when a role changes model route, and record meaningful changes or reversions in `/workspace/DECISIONS.md`.

## Suggested Defaults

| Role group | Recommended route | Why |
| --- | --- | --- |
| PI Liaison / User Interview Agent | OpenAI/Codex OAuth or another approved high-reliability route | This role talks to the user, manages Slack intake, and batches decisions. |
| Scientific Director | OpenAI/Codex OAuth or another approved high-reliability route | This role sets scientific direction and decides when claims can advance. |
| Deputy Director / Integrator | High-reliability route first, open-model experiments after evaluation | This role maintains coherence across the team. |
| Data, modeling, citation, communication, and skeptic roles | Approved open-model API route allowed for bounded tasks | These roles can be tested with narrower prompts and reviewable outputs. |
| Societal Impact / Translation Agent | High-reliability route preferred | Sensitive claims about communities, policy, public health, legal rules, or sovereignty require careful review. |

## Verde-Style API Experiments

For Verde/CyVerse experiments, use the OpenAI-compatible base URL `https://llm-api.cyverse.ai/v1` and keep credentials local in `.env`. The [AI-VERDE API documentation](https://aiverde-docs.cyverse.ai/api/) explains that keys are obtained from the AI-VERDE course or team details and that available models can be listed from the API. Do not commit keys, paste them into chats, or store them in markdown:

```dotenv
VERDE_LLM_BASE_URL=https://llm-api.cyverse.ai/v1
VERDE_LLM_API_KEY=
VERDE_LLM_DEFAULT_MODEL=js2/gpt-oss-120b
VERDE_LLM_PROVIDER_NAME=verde
```

After setting a local key, inspect the models your team can access:

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

The container startup writes Hermes' local `config.yaml` with `provider: custom`, `base_url: https://llm-api.cyverse.ai/v1`, and `default: js2/gpt-oss-120b` unless `HERMES_CONFIGURE_MODEL=0` is set or an existing config is preserved. A real `VERDE_LLM_API_KEY`, `AI_VERDE_API_KEY`, or `OPENAI_API_KEY` is still required before inference will succeed.

## Evaluation Workflow

1. Pick one bounded role and one bounded task.
2. Run the task with the current reliable route.
3. Run the same task with the open-model candidate.
4. Compare evidence handling, citation behavior, role compliance, and uncertainty language.
5. Record the result in `/workspace/agent_reports/model_evaluations.md` or `/workspace/DECISIONS.md`.
6. Promote the route only after human approval when the role is user-facing, Slack-facing, director-level, or involved in sensitive claims.

## Scaling Pattern

The scalable unit is not "one key per agent." The scalable unit is a reviewed route assignment: role, provider, model, allowed task types, blocked actions, evaluation date, and fallback. That keeps the system reproducible as users add local keys, hosted endpoints, or future Hermes provider integrations.
