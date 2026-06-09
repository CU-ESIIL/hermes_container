# Data Layout

The visible filesystem panel should make these paths legible:

| Path | Meaning |
| --- | --- |
| repository root | appliance source, docs, compose, scripts, tests |
| `/workspace` | active project workspace |
| `/data/workspace` | same mounted workspace through the data root |
| `/data/outputs` | generated outputs and reviewable artifacts |
| `/external_storage/local` | mounted large-data area |
| `./secrets` | local secret source for the secrets overlay |

Writes are intentionally narrower than read visibility. Sensitive paths and token-like files are blocked.
