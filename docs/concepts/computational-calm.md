# Computational Calm

Hermes is designed for scientists who want capable tools without living inside infrastructure.

The documentation and template should make it clear:

- what is safe to edit,
- what is generated,
- what should be reviewed,
- how to checkpoint,
- how to recover,
- when to ask for help.

## Design Principles

- Start with scientific purpose before technical detail.
- Prefer visible files and plain text over hidden magic.
- Keep agents bounded by roles, inputs, outputs, and review rules.
- Treat troubleshooting as normal scientific work.
- Make irreversible or expensive actions require human approval.

!!! tip "Mistakes are expected"
    Most problems are recoverable if secrets were not committed and important work was saved in the repository, a mounted workspace, a volume, or external storage.

