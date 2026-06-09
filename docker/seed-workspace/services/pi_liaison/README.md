# PI Liaison Service

The PI Liaison is the only default Slack-facing component. Slack messages should enter workspace queues and memory files for reviewable routing. Slack must never directly trigger arbitrary shell execution.

Copy `.env.template` to the repository root `.env` on the host and fill in local credentials there. Do not place real tokens in this directory.
