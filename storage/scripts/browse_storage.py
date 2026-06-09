#!/usr/bin/env python3
"""Print the target for one configured storage location."""

from __future__ import annotations

import argparse
import os
from storage_common import credential_status, default_config_path, load_registry, require_store


def main() -> int:
    parser = argparse.ArgumentParser(description="Show one Hermes storage target.")
    parser.add_argument("store")
    parser.add_argument("--config", default=default_config_path())
    args = parser.parse_args()

    registry = load_registry(args.config)
    store = require_store(registry, args.store)
    target = store.get("path") or store.get("href") or store.get("bucket") or ""
    print(f"{args.store}\t{store.get('type', 'unknown')}\t{target}")
    if store.get("description"):
        print(store["description"])
    if credential_status(store):
        print(f"credentials: {credential_status(store)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
