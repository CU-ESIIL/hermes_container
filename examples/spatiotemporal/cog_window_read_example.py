#!/usr/bin/env python3
"""Read a small window from a cloud-optimized GeoTIFF."""

from __future__ import annotations

import json
from pathlib import Path


def main() -> int:
    import rasterio
    from rasterio.windows import Window

    url = (
        "https://oin-hotosm.s3.amazonaws.com/5a9c4f5d6d3f3700117c3a83/"
        "0/5a9c4f5d6d3f3700117c3a84.tif"
    )
    output = Path("/data/outputs/jobs/cog-window-demo/metadata.json")
    output.parent.mkdir(parents=True, exist_ok=True)
    with rasterio.Env():
      with rasterio.open(url) as dataset:
          window = Window(0, 0, min(256, dataset.width), min(256, dataset.height))
          array = dataset.read(1, window=window)
          summary = {
              "source": url,
              "driver": dataset.driver,
              "crs": str(dataset.crs),
              "shape": list(array.shape),
              "min": float(array.min()),
              "max": float(array.max()),
          }
    output.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
