#!/usr/bin/env python3
"""Validate a Hermes storage registry and optionally check local paths."""

from __future__ import annotations

import os
from pathlib import Path
from storage_common import credential_status, get_stores, load_registry, registry_arg_parser


def main() -> int:
    parser = registry_arg_parser("Validate Hermes storage registry entries.")
    parser.add_argument("--live", action="store_true", help="Check remote URLs with network requests.")
    args = parser.parse_args()

    registry = load_registry(args.config)
    stores = get_stores(registry)
    errors: list[str] = []
    warnings: list[str] = []

    if not stores:
        errors.append("No stores configured.")

    for name, store in stores.items():
        if not isinstance(store, dict):
            errors.append(f"{name}: store entry must be a mapping.")
            continue
        store_type = store.get("type")
        if not store_type:
            errors.append(f"{name}: missing type.")
        if store_type == "local":
            path = store.get("path")
            if not path:
                errors.append(f"{name}: local stores require path.")
            elif not Path(str(path)).exists():
                warnings.append(f"{name}: local path does not exist yet: {path}")
        if credential_status(store):
            for label, status in credential_status(store).items():
                if status == "unset":
                    warnings.append(f"{name}: credential env for {label} is unset.")
        if args.live and store.get("href"):
            import urllib.request

            req = urllib.request.Request(str(store["href"]), method="HEAD")
            try:
                with urllib.request.urlopen(req, timeout=10) as response:
                    if response.status >= 400:
                        warnings.append(f"{name}: HEAD returned HTTP {response.status}.")
            except Exception as exc:  # noqa: BLE001 - surface a clear diagnostic.
                warnings.append(f"{name}: live check failed: {exc}")

    for warning in warnings:
        print(f"warning: {warning}")
    for error in errors:
        print(f"error: {error}")
    if errors:
        return 1
    print(f"Storage registry ok: {args.config} ({len(stores)} stores).")
    if os.environ.get("HERMES_STORAGE_STRICT") and warnings:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

