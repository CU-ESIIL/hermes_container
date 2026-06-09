#!/usr/bin/env python3
"""Cache a small approved dataset subset or explain the planned cache action."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
from storage_common import default_config_path, load_registry, require_store


def main() -> int:
    parser = argparse.ArgumentParser(description="Cache a dataset subset into /workspace/cache.")
    parser.add_argument("--config", default=default_config_path())
    parser.add_argument("--dataset", required=True, help="Store id to cache from.")
    parser.add_argument("--cache-dir", default="/workspace/cache")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--bbox", default="")
    parser.add_argument("--time", default="")
    args = parser.parse_args()

    registry = load_registry(args.config)
    store = require_store(registry, args.dataset)
    cache_dir = Path(args.cache_dir)
    target = store.get("path") or store.get("href") or store.get("bucket") or ""
    plan = f"cache subset from {args.dataset} ({store.get('type')}) {target} into {cache_dir}"
    if args.bbox:
        plan += f" bbox={args.bbox}"
    if args.time:
        plan += f" time={args.time}"

    if args.dry_run:
        print(f"dry-run: would {plan}")
        return 0
    cache_dir.mkdir(parents=True, exist_ok=True)
    manifest = cache_dir / f"{args.dataset}.cache-request.txt"
    manifest.write_text(plan + "\n", encoding="utf-8")
    print(f"Wrote cache request manifest: {manifest}")
    print("No large data were downloaded. Add provider-specific subset logic after human review.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
