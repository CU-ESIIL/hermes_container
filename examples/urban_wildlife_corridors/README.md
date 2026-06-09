# Urban Wildlife Corridors Example Snapshot

This snapshot captures selected outputs from the local OpenClaw scientific working group after the agents discussed the user-provided source materials and developed a Phase 0 urban wildlife corridor project.

The snapshot is intended for repository review and reproducibility. It does not include the original source uploads from `workspace/documents/source_materials/`, local `.env` files, OpenClaw runtime state, Slack state, or private auth material.

## Contents

- `documents/` - manuscript draft, prior-work synthesis, source inventory, and simulation design.
- `agent_reports/` - team consultation and integration memos.
- `analysis/` - simulation manifest, summary table, and replicate table.
- `figures/` - generated SVG summary figure.
- `literature/` - citation-target notes.
- `project_state/` - selected charter, team brief, assumptions, questions, decisions, tasks, and daily note.
- `scripts/` - simulation script used to generate the included analysis outputs and figure.

## Reproduce The Included Simulation

From this example directory:

```bash
node scripts/simulate_corridor_population_dynamics.js
```

The script writes outputs relative to its working tree, so run it from `examples/urban_wildlife_corridors/` if you want to refresh this snapshot's `analysis/` and `figures/` files.

## Review Notes

The current model is a diagnostic scaffold, not a validated ecological model. The manuscript draft and reports intentionally flag limitations around taxa selection, empirical calibration, road mortality, behavior, predation, matrix permeability, governance, and literature support.
