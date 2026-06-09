# TEAM_BRIEF.md - Working Group Brief

This document is written and maintained by the PI Liaison for the scientific working group. It translates the user's answers into a structured internal brief without inventing goals, facts, data sources, or approvals.

## Project summary

The project tests whether urban wildlife corridors should be designed as hierarchical ecological transport networks rather than shortest-distance webs among habitat fragments. the PI's prior work frames cities and ecosystems as co-located metabolic/transport networks, so Phase 1 should evaluate flow, time, crossing risk, disturbance recovery, and metacommunity persistence together. All claims remain preliminary until literature, domain, and skeptic review are complete.

## Key scientific question

Do dendritic, ringed, or fractal corridor geometries improve multi-species flow, dispersal, persistence, recovery, or coexistence relative to shortest-distance corridor webs under city transport constraints?

## User intent

The PI wants a manuscript draft grounded in real simulations, not just a conceptual essay. The theory is that transport-network-like hierarchy may organize ecological movement better than locally shortest paths, especially when movement is measured as effective time/risk and when human and non-human networks occupy the same footprint.

## Known constraints

- Use the PI's source materials in `documents/source_materials/` as the theoretical and modeling base.
- Use synthetic simulations until empirical sites, species, and data are selected or explicitly approved.
- Do not treat preliminary simulation outputs as validated ecological claims.
- Human approval is required before policy, community, public-facing, or empirical-site claims.
- The current JavaScript simulation is a diagnostic scaffold, not the manuscript-scale model.

## Expected outputs

- Reproducible simulation script.
- Simulation output tables and figure.
- Manuscript draft with methods, preliminary results, limitations, and next tests.
- Question queue for PI choices that affect Phase 1.

## Initial task assignments

| Role | Initial task | Expected output | Due or review point |
| --- | --- | --- | --- |
| Scientific Director | Review whether the current model directly tests the corridor hierarchy hypothesis or mostly tests corridor-length efficiency. | Phase 0 scientific review memo | Before claims are promoted beyond draft |
| Deputy Director / Integrator | Maintain artifact map across manuscript, simulation code, outputs, figures, assumptions, and questions. | Integration memo in agent_reports/urban_wildlife_corridors/ | Before Phase 1 sensitivity expansion |
| Quantitative Modeler | Extend the simulation to sensitivity analyses over dispersal, competition, corridor resistance, and disturbance. | Sensitivity script and diagnostics | Phase 1 |
| Domain Scientist | Review species dynamics, corridor assumptions, and plausibility for urban taxa. | Domain plausibility memo | Before manuscript interpretation hardens |
| Skeptic / Adversarial Reviewer | Test whether dendritic benefit is assumed rather than emergent. | Skeptic review memo | Required before any major claim |

## Assumptions to test

- Synthetic habitat fragments and niche gradients are sufficient for a Phase 0 model test.
- Corridor geometry can be usefully compared by both absolute biodiversity outcomes and biodiversity per corridor length.
- The first model is a scaffold; it does not include behavior, predation, mortality from roads, matrix permeability, human-network crossing costs, ring/trunk/branch flow motifs, or empirical calibration.

## Issues requiring skeptic review

- The initial run shows little absolute difference in coexistence among geometries, so the manuscript should not claim dendritic corridors increase coexistence without further model development.
- The apparent dendritic advantage is currently corridor-length efficiency, not stronger persistence.
- The stronger PI-derived hypothesis is about maintaining flow through co-located city/ecosystem transport systems; the model must not reduce that to a simple edge-length comparison.

## Issues requiring impact review

- Urban corridor recommendations affect communities, land access, governance, and planning priorities; public-facing guidance requires later impact review.

## Unresolved questions for the user

- Which target species groups should Phase 1 emphasize?
- Should the empirical path use Montreal first, given the source materials, or remain synthetic until the model is stable?
