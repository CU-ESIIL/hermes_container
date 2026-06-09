#!/usr/bin/env python3
"""Sync or stage output artifacts to an approved storage target."""

from __future__ import annotations

import argparse
import os
import shutil
from pathlib import Path
from storage_common import default_config_path, load_registry, require_store


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync Hermes outputs to a configured store.")
    parser.add_argument("source", help="Output directory or file to sync.")
    parser.add_argument("--store", required=True)
    parser.add_argument("--config", default=default_config_path())
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    source = Path(args.source)
    if not source.exists():
        raise SystemExit(f"Source does not exist: {source}")
    registry = load_registry(args.config)
    store = require_store(registry, args.store)
    store_type = store.get("type")

    if store_type == "local":
        target_root = Path(str(store.get("path", "")))
        if args.dry_run:
            print(f"dry-run: would copy {source} to {target_root / source.name}")
            return 0
        target_root.mkdir(parents=True, exist_ok=True)
        target = target_root / source.name
        if source.is_dir():
            if target.exists():
                raise SystemExit(f"Target already exists; choose a new output name: {target}")
            shutil.copytree(source, target)
        else:
            shutil.copy2(source, target)
        print(f"Copied output to local store: {target}")
        return 0

    print(f"Store {args.store} is {store_type}. Use rclone/provider tooling after review.")
    print(f"dry-run: would sync {source} to {store.get('href') or store.get('bucket') or args.store}")
    if not args.dry_run:
        raise SystemExit("Remote sync is scaffolded only; rerun with provider-specific reviewed tooling.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
