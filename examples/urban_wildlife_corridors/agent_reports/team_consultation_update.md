# Team Consultation Update - Urban Wildlife Corridors

Date: 2026-05-18
Status: internal working-group update after user requested full-team consultation.

## User request

The PI asked the working group to consult the whole team, update everyone, and produce an updated/refined manuscript using the newly added source materials in `documents/source_materials/`.

## Team consensus

The project should be reframed from "dendritic corridors beat shortest paths" to a more rigorous theory-testing question:

Do hierarchical ecological transport networks, including branch, trunk, and ring motifs, improve metacommunity flow, recovery, and persistence compared with nearest-distance corridor webs when movement is measured as effective time/risk and constrained by co-located human transport networks?

## Role readout

| Role bundle | Main guidance |
| --- | --- |
| Scientific Director / Domain Scientist | Treat hierarchy as a testable hypothesis, not a conclusion. Pure trees may be fragile; hybrid redundancy and functional groups are essential. |
| Quantitative Modeler / Data Engineer | Rebuild the manuscript model from the QMD equation family with species-by-node state variables, graph-mediated dispersal, stochasticity, extinction/recolonization, and parameter manifests. |
| Citation & Evidence Curator / Skeptic | Current results do not support dendritic superiority. Distance, length, topology, and hub placement are confounded. Broad claims from the DOCX need formal citations. |
| Scientific Narrative Lead / Technical Communicator | Restructure the manuscript as conceptual framework + simulation design + Phase 0 diagnostic + adequacy criteria, not as a results paper claiming design success. |
| Deputy Director / Societal Impact | Keep all planning, policy, public-health, equity, and city-specific claims in review status. Human approval is required before selecting Montreal or making public guidance. |

## Immediate correction completed

The team found an output-provenance mismatch: the manuscript described the current script parameters, but output files appeared to come from an older run. The current script was rerun on 2026-05-18. Outputs now match the current diagnostic parameters:

- 12 replicates
- 24 habitat patches
- 6 species
- 3 scenarios
- 4 geometries
- 144 replicate-geometry-scenario rows plus header

Updated outputs:

- `analysis/urban_wildlife_corridors/simulation_replicates.csv`
- `analysis/urban_wildlife_corridors/simulation_summary.csv`
- `analysis/urban_wildlife_corridors/README.md`
- `figures/urban_wildlife_corridors/simulation_summary.svg`

## Updated manuscript stance

The refined manuscript now says:

- The current scaffold is diagnostic only.
- The diagnostic run does not validate dendritic superiority.
- The strongest current finding is that the deterministic model is too stabilizing and too distance-centric.
- The real manuscript-scale test must include stochastic extinction/recolonization, disturbance recovery, functional groups, cost-matched network controls, effective travel-time costs, crossing-risk penalties, and explicit human/ecological network interactions.

## Role-specific next tasks

| Role | Next task |
| --- | --- |
| Scientific Director | Choose the first Phase 1 priority: persistence, recovery, cost efficiency, robustness, or human/ecological crossing conflict. |
| Quantitative Modeler | Build a unified metacommunity model with graph-mediated dispersal inside the multi-species equations. Avoid random draws inside ODE derivatives; use explicit stochastic discrete-time updates unless there is a strong reason not to. |
| Data Engineer | Add a manifest tying every output table and figure to exact script parameters, seed, and source code state. Prepare an OSM-to-node pipeline plan without running large downloads. |
| Domain Scientist | Define functional groups and plausible trait ranges before ecological interpretation. |
| Citation & Evidence Curator | Build a citation map for corridor efficacy, metacommunity rescue/recolonization, road ecology, optimal transport/constructal theory, urban scaling, and OSM habitat validation. |
| Skeptic | Test whether dendritic benefit is built into lower cost, edge count, hub placement, or disturbance implementation. |
| Scientific Narrative Lead | Keep the manuscript framed as model development and hypothesis testing until manuscript-scale results exist. |
| Technical Communicator | Maintain a clear distinction between the diagnostic JS scaffold and the future manuscript model. |
| Societal Impact / Translation | Hold planning, equity, public-health, policy, and city-specific language for human/domain review. |
| PI Liaison | Batch remaining high-value decisions for the PI and avoid low-value interruptions. |

## Human-review flags

Human approval is required before:

- selecting Montreal or another real city as a case study;
- using empirical biodiversity, community, or sensitive land-use data;
- making city-specific planning recommendations;
- making public-facing claims;
- making claims about affected communities, equity, public health, legal rules, Indigenous knowledge, or governance.

## Files updated in this pass

- `documents/urban_wildlife_corridors/manuscript_draft.md`
- `agent_reports/urban_wildlife_corridors/team_consultation_update.md`
- diagnostic outputs under `analysis/urban_wildlife_corridors/`
- `figures/urban_wildlife_corridors/simulation_summary.svg`

