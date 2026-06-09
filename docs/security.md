# Security

Slack credentials are high-value secrets. A bot token can allow an application to read or write through the bot account, depending on granted scopes. An app-level token can allow Socket Mode connectivity for the Slack app. Treat both as credentials that can expose private workspace content or let an attacker impersonate trusted automation.

## Slack token types

`SLACK_BOT_TOKEN` values usually begin with `xoxb-`. They identify the bot user and authorize bot actions permitted by the Slack app scopes.

`SLACK_APP_TOKEN` values usually begin with `xapp-`. They are app-level tokens commonly used for Socket Mode or app connectivity. They are not a substitute for least-privilege bot scopes.

Do not use the Slack signing secret or legacy verification token as `SLACK_APP_TOKEN`. The signing secret verifies HTTP requests when Slack sends events to a public endpoint. The legacy verification token is not the Socket Mode app-level token. For this container, create an app-level token under the Slack app's Basic Information page with the `connections:write` scope; the value should look like `xapp-1-APPID-INSTALLID-SECRET`.

Do not commit either token to git. Do not paste them into chat, markdown files, issue comments, screenshots, prompt logs, terminal transcripts, or documentation.

## Local environment files

Secrets belong in local environment variables because they can be injected at runtime without baking them into the Docker image or storing them in tracked files. This repo uses `.env` for local development and keeps `.env` ignored by git.

Start from the template:

```bash
cp .env.example .env
```

Edit `.env` locally and run:

```bash
scripts/check-secrets.sh
```

The checker validates that Slack variables are present and masks token previews in output. It should show only values like `xoxb-****abcd`, never full tokens.

## Rotation

Rotate Slack tokens whenever access changes, scopes change, a teammate leaves, an automation host is replaced, or there is any chance that a token appeared in git, screenshots, prompt logs, shell history, terminal output, or chat.

Use least-privilege scopes for the Slack app. Give the bot only the permissions needed for PI Liaison intake, question routing, and review notifications. Avoid scopes that allow broad workspace reading or administrative changes unless the use case requires them and the human owner approves.

## Immediate response to exposed credentials

1. Revoke the exposed token in Slack.
2. Regenerate the token.
3. Update `.env` on the local host or deployment environment.
4. Restart services so the new token is loaded.
5. Check git history if the token was committed.

If a token reached GitHub, assume it was exposed even if the repository is private. Rewriting history may be useful for cleanup, but it is not a substitute for revocation.

## Screenshots and prompt logs

Screenshots and prompt logs can leak secrets even when git is clean. Do not capture terminal output, browser pages, or config files that show full tokens. When asking an assistant for help, describe the token type and error, not the token value.

## PI Liaison boundary

Slack should talk only to the PI Liaison, not directly to execution agents. Slack messages should enter workspace queues and memory files, such as `QUESTIONS_FOR_USER.md`, `TEAM_BRIEF.md`, and `daily_notes/`, where they can be reviewed and routed.

Slack must never directly trigger arbitrary shell execution. Any request that would delete files, push to GitHub, install skills, mount directories, use billed APIs, publish content, or make sensitive claims still requires human review.

## Worker and Kubernetes boundary

Hermes worker jobs are bounded execution units, not autonomous sub-agent swarms. A trusted agent may draft a task YAML and summarize results, but cluster execution, new worker images, new mounts, broader RBAC, expensive runs, or external APIs with billing implications require human approval.

Kubernetes deployments should use namespace isolation, minimal Role permissions, resource limits, explicit task ConfigMaps, and persistent output volumes. Do not mount kubeconfig, cloud credentials, or broad host paths into Hermes containers unless a human owner approves the exact scope.

## Slack app setup checklist

For inbound Slack messages, Socket Mode credentials are necessary but not sufficient. The Slack app also needs message surfaces and events enabled.

- Enable Socket Mode.
- Create an app-level token with `connections:write` and use that value as `SLACK_APP_TOKEN`.
- Invite the bot to the target channel.
- In **App Home**, enable the Messages tab if users should DM the app.
- In **Event Subscriptions**, subscribe to bot events needed for the Liaison, such as `app_mention` for channel mentions and `message.im` for direct messages.
- Reinstall the Slack app to the workspace after changing scopes or event subscriptions.

If Slack shows "Sending messages to this app has been turned off," enable the App Home Messages tab and reinstall the app.
