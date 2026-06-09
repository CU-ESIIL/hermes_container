#!/usr/bin/env python3
"""Query a STAC API without downloading full source scenes."""

from __future__ import annotations

import json


def main() -> int:
    from pystac_client import Client

    client = Client.open("https://earth-search.aws.element84.com/v1")
    search = client.search(
        collections=["sentinel-2-l2a"],
        bbox=[-105.35, 39.95, -105.15, 40.10],
        datetime="2023-06-01/2023-08-31",
        max_items=3,
    )
    items = list(search.items())
    summary = [
        {
            "id": item.id,
            "datetime": item.datetime.isoformat() if item.datetime else None,
            "asset_count": len(item.assets),
            "asset_names": sorted(item.assets.keys())[:10],
        }
        for item in items
    ]
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
