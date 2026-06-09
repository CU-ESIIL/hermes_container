# Slack Integration

Slack is an optional PI Liaison surface. It should not become a direct command channel for execution agents.

## Why Slack Is Narrow

Slack is useful for intake, reminders, questions, and review notifications. It is risky if messages can directly trigger shell commands, publication, deletion, or broad agent activity. Hermes therefore treats Slack as a conversation channel for the PI Liaison and a queue into workspace memory.

## Required Local Variables

Set these in `.env`:

```text
SLACK_BOT_TOKEN=xoxb-your-token
SLACK_APP_TOKEN=xapp-your-token
SLACK_DEFAULT_CHANNEL=#science-working-group
```

Run:

```bash
scripts/check-secrets.sh
```

The checker masks token previews and refuses placeholder or malformed Slack tokens.

## Safe Use

Invite the bot to the intended channel. Enable Socket Mode and the relevant Slack app event subscriptions. If the app is reinstalled, rotate and update tokens. Never paste tokens into chat, docs, screenshots, issues, or prompt logs.
