#!/usr/bin/env python3
"""Register a dataset metadata record without moving data."""

from __future__ import annotations

import argparse
import datetime as dt
import os
from pathlib import Path
from storage_common import default_config_path, load_registry, write_json


def main() -> int:
    parser = argparse.ArgumentParser(description="Register a dataset metadata record.")
    parser.add_argument("--config", default=default_config_path())
    parser.add_argument("--name", required=True)
    parser.add_argument("--href", required=True)
    parser.add_argument("--type", required=True, choices=["stac", "cog", "zarr", "parquet", "netcdf", "s3", "webdav", "irods", "http", "local"])
    parser.add_argument("--store", default="")
    parser.add_argument("--description", default="")
    parser.add_argument("--out", default="storage/datasets.local.json")
    args = parser.parse_args()

    load_registry(args.config)
    record = {
        "name": args.name,
        "href": args.href,
        "type": args.type,
        "store": args.store,
        "description": args.description,
        "registered_at": dt.datetime.now(dt.UTC).isoformat(),
        "review_status": "draft",
    }
    out_path = Path(args.out)
    existing = []
    if out_path.exists():
        import json

        existing = json.loads(out_path.read_text(encoding="utf-8"))
    existing = [item for item in existing if item.get("name") != args.name]
    existing.append(record)
    write_json(out_path, existing)
    print(f"Registered dataset metadata: {args.name} -> {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
