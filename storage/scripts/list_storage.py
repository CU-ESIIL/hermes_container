#!/usr/bin/env python3
"""List configured Hermes storage locations without exposing secrets."""

from __future__ import annotations

import json
from storage_common import credential_status, get_stores, load_registry, registry_arg_parser


def main() -> int:
    parser = registry_arg_parser("List Hermes storage registry entries.")
    parser.add_argument("--json", action="store_true", help="Print machine-readable JSON.")
    args = parser.parse_args()

    registry = load_registry(args.config)
    stores = get_stores(registry)
    rows = []
    for name, store in stores.items():
        if not isinstance(store, dict):
            continue
        rows.append(
            {
                "name": name,
                "type": store.get("type", "unknown"),
                "target": store.get("path") or store.get("href") or store.get("bucket") or "",
                "credentials": credential_status(store),
                "description": store.get("description", ""),
            }
        )

    if args.json:
        print(json.dumps(rows, indent=2))
    else:
        for row in rows:
            print(f"{row['name']}\t{row['type']}\t{row['target']}")
            if row["description"]:
                print(f"  {row['description']}")
            if row["credentials"]:
                print(f"  credentials: {row['credentials']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

