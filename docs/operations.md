# Operations Guide

This page documents the reproducible operating path for the Hermes/Hermes scientific working group container with Slack Socket Mode and ChatGPT/Codex OAuth.

The working deployment has four separate gates:

1. Docker starts the Hermes Gateway.
2. Slack Socket Mode connects to the Gateway.
3. The Slack user is paired and approved.
4. The Gateway has a fresh model login for `openai-codex`.

Treat these as separate checks. A failure in one layer can look like a silent Slack failure from the user's perspective.

## Start the Gateway

Create a local `.env` from `.env.example`, add Slack tokens, and validate them:

```bash
cp .env.example .env
scripts/check-secrets.sh
```

Start the long-running Gateway container:

```bash
scripts/start-gateway.sh
```

The script prints a Docker container id. Keep that id for diagnostics. You can also rediscover it:

```bash
docker ps --filter name=openclaw
```

For multi-instance local work, keep the service boundaries strict. The Hermes Gateway is the only service that owns Hermes state and sessions. The workspace CMS and JupyterLab services share `/workspace` for files and outputs, but they use lightweight service entrypoints and must not register Slack channels, rewrite Hermes config, or run Gateway startup.

## Open The Main Browser UI

Use the Gateway URL for chat, not the CMS URL. In the default local stack:

```text
http://127.0.0.1:18789/      main Hermes chat and control UI
http://127.0.0.1:8090/       workspace CMS, files, and GitHub manager
http://127.0.0.1:8888/lab    JupyterLab
```

The reproducible local path is to open the tokenized dashboard URL from the running Gateway container:

```bash
docker exec <container-id> openclaw dashboard --no-open
```

Open the printed URL directly in the browser you plan to use. This avoids landing on the unauthenticated chat page and then manually copying a token.

If the browser reports `Device pairing required`, approve that exact browser request from the same live Gateway container:

```bash
docker exec <container-id> openclaw devices list
docker exec <container-id> openclaw devices approve <REQUEST_ID>
```

Then reload the chat page or reopen the tokenized dashboard URL.

## Verify Slack

Probe Slack Socket Mode from inside the running container:

```bash
docker exec <container-id> openclaw channels status --channel slack --probe --timeout 20000
```

A healthy Slack connection should report that the Slack provider is enabled, configured, running, connected, and healthy.

## Pair a Slack User

The first time a Slack user talks to the app, Hermes may reply with "access not configured" and a pairing code.

Approve that user inside the running Gateway container:

```bash
docker exec -it <container-id> openclaw pairing approve slack <PAIRING_CODE>
```

This approval is stored in the persisted Hermes config mount under `~/.openclaw` on the host and `/data/.openclaw` in the container. Pair each human operator explicitly. Do not approve unknown users or broad groups without review.

## Refresh Codex OAuth in the Live Gateway

For Slack replies, re-authenticate in the same running Gateway container that Slack is using:

```bash
docker exec -it <container-id> openclaw models auth login --provider openai-codex --set-default
```

Open the OAuth URL in your local browser. After sign-in, paste the full `localhost:1455/auth/callback?...` redirect URL back into the terminal prompt.

Then verify model auth:

```bash
docker exec <container-id> openclaw models status
```

Healthy Codex OAuth status should show the `openai-codex` profile and may show usage/quota information. If status only says the profile expires later but agent calls still return `token_expired`, rerun the login inside the live Gateway container.

## Smoke Test the Agent

Before testing Slack, run a direct agent reply check:

```bash
docker exec <container-id> openclaw agent --session-id slack-ready-check-$(date +%s) --message 'Reply with exactly: PI Liaison ready' --timeout 120
```

Expected output:

```text
PI Liaison ready
```

Then test in Slack:

```text
@Science_advisory_team hi
```

## Common Failure Modes

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Browser opens `http://127.0.0.1:8090/` but no chat is visible | The CMS sidecar opened instead of the main Gateway UI | Open `http://127.0.0.1:18789/` or use `openclaw dashboard --no-open` from the live container |
| Browser reaches `http://127.0.0.1:18789/` but shows `Auth required` | The Gateway is up, but the browser is using an un-tokenized URL | Use the token-bearing URL from `openclaw dashboard --no-open` |
| Browser accepts the token but shows `Device pairing required` | The local browser has not been approved for Control UI access yet | Run `openclaw devices list`, then `openclaw devices approve <REQUEST_ID>` inside the live Gateway container |
| Slack says `access not configured` | Slack user is not paired | Run `openclaw pairing approve slack <PAIRING_CODE>` inside the Gateway container |
| Slack provider is not connected | Socket Mode token, bot token, channel, or Slack app setup is wrong | Run `scripts/check-secrets.sh`, check Socket Mode, app-level token, bot membership, and event subscriptions |
| Slack replies with `Model login expired` | Gateway cannot refresh Codex OAuth | Run `openclaw models auth login --provider openai-codex --set-default` inside the live Gateway container |
| Direct agent test fails with `token_expired` | OAuth metadata exists but backend refresh is rejected | Re-auth in the live Gateway container; restart Gateway only after confirming the profile works |
| Direct messages show "Sending messages to this app has been turned off" | Slack App Home messages are disabled | Enable the App Home Messages tab and reinstall the Slack app |
| Approval button does not respond or CLI says `scope upgrade pending approval` | The local operator device needs a scope upgrade, or background cron jobs are locking the same session | Run `openclaw devices list`, approve the pending local device with `openclaw devices approve <REQUEST_ID>`, then pause noisy cron jobs with `openclaw cron disable <JOB_ID>` |
| Agent replies stall while cron jobs keep spawning subagents | A recurring improvement/review loop is overloading the Gateway or sharing a locked session | Run `openclaw cron list`, disable the loop, and check `openclaw tasks list --status running --json` before restarting work |
| New instance opens but the agent dropdown is missing | The instance has only the default `main` agent registered | Run `openclaw agents list`; restore the 11-agent registry without copying another instance's token, port, sessions, or workspace |
| Agent fails with `session file changed while embedded prompt lock was released` | Browser, CLI, heartbeat, or a background task touched the same active transcript | Stop using that transcript, inspect `openclaw tasks list --json` and `openclaw sessions --agent main --json`, archive the failed session, then start a fresh browser session |

## Recover a Stuck Approval Flow

If the Control UI approval button appears to do nothing, first check whether the Gateway is waiting on a device scope upgrade:

```bash
docker exec <container-id> openclaw devices list
```

If a pending request is shown for your local operator device, approve that exact request:

```bash
docker exec <container-id> openclaw devices approve <REQUEST_ID>
```

Then inspect and pause noisy cron jobs before retrying the UI:

```bash
docker exec <container-id> openclaw cron list
docker exec <container-id> openclaw cron disable <JOB_ID>
docker exec <container-id> openclaw tasks list --status running --json
```

Use recurring jobs conservatively. Continuous-improvement loops should be opt-in and slow enough that one run finishes before the next begins.

## Recover a Multi-Instance Gateway

When running several Hermes gateways at once, treat each instance as a separate appliance. Validate the instance with:

```bash
docker exec <gateway-container> openclaw --version
docker exec <gateway-container> openclaw status
docker exec <gateway-container> openclaw agents list
docker exec <gateway-container> openclaw sessions --agent main --json
```

The agent list should show 11 agents. If only `main` appears, repair the agent registry before using the browser. If a session-lock error appears, archive the failed session rather than deleting the instance. See the [multi-instance runbook](instance-runbook.md) before copying state or updating Hermes.

## Scaling Notes

Use one narrowly mounted `workspace/` per scientific working group or project. Avoid mounting the user's whole home directory. The source scaffold lives in `docker/seed-workspace`; runtime notes and project files live in the mounted `workspace/`, while durable runtime state and optional outputs live under `/data`.

For multiple Slack channels, prefer explicit channel ids in `.env` or deployment-specific environment files. Use a stable value such as `channel:C0123456789` when supported, because channel names can change.

For multiple users, approve each Slack sender intentionally and document who is allowed to operate the Liaison. Slack should remain the PI Liaison interface, not a direct execution surface for every agent.

For multiple deployments, keep secrets out of images and git. Build the same image, provide different `.env` files or deployment secrets, and keep each deployment's `~/.openclaw` state separate.

For long-running use, expect occasional OAuth refresh. The reproducible recovery path is live-container re-auth, Slack health probe, model status, direct agent smoke test, then Slack test.
