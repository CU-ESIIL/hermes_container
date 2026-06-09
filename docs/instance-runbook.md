# Multi-Instance Runbook

This runbook captures the lessons from bringing up the second and third local Hermes gateways. Use it whenever you spawn another working group instance from the same repository.

The central lesson is simple: a new instance is not healthy just because the browser opens. Validate the Hermes state, the agent registry, the session store, the model route, and the auxiliary UI ports before doing project work.

## Expected Instance Shape

A healthy OASIS Hermes instance has four separate parts:

| Layer | What to check | Why it matters |
| --- | --- | --- |
| Gateway | Hermes Control UI port, token auth, allowed browser origins | The chat UI can load but still fail to connect if the origin or token state is wrong. |
| Agent registry | 11 configured agents, with `main` named PI Liaison | If only `main` exists, the agent dropdown disappears and the working group was not seeded correctly. |
| Workspace services | JupyterLab and CMS ports | Files, outputs, GitHub manager, and review tools live outside the Gateway process. |
| Persistent state | `instances/<name>/openclaw`, `workspace`, `data`, and `external_storage` | These folders distinguish one working group from another and keep project work from mixing. |

Only the Gateway service should boot Hermes and mount the Hermes state directory. Workspace services should be boring: JupyterLab serves notebooks, and the CMS serves files plus GitHub repository management from the shared workspace. They should not seed the working group, register Slack channels, rewrite Hermes config, or touch Gateway sessions.

## Start a New Instance

Use a unique name and unique ports:

```bash
scripts/start-instance.sh project-two 18790 8889 8091
scripts/start-instance.sh project-three 18791 8890 8092
```

Do not reuse a gateway port, JupyterLab port, CMS port, or instance name while the previous instance is still running.

The helper writes state under:

```text
instances/<instance-name>/
  openclaw/
  workspace/
  data/
  external_storage/
```

These folders are intentionally ignored by git. They are runtime state, not template source.

If `secrets/github_token` exists, or `HERMES_GITHUB_TOKEN_FILE` points at a token file, the helper also applies the Docker secrets overlay so the Gateway and CMS receive GitHub credentials. This keeps spawned instances aligned with the base compose setup instead of requiring a hand-edited `.env` for each gateway.

For gateway 3, the explicit authenticated launch is:

```bash
mkdir -p secrets
printf '%s\n' 'PASTE_YOUR_FINE_GRAINED_TOKEN_HERE' > secrets/github_token
chmod 600 secrets/github_token

HERMES_GITHUB_TOKEN_FILE=./secrets/github_token \
HERMES_USE_SECRETS_OVERLAY=1 \
scripts/start-instance.sh project-three 18791 8890 8092
```

After startup, use **GitHub Auth** in the sidebar and click **Configure git credentials**. The sidebar, CMS GitHub manager, and agents share the same `/workspace/.openclaw-github/authorized-repos.yaml` allowlist and `/workspace/repos/` clone directory.

## Immediate Validation

After the helper prints URLs, run these checks before sending prompts to the agent.

```bash
docker ps --filter name=hermes
docker exec <gateway-container> openclaw --version
docker exec <gateway-container> openclaw status
docker exec <gateway-container> openclaw agents list
docker exec <gateway-container> openclaw sessions --agent main --json
```

Expected results:

- `openclaw agents list` shows 11 agents.
- `main` is named `PI Liaison`.
- Specialist agents such as `scientific-director`, `data-engineer`, `skeptic`, and `societal-impact-translation` are present.
- The default model is the expected route, usually `verde/js2/gpt-oss-120b` for open-model testing.
- `openclaw status` reports the intended gateway port for that instance.

If the agent list only shows `main`, stop and repair the instance configuration before using the UI. A browser refresh will not fix a missing agent registry.

## Safe Agent Smoke Test

Do not use the browser's active `agent:main:main` session for CLI smoke tests. That can collide with the web UI and produce session-lock errors.

Use a dedicated smoke-test session id:

```bash
docker exec <gateway-container> openclaw agent \
  --agent main \
  --session-id instance-smoke-$(date +%s) \
  --message 'Reply with exactly: OK' \
  --timeout 120
```

Expected output:

```text
OK
```

If the smoke test works but the browser does not, the problem is usually the browser session, token, origin, or stale frontend cache rather than the model route.

## Browser Checks

Open the Gateway URL printed by the helper. For an external browser, use the exact local origin:

```text
http://127.0.0.1:<gateway-port>/
```

If the browser reports `Browser origin not allowed`, check `gateway.controlUi.allowedOrigins` in that instance's Hermes config and restart the Gateway.

If the browser reports `Auth required`, use the token-bearing URL from:

```bash
docker exec <gateway-container> openclaw dashboard --no-open
```

If the Control UI loads but the chat does not respond, click **New session** once. If the same transcript continues to fail, inspect and archive the failed session rather than repeatedly sending prompts into it.

## Recover a Session-Lock Failure

The repeated error:

```text
session file changed while embedded prompt lock was released
```

means the current session transcript changed while Hermes expected exclusive access. In practice this can happen when a web session, CLI smoke test, heartbeat, or background task touches the same `agent:main:main` transcript.

First inspect, do not delete:

```bash
docker exec <gateway-container> openclaw tasks list --json
docker exec <gateway-container> openclaw sessions --agent main --json
docker logs --tail 120 <gateway-container>
```

If the failed key is `agent:main:main`, stop the Gateway and archive that one transcript out of the active registry. Keep the archived files for later inspection. Do not wipe the whole Hermes state directory.

The principle is:

- archive the failed transcript
- keep the workspace
- keep the agent registry
- restart the Gateway
- create a fresh browser session

## Repair a Missing Agent Registry

If a new instance has only one agent, compare it with a known-good instance:

```bash
docker exec <good-gateway> openclaw agents list
docker exec <new-gateway> openclaw agents list
```

The fix is to restore the `agents.list` and related agent defaults in the new instance's `openclaw.json`. Preserve the new instance's gateway token, port, allowed origins, sessions, and local workspace paths. Do not copy a whole known-good Hermes state directory over another instance; that can mix ports, tokens, sessions, and project memory.

Keep Hermes runtime state on local disk rather than in a cloud-synced repository folder. Session files are lock-sensitive, and cloud sync metadata updates can make Hermes think another writer changed the transcript. `scripts/start-instance.sh` defaults to `/private/tmp/hermes-<instance>-openclaw` on macOS, `$RUNNER_TEMP/hermes-<instance>-openclaw` on GitHub Actions runners, and `/tmp/hermes-<instance>-openclaw` on other Linux hosts; the project workspace remains under `instances/<name>/workspace`.

## Update Policy

An update banner means a newer Hermes package exists. It does not by itself diagnose the problem.

For local Docker Hermes gateways, do not use the in-browser **Update now** button as the upgrade path. The local container cannot complete the managed-service update handoff, so the Hermes branding layer suppresses that unsupported banner. Treat Hermes upgrades as image/package changes: update one target gateway, restart it, then rerun the validation checks below.

For a new instance:

1. Record the current version with `openclaw --version`.
2. Run the non-destructive checks above.
3. If updating, update only the target instance first.
4. Restart and rerun `openclaw agents list`, `openclaw status`, and the dedicated smoke test.
5. Do not update every running gateway at once.

If an update changes behavior, keep the old instance running until the new one is validated.

### Known-Good Version Note

During the May 2026 multi-instance bring-up, gateway 2 remained stable on Hermes `2026.5.18` while gateway 3 began throwing repeated embedded session-lock errors after a live update to `2026.5.20`. The Verde model route still worked in isolated CLI smoke tests, but browser sessions failed with:

```text
session file changed while embedded prompt lock was released
```

For new local Hermes instances, treat `2026.5.18` as the current known-good Hermes baseline until `2026.5.20` or later is validated with a browser chat test. If an experimental instance has already been updated and starts failing this way, recover the instance by returning only that gateway to the known-good Hermes package, archiving the failed webchat session, and rerunning the dedicated smoke test. Do not update working gateways just because another instance shows an update banner.

The reusable image pins this baseline with `ARG OPENCLAW_VERSION=2026.5.18` in the Dockerfile. To test a newer Hermes version, build an experimental image with an explicit build argument and validate it on one noncritical instance before changing the default.

Also check `openclaw status` for heartbeat state. A default Hermes instance may enable a 30-minute heartbeat on `main` even when no heartbeat block appears in `openclaw.json`. In gateway 3, that heartbeat repeatedly touched `agent:main:main` and kept recreating the lock error. For local template instances, explicitly disable the PI Liaison heartbeat unless the project needs it:

```json
{
  "id": "main",
  "heartbeat": {
    "every": ""
  }
}
```

After patching, restart the gateway and confirm `openclaw status` reports `disabled (main)`.

If a fresh dedicated CLI smoke test still writes an assistant reply to the session file but exits with the same session-lock error, compare the failing instance's model and tool configuration with a known-good gateway. Gateway 3 became harder to diagnose after the template forced a special minimal tool-deny profile for Verde and used automatic visible replies. Gateway 1's more stable Verde runs did not include that extra `tools.byProvider` restriction and used `message_tool` visible replies.

The preferred local Verde profile is:

```json
{
  "models": {
    "mode": "merge"
  },
  "messages": {
    "visibleReplies": "message_tool",
    "groupChat": {
      "visibleReplies": "message_tool"
    }
  }
}
```

Only enable the minimal tool-deny profile intentionally with `OPENCLAW_VERDE_MINIMAL_TOOLS=1`, and record why in the project log.

After this repair, rerun the dedicated smoke test with a new session id. A passing direct test should return JSON with `"status": "ok"` and payload text `OK`.

### Reapply Hermes Branding After Live Updates

Hermes package updates replace the upstream Control UI asset directory. That can temporarily remove the OASIS Hermes header, project banner, Files link, and GitHub link even though the workspace services are still running.

After any live `openclaw update` inside a running gateway container, reapply the Hermes UI patch for that instance:

```bash
docker cp scripts/install-control-ui-branding.sh <gateway-container>:/tmp/install-control-ui-branding.sh
docker cp branding/control-ui <gateway-container>:/opt/hermes/branding/control-ui
docker cp docs/assets/brand/hermes.png <gateway-container>:/opt/hermes/branding/assets/hermes.png
docker exec <gateway-container> sh -lc 'HERMES_CMS_PORT=<cms-port> OPENCLAW_WORKSPACE=/workspace bash /tmp/install-control-ui-branding.sh'
docker restart <gateway-container>
```

The branding installer also reopens the Control UI content security policy for that instance's CMS origin. That is required for the embedded **Files** and **GitHub Auth** sidebar panels to fetch `/api/file/*` and `/api/github/*` from the CMS service.

Verify the update did not strip the Hermes sidebar features:

```bash
curl -sS -D - -o /tmp/hermes-index.html \
  http://127.0.0.1:<gateway-port>/ | grep -i content-security-policy

docker exec <gateway-container> sh -lc \
  'grep -q hermes-file-list /usr/local/lib/node_modules/openclaw/dist/control-ui/hermes-brand.js &&
   grep -q hermes-repo-form /usr/local/lib/node_modules/openclaw/dist/control-ui/hermes-brand.js'

curl -sS http://127.0.0.1:<cms-port>/api/file/list?path=/workspace
curl -sS http://127.0.0.1:<cms-port>/api/github/repos
```

The content security policy should include the CMS origin, for example `http://127.0.0.1:<cms-port>`. The JavaScript checks should pass, and the CMS endpoints should return JSON.

Then hard-refresh the browser. If the page still looks like default Hermes, clear the service worker/cache for that local port or open a fresh private window. The CMS routes should remain available at the instance CMS port, for example:

```text
http://127.0.0.1:<cms-port>/files?path=/workspace
http://127.0.0.1:<cms-port>/github
```

## What Not To Do

Do not:

- copy an entire live `instances/<name>/openclaw` directory over another instance
- run CLI smoke tests against the browser's active `agent:main:main` transcript
- keep sending prompts into a transcript that has already thrown a session-lock error
- assume a loaded UI means the agent registry is correct
- treat Files, GitHub, JupyterLab, and CMS as separate unrelated apps; they are companion services for the same instance
- update all gateways at once when only one instance is failing
- delete runtime state before checking whether project work or auth state is inside it

## What To Do Instead

Do:

- validate the agent count immediately after spawn
- use explicit, unique smoke-test session ids
- keep each instance on unique ports
- keep each instance in its own `instances/<name>/` folder
- archive broken sessions instead of deleting them
- preserve workspace and Hermes config separately
- document the exact Hermes version that worked for the instance
- use the CMS port printed by the instance helper for Files and GitHub manager links

The goal is for each working group to feel like a separate scientific appliance, not a tab in one shared, invisible runtime.
