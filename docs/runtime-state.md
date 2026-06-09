# Runtime State

Hermes stores gateway state under `HERMES_STATE_DIR`, mounted into `/data/.openclaw` and `/root/.openclaw`.

This matters because:

- runtime auth and gateway state survive container restarts
- multi-instance launches do not collide
- unwritable runtime parents fall back to a writable temp directory instead of failing hard
