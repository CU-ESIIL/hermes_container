#!/usr/bin/env python3
"""Open a Zarr store lazily and print metadata."""

from __future__ import annotations

import json


def main() -> int:
    import xarray as xr

    store = "https://storage.googleapis.com/cmip6/pangeo-cmip6-noQC.zarr"
    dataset = xr.open_zarr(store, consolidated=True)
    summary = {
        "source": store,
        "dims": {key: int(value) for key, value in dataset.sizes.items()},
        "variables_sample": list(dataset.data_vars)[:10],
    }
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
