# Gateway 3 Handoff

Last updated: 2026-05-22 16:55 MDT

This note captures the current state of gateway 3 after the rebuild and the remaining work for the next session.

## Current Goal

Build a robust, reproducible Hermes/Hermes container with:

- branded Hermes Control UI
- reliable PI Liaison chat
- browsable project file structure and outputs
- GitHub repository read/write workflow for authorized project repositories
- scalable credential injection through environment variables, secret files, and eventually GitHub Secrets

## What Was Wrong

Gateway 3 had accumulated too many moving parts at once. The most important finding was that the workspace CMS and Jupyter services were using the full Hermes gateway entrypoint. That meant non-gateway services could run workspace seeding, branding installation, GitHub/Slack setup, and Hermes bootstrap logic even though only the Gateway should own Hermes runtime state.

Separately, the active browser transcript `agent:main:gateway3-fixed` was poisoned by repeated Verde `reasoning-only assistant turn` failures. Fresh direct CLI sessions worked, but the browser kept reusing that bad transcript.

The update banner was not the main problem. It was an upstream Hermes package notice for `2026.5.20`; the local Docker dashboard update path cannot complete the managed-service handoff. The banner was suppressed in the Hermes branding layer, but the real stabilization was the container/service split and version pin.

## Changes Made

- Pinned the Docker image to Hermes `2026.5.18` with `ARG OPENCLAW_VERSION=2026.5.18` in `Dockerfile`.
- Added `docker/service-entrypoint.sh` for non-gateway services.
- Updated `docker-compose.yml` so:
  - `openclaw-local` uses the full Hermes gateway entrypoint and owns Hermes state.
  - `workspace-cms` uses the lightweight service entrypoint and only serves files/GitHub manager.
  - `workspace-ui` bypasses the Hermes entrypoint and runs JupyterLab directly.
- Rebuilt `openclaw-local`.
- Restarted gateway 3 on port `18791`, workspace UI on `8890`, CMS on `8092`.
- Reapplied Hermes branding and suppressed unsupported updater notices.
- Moved the browser to a fresh dashboard session.
- Removed the active `agent:main:gateway3-fixed` registry key and archived its session files under:

```text
/private/tmp/hermes-project-three-openclaw/agents/main/sessions/archived-20260522-pinned-rebuild/
```

## Current Live Links

```text
Gateway 3 chat:
http://127.0.0.1:18791/chat?session=agent%3Amain%3Adashboard%3A53fdac2b-ddd7-4eed-860c-ea527110ff03

Workspace UI:
http://127.0.0.1:8890/lab?token=hermes

Workspace CMS:
http://127.0.0.1:8092

Files:
http://127.0.0.1:8092/files?path=/workspace

GitHub manager:
http://127.0.0.1:8092/github
```

## Current Validation

Passing checks:

```bash
bash -n docker/entrypoint.sh docker/service-entrypoint.sh scripts/start-instance.sh scripts/install-control-ui-branding.sh
docker compose config --quiet
git diff --check
docker exec hermes-project-three-openclaw-local-run-96075a70e8ae openclaw --version
docker exec hermes-project-three-openclaw-local-run-96075a70e8ae openclaw agents list
docker exec hermes-project-three-openclaw-local-run-96075a70e8ae openclaw agent --agent main --session-id gateway3-pinned-smoke-20260522 --model verde/js2/gpt-oss-120b --message 'Reply with exactly: PINNED_OK' --timeout 120 --json
curl -fsS 'http://127.0.0.1:8092/api/file/list?path=/workspace'
curl -fsS 'http://127.0.0.1:8092/api/github/status'
```

Observed results:

- Hermes version is `2026.5.18`.
- 11 Hermes agents are present.
- Direct PI Liaison smoke test returned `PINNED_OK`.
- CMS file API returns the shared `/workspace` listing.
- CMS GitHub status endpoint works, but reports unauthenticated without a token.
- Heartbeats are disabled on gateway 3.
- CLI status still reports an available upstream update to `2026.5.20`; this is expected and should not be handled through the dashboard.

Follow-up diagnostics after the browser still struggled:

- `openclaw health` reports the Gateway event loop as OK.
- The Control UI repeatedly receives successful `commands.list` responses, so the slash-command catalog is loading.
- `openclaw approvals get` works, but this Hermes version does not support `openclaw approvals list --json`; there is no pending approval queue visible through `approvals get`.
- The `/approve` failure shown in the browser is probably a stale or malformed assistant instruction. Bare `/approve` is not enough; approval flows need the pending approval id and a valid decision.
- Recent browser chat failures are still dominated by `reasoning-only assistant turn detected` and `incomplete terminal response` from `verde/js2/gpt-oss-120b`.
- Gateway logs also show an intermittent `paired.json` read race during browser reconnects, but reconnects recover and `commands.list` succeeds afterward.

Conclusion: do not do a full Hermes state reset as the next step. A gateway restart may clear transient reconnect/device-file races, but it will not fix the core browser-chat issue. The next durable fix should focus on model routing/re-auth for PI Liaison and a clearer non-chat GitHub/CMS workflow for repository actions.

Gateway 1 and gateway 2 comparison:

- Gateway 2 is the better Verde-only reference. It uses Hermes `2026.5.18`, default model `verde/js2/gpt-oss-120b`, no OAuth profiles, `groupChat.visibleReplies = message_tool`, no `tools.byProvider` Verde deny block, and the default 30-minute PI Liaison heartbeat.
- Gateway 1 is not a pure Verde reference because its gateway process started with `agent model: codex/gpt-5.5`, even though many working-group runs used Verde.
- Gateway 3 was adjusted to match gateway 2's Verde-only profile:
  - default model remains `verde/js2/gpt-oss-120b`
  - `messages.visibleReplies` and `messages.groupChat.visibleReplies` are `message_tool`
  - generated Verde `tools.byProvider` restrictions were removed
  - the main agent heartbeat override was removed, restoring `Heartbeat interval: 30m (main)`
- The corrected `docker/entrypoint.sh` was copied into the live gateway 3 container at `/usr/local/bin/openclaw-container-entrypoint`, then gateway 3 was restarted to confirm the settings persist across restart.
- Final direct smoke test passed:

```bash
docker exec hermes-project-three-openclaw-local-run-96075a70e8ae openclaw agent --agent main --session-id gateway3-verde-persistent-20260522 --model verde/js2/gpt-oss-120b --message 'Reply with exactly: VERDE_PERSISTENT_OK' --timeout 120 --json
```

Result payload: `VERDE_PERSISTENT_OK`.

Approval UX follow-up:

- Browser chat is now responding, but bare `/approve` is still not the right workflow.
- The browser device has `operator.approvals` scope.
- The native approval queue is reachable with:

```bash
docker exec hermes-project-three-openclaw-local-run-96075a70e8ae openclaw gateway call exec.approval.list --json --params '{}'
```

- It returns `[]` unless a real approval request is pending.
- Gateway 3 was switched to Hermes's cautious exec policy so future exec requests outside the allowlist should create native approval requests for the UI instead of relying on chat text:

```bash
docker exec hermes-project-three-openclaw-local-run-96075a70e8ae openclaw exec-policy preset cautious --json
```

- The effective policy is now `security=allowlist`, `ask=on-miss`, `askFallback=deny`.
- Workspace instructions now tell agents to use the Hermes approval UI or CMS/GitHub manager buttons and not ask the user to type bare `/approve`.

## Remaining Work

1. Verify browser chat manually in the fresh session.
2. Verify the next real shell or GitHub action presents an approval button in the Control UI or CMS/GitHub manager rather than asking for `/approve`.
3. Keep PI Liaison and specialist roles on Verde for now. If browser chat still fails, compare browser session transcript/state before changing models.
4. Authenticate GitHub for the CMS/GitHub manager:

```bash
docker exec -it hermes-project-three-workspace-cms-1 gh auth login
docker exec hermes-project-three-workspace-cms-1 gh auth setup-git
```

or provide a fine-grained token through `GITHUB_TOKEN`, `GH_TOKEN`, or mounted `_FILE` variables.

5. Test the GitHub manager end to end:
   - authorize `CU-ESIIL/WUI_boundary`
   - clone or fetch
   - create an agent branch
   - edit a safe file in `/workspace/repos/...`
   - commit
   - push
   - open a PR

6. Decide the scalable GitHub Secrets workflow:
   - GitHub Actions self-hosted runner
   - Codespaces/devcontainer
   - Docker host pulling secrets from Actions into local secret files
   - Kubernetes/other orchestrator

7. Add an automated instance validator script, probably `scripts/validate-instance.sh`, covering:
   - version
   - gateway reachability
   - 11-agent registry
   - heartbeat state
   - direct smoke test on a fresh session id
   - CMS file API
   - GitHub manager status

8. Consider adding a safe session archive helper instead of manually editing `sessions.json`.

## Cautions

- Do not reuse `gateway3-fixed`; that session was the bad browser transcript.
- Do not click the dashboard update button for local Docker gateways.
- Do not allow CMS or Jupyter services to mount or mutate Hermes state.
- Do not rely on bare `/approve`; approval commands need the exact pending approval id and decision.
- Do not print tokens, OAuth callback codes, Slack tokens, GitHub tokens, or model API keys in docs or logs.
- Treat `openclaw@2026.5.18` plus the gateway 2-style Verde profile as the current known-good local baseline until a newer version passes browser chat validation.
