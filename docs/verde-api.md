# Verde API

Hermes uses the same Verde provider model as the reference appliance while rebranding the surrounding interface for Hermes.

At startup the Hermes entrypoint:

- reads `_FILE` secret values into process environment variables
- registers the Verde provider when a key is available
- preserves tokenized local gateway auth and bounded model routing

Use `scripts/check_auth.sh` to validate configuration safely.
