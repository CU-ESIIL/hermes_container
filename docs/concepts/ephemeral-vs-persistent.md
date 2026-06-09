# Ephemeral Vs Persistent

Some parts of Hermes are meant to be rebuilt. Other parts are meant to last.

| Layer | Persistence | Examples |
| --- | --- | --- |
| Container runtime | Ephemeral | running processes, temporary shell state |
| Image | Rebuildable | installed tools, startup scripts, branding defaults |
| Repository | Persistent | docs, seed workspace, tests, scripts |
| Volumes | Persistent while kept | Hermes state, notebooks, outputs |
| External storage | Persistent outside the repo | large data, durable derived artifacts |
| Secrets | Injected, not stored | Slack tokens, API keys |

## Safe Rule

If you need it later, put it in one of these durable places:

- the repository,
- a mounted workspace folder,
- a named Docker volume,
- external storage with a manifest.

If it is sensitive, do not put it in git.

