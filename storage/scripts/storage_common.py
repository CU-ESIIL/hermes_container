#!/usr/bin/env python3
"""Small storage-registry helpers with a PyYAML fallback parser."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Any


def load_registry(path: str | Path) -> dict[str, Any]:
    registry_path = Path(path)
    if not registry_path.exists():
        raise SystemExit(f"Storage config not found: {registry_path}")
    text = registry_path.read_text(encoding="utf-8")
    try:
        import yaml  # type: ignore

        data = yaml.safe_load(text) or {}
        if not isinstance(data, dict):
            raise SystemExit(f"Storage config must be a mapping: {registry_path}")
        return data
    except ModuleNotFoundError:
        return parse_simple_storage_yaml(text)


def parse_simple_storage_yaml(text: str) -> dict[str, Any]:
    """Parse the simple registry shape used by this repo when PyYAML is absent."""

    data: dict[str, Any] = {"stores": {}}
    current_store: str | None = None
    current_nested: str | None = None
    for raw_line in text.splitlines():
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        indent = len(raw_line) - len(raw_line.lstrip(" "))
        line = raw_line.strip()
        if indent == 0 and ":" in line:
            key, value = line.split(":", 1)
            key = key.strip()
            value = value.strip()
            if key == "stores":
                continue
            data[key] = coerce_scalar(value)
        elif indent == 2 and line.endswith(":"):
            current_store = line[:-1].strip()
            data["stores"][current_store] = {}
            current_nested = None
        elif indent == 4 and current_store and ":" in line:
            key, value = line.split(":", 1)
            key = key.strip()
            value = value.strip()
            if value:
                data["stores"][current_store][key] = coerce_scalar(value)
                current_nested = None
            else:
                data["stores"][current_store][key] = {}
                current_nested = key
        elif indent == 6 and current_store and current_nested and ":" in line:
            key, value = line.split(":", 1)
            data["stores"][current_store][current_nested][key.strip()] = coerce_scalar(value.strip())
    return data


def coerce_scalar(value: str) -> Any:
    if value in {"true", "True"}:
        return True
    if value in {"false", "False"}:
        return False
    try:
        return int(value)
    except ValueError:
        return value.strip('"').strip("'")


def registry_arg_parser(description: str) -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("--config", default=default_config_path(), help="Storage registry YAML file.")
    return parser


def default_config_path() -> str:
    configured = os.environ.get("HERMES_STORAGE_CONFIG")
    if configured:
        return configured
    if Path("storage/storage.yml").exists():
        return "storage/storage.yml"
    return "/opt/hermes/storage/storage.yml"


def get_stores(registry: dict[str, Any]) -> dict[str, Any]:
    stores = registry.get("stores", {})
    if not isinstance(stores, dict):
        raise SystemExit("Storage config field 'stores' must be a mapping.")
    return stores


def require_store(registry: dict[str, Any], name: str) -> dict[str, Any]:
    stores = get_stores(registry)
    store = stores.get(name)
    if not isinstance(store, dict):
        raise SystemExit(f"Unknown storage store: {name}")
    return store


def mask(value: str | None) -> str:
    if not value:
        return "unset"
    if len(value) <= 8:
        return "****"
    return f"{value[:4]}****{value[-4:]}"


def credential_status(store: dict[str, Any]) -> dict[str, str]:
    envs: dict[str, str] = {}
    nested = store.get("credentials_env", {})
    if isinstance(nested, dict):
        envs.update({str(k): str(v) for k, v in nested.items()})
    for key, value in store.items():
        if key.endswith("_env") and isinstance(value, str):
            envs[key] = value
    return {label: ("set:" + mask(os.environ.get(env_name)) if os.environ.get(env_name) else "unset") for label, env_name in envs.items()}


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
