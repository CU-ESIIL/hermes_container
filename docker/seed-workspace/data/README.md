# Data

Use this directory only for data that the user intentionally places in the workspace or that a documented workflow creates.

Do not silently ingest external data. When adding data, document source, access method, license, citation requirements, sensitivity, and whether it can be committed or must remain local.

Recommended subdirectories:

- `raw/` for original local copies or controlled inputs.
- `processed/` for cleaned or transformed data.
- `derived/` for reproducible outputs from scripts.

Large, sensitive, licensed, or private data should stay out of git unless the user explicitly approves inclusion.
