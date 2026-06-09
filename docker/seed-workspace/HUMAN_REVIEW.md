# HUMAN_REVIEW.md

Human approval is required before any agent performs or finalizes the actions below.

## Always Require Approval

- Deleting files or directories
- Pushing to GitHub or another remote
- Installing third-party Hermes skills, plugins, or system tools
- Adding durable dependencies to the template image, `Dockerfile`, or requirements files
- Mounting new host folders into the container
- Sending emails, messages, posts, or other external communications
- Modifying credentials, tokens, auth profiles, API keys, or secrets
- Publishing web pages, reports, datasets, figures, or public documentation
- Making claims about communities, Tribes, Indigenous knowledge, public health, legal rules, or policy recommendations
- Running expensive or long jobs
- Using external APIs with billing implications
- Launching Kubernetes Jobs or other worker containers outside the approved local test path
- Changing worker image allowlists, Kubernetes RBAC, mounted volumes, or resource limits

## Container-Local Package Installs

Routine package installs inside the running container may proceed without an extra chat approval when they are needed for active analysis, do not alter credentials, do not mount host folders, and do not use paid services. Agents should log the package name, reason, and command in `daily_notes/`, `agent_reports/`, or a relevant provenance file.

If the package is needed again, propose a durable template change to `requirements-spatiotemporal.txt`, `requirements.txt`, or the `Dockerfile` so future containers are reproducible.

## Review Expectations

Approval should include the specific action, target files or services, expected cost or risk, and rollback plan when relevant. Silence is not approval.

Use native approval surfaces when available. For shell or tool execution, the agent should trigger an Hermes approval request that the user can approve or deny in the UI. For repository workflows, prefer the Hermes CMS/GitHub manager buttons for clone, branch, commit, push, and pull request actions. Agents should not ask users to type bare `/approve`.

## Why This Exists

Autonomous agents may have file, shell, network, and tool access. This workspace uses bounded roles and review gates to reduce risk, but it does not guarantee safe autonomy. Human judgment remains part of the workflow.
