# Simulation Design for Urban Wildlife Corridor Geometry

Status: working design note, 2026-05-18. External reuse requires human approval.

## Why the first endpoint run was inadequate

The initial Phase 0 run was useful only as a scaffold check. It was not adequate evidence for a manuscript claim because it used a short fixed horizon, summarized only the final timestep, and did not test whether the community had reached equilibrium, a cycle, a slow transient, or a declining state. For a corridor geometry hypothesis, that distinction matters: dispersal networks may change extinction timing, rescue dynamics, recolonization after disturbance, or long transient coexistence even when endpoint richness looks identical.

The revised model therefore treats equilibrium as an empirical outcome of the simulation, not an assumption.

## Core design principles

1. Run long enough to separate initialization artifacts from long-run behavior.
2. Sample a post-burn-in window rather than reporting only the final timestep.
3. Report trend and variability diagnostics for the final window.
4. Classify runs as quasi-stationary only when recent abundance trends and temporal variability are small.
5. Preserve non-equilibrium outcomes as valid results instead of forcing an equilibrium interpretation.
6. Compare corridor geometries under multiple regimes: benign movement, costly movement, and disturbance.
7. Use cost-matched and topology-matched controls so dendritic advantages are not just length artifacts.
8. Track extinction timing and recolonization, not just final persistence.
9. Measure movement as effective time, risk, and flow continuity rather than Euclidean distance alone.
10. Model human and ecological transport networks together, because the prior design manuscript treats them as co-located metabolic networks.
11. Penalize aggregated crossings between high-flow human and non-human transport corridors, while allowing mixing in dispersed low-flow zones.
12. Include branching trunks, local branches, and city-scale rings as candidate ecological network motifs.

## Integration of the PI's prior work

The local files in `documents/source_materials/` substantially change the model target.

`Design principles for fitting cities and ecosystems into the same footprint 14 April 2021.docx` frames cities and ecosystems as overlapping transport/metabolic networks. Its design principles emphasize mutualistic co-design, dendritic maturation, minimizing time rather than distance, aligning inertial reference frames, reducing crossings between aggregated human and ecological flows, using elongated modules, and adding city-scale ring structure early.

`population dynamics on a network.qmd` provides the appropriate equation family: logistic growth on graph nodes with node-specific growth rates and carrying capacities, graph-mediated dispersal, exponential distance decay, stochastic growth/dispersal terms, extinction-time tracking, and a later multi-species community model with a competition matrix.

`Greenspace scaling.Rmd` provides the empirical-data path: use OpenStreetMap green-space polygons and city population data to estimate scaling relationships and eventually convert polygons into node coordinates, habitat areas, and carrying capacities.

The temporary JavaScript model should therefore be treated as a diagnostic scaffold only. The manuscript model should be rebuilt around the Quarto model family and the DOCX design rules.

## Current diagnostic implementation

The current script, scripts/simulate_corridor_population_dynamics.js, now runs a smaller interactive diagnostic protocol:

- 12 seeded landscapes
- 24 habitat patches
- 6 species
- 2200 timesteps
- burn-in through timestep 1200
- samples every 25 timesteps
- final diagnostic window of 600 timesteps
- geometries: nearest web, minimum spanning tree, dendritic tree, hybrid dendritic
- scenarios: benign long-run, costly movement, edge disturbance

This scale is deliberately small enough to rerun while the model is being debugged. It should not be treated as the final manuscript-scale run.

## Diagnostic endpoints

The script writes replicate-level and summary outputs with these key endpoints:

- recent_persistent_species: mean persistent species over the final sampled window
- long_run_persistent_species: mean persistent species over all post-burn-in samples
- persistent_species_per_length: final-window persistence divided by corridor length
- recent_regional_total_cv: temporal coefficient of variation in final-window total abundance
- recent_relative_trend_per_1000_steps: final-window abundance trend scaled by mean abundance
- quasi_stationary_flag: 1 only when final-window trend and variability are both small
- species_extinctions and mean_extinction_step: extinction count and timing
- failed_edges: disturbance realized in the graph

## What the current diagnostic run shows

Under the present deterministic logistic-competition equations, all runs become quasi-stationary by the final window. This does not prove that urban corridor metacommunities equilibrate. It means the current equations are too smooth and stabilizing to generate the kinds of non-equilibrium dynamics that may be central to the hypothesis.

The current geometry signal is still mostly an efficiency signal: the minimum spanning tree and dendritic geometries use less total corridor length than the nearest-neighbor web while maintaining similar recent persistence. That result is not yet a biological claim about superior dispersal. It is partly a network construction result and needs stronger controls.

## Required Phase 2 changes

### Add genuine non-equilibrium processes

The next model should include at least one of the following:

- demographic stochasticity
- environmental stochasticity
- seasonal habitat suitability
- disturbance pulses
- road or matrix mortality that varies over time
- patch-level catastrophes
- delayed density dependence
- Allee effects or mate limitation
- predation or apparent competition
- colonization-extinction dynamics for low-density populations

### Improve geometry comparisons

The geometry comparison needs controls that separate topology from length and density:

- cost-matched nearest-neighbor web
- cost-matched dendritic network
- minimum spanning tree
- Steiner-like tree approximation
- random geometric graph with matched edge count
- random geometric graph with matched total length
- circuit-style redundant network proxy
- dendritic networks with different branching ratios and depth

### Improve biological realism

The manuscript should move from generic species to functional groups with plausible trait ranges:

- low-mobility amphibian or small ground-dwelling species
- medium-mobility small mammal
- urban generalist bird or bat
- pollinator or ground arthropod group
- disturbance-sensitive specialist
- matrix-tolerant generalist

Each group should have explicit assumptions for movement kernel, corridor mortality, patch carrying capacity, disturbance sensitivity, and recolonization probability.

### Use stronger response variables

The primary outcomes should not be limited to final richness:

- time to first extinction
- time to loss of half the initial species pool
- probability of all-species persistence through a fixed horizon
- metacommunity occupancy through time
- recolonization after disturbance
- rescue effect frequency
- abundance variance and synchrony among patches
- coexistence under equal corridor construction cost
- robustness after edge or hub failure

## Recommended manuscript stance

The manuscript should be framed as a theory-testing simulation paper, not as a planning recommendation. The defensible question is:

Do hierarchical ecological transport networks maintain multi-species flow, persistence, and recovery better than nearest-distance networks when both are embedded within real urban land-use and human transport constraints?

The current answer is: the scaffold is ready, but the deterministic model is too stabilizing and too distance-centric to evaluate the strongest version of the theory. The next run should deliberately test regimes where equilibrium may not occur, where transient dynamics are ecologically important, and where travel time, crossing risk, ring structure, and flow continuity matter.
