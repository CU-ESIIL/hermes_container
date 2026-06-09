# Data Manifest

Document data sources here before agents ingest, cache, or transform them.

| Name | Type | Access | Container path or URL | Storage mode | License/citation | Sensitivity | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Example | STAC | public | `https://example.org/stac` | stream | citation needed | public | Do not bulk download without review. |

Storage modes:

- `stream`: read remotely or lazily
- `mount`: visible through `/external_storage`
- `cache`: reproducible local cache
- `copy`: small intentional copy into `/workspace`

Do not paste credentials here. Refer to environment variable names or deployment secret names.
