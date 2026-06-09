# Prior Work Synthesis for Urban Wildlife Corridors

Status: internal synthesis from local source materials, captured for repository review on 2026-05-18. Publication or external reuse requires human approval.

## Source materials reviewed

- Design principles for fitting cities and ecosystems into the same footprint 14 April 2021.docx
- population dynamics on a network.qmd
- Greenspace scaling.Rmd

## Central conceptual frame from the DOCX

The prior manuscript frames cities and ecosystems as co-located transport/metabolic networks. The key claim is not simply that dendritic corridors are shorter. The stronger theoretical claim is that mature flow systems become efficient by organizing movement through branching, hierarchical, tree-like transport structures across spatial scales.

Important design principles extracted from the DOCX:

1. Cities and green networks should be designed together as mutualists operating at the same spatial and temporal scales.
2. Cities and ecosystems are both metabolic networks that gain efficiency as they grow larger.
3. Metabolic networks mature by rewiring toward dendritic/tree-shaped flow structures.
4. Mature systems support energetic specialization and diversity.
5. Urban green spaces should be designed to produce ecosystem functions efficiently and remain resilient to perturbation.
6. Human and non-human transport networks should cross as little as possible in their aggregated/high-flow forms, while mixing can occur in dispersed/low-flow forms.
7. Design should minimize travel time, not Euclidean distance, while maintaining flow.
8. Rectangular/elongated modules may be preferable to square modules, with access to faster/larger zones at one end and slower/smaller zones at the other.
9. City-scale green networks should include ring structure early, rather than only local patch-to-patch links.
10. Growth, movement, and evolution are fundamental goals of the spaces, so equilibrium should not be treated as the only valid endpoint.

## Implications for the corridor model

The previous simulation scaffold was too narrow because it treated corridor geometry mainly as a graph-topology comparison. The prior work implies a richer design problem:

- The ecological network is a dispersal transport network embedded in and constrained by the human transport network.
- Corridor cost should include crossing conflicts with roads or other high-flow human structures, not only corridor length.
- Movement cost should be measured in effective time/risk/entropy, not only distance.
- Dendritic designs should be compared against networks with rings, local branches, and mixed trunk/branch scales.
- A successful design should maintain flow under growth and disturbance, not merely maximize endpoint occupancy.
- The model should test whether dendritic structure supports specialization by maintaining species with different movement scales, habitat needs, and disturbance sensitivities.

## Population dynamics model extracted from the QMD

The Quarto file develops a sequence of network population-dynamics models:

- single-species logistic growth with dispersal among graph nodes
- dispersal matrices based on Euclidean distance, graph shortest-path distance, or exponential distance decay
- node-specific growth rates and carrying capacities
- extinction-time tracking
- demographic and dispersal stochasticity
- multi-species community dynamics with a competition matrix
- larger graph examples up to 150 nodes
- ODE integration using deSolve, with explicit tolerances and long max-step allowances

The recurring mathematical structure is:

dN_i/dt = r_i N_i (1 - N_i / K_i) + incoming dispersal - outgoing dispersal

For the community case, this becomes:

dN_ij/dt = r_ij N_ij (1 - (N_ij + competition effects) / K_ij)

The QMD currently sketches competition and stochasticity, but some later community blocks do not yet fully reconnect dispersal into the multi-species equations. That is an implementation opportunity: the new manuscript model should combine the best parts into one coherent metacommunity model with node-specific r/K, competition, stochasticity, and graph-mediated dispersal.

## Greenspace scaling model extracted from the RMD

The R Markdown file uses OpenStreetMap and Canadian census data to estimate how urban land-use polygons scale with city population. It includes:

- OSM extraction for parks, gardens, nature reserves, dog parks, commons, pitches, wood, buildings, residential land, and farmland
- polygon area extraction with log-area transformations
- Canadian census city population joins
- log-log scaling plots of greenspace area versus population
- notes about formatting polygons as XY coordinates or node IDs for a metapopulation model
- exploratory sidewalk extraction as potential movement infrastructure

This is directly relevant because the corridor model should not use arbitrary synthetic patches forever. A data-grounded version can derive habitat nodes from OSM greenspace polygons, node carrying capacities from polygon area/suitability, and human-network conflict costs from roads or pedestrian infrastructure.

## Revised research question

Do hierarchical ecological corridor networks maintain multi-species metacommunity flow, persistence, and recovery better than nearest-distance networks when both are embedded within real urban land-use and human transport constraints?

## Revised model architecture

1. Landscape layer:
   - habitat patches from OSM greenspace polygons or synthetic analogues calibrated to the greenspace scaling results
   - patch carrying capacity as a function of polygon area, habitat class, and suitability
   - city size or footprint as a scaling axis

2. Human transport layer:
   - roads/sidewalks/other linear infrastructure as crossing-risk and travel-time constraints
   - high-flow human corridors treated as costly barriers for non-human aggregated movement

3. Ecological transport layer:
   - local branches, trunks, rings, and hybrid dendritic designs
   - movement cost measured as effective time/risk rather than Euclidean distance alone
   - explicit penalties for crossing human high-flow corridors

4. Population layer:
   - multi-species node-by-species abundance state
   - node- and species-specific r and K
   - competition matrix
   - graph-mediated dispersal
   - demographic/environmental/dispersal stochasticity
   - extinction and recolonization

5. Response layer:
   - extinction timing
   - recolonization after disturbance
   - rescue effects
   - abundance synchrony
   - flow continuity
   - persistence per construction cost
   - conflict/crossing count with human network
   - function proxy from biomass or occupancy weighted by specialization

## Immediate implementation priorities

1. Rebuild the simulation around the QMD equation family rather than the temporary JavaScript scaffold.
2. Add a network generator that creates explicit trunks, branches, rings, and nearest-neighbor webs.
3. Replace distance-only movement with effective travel-time/risk costs.
4. Add crossing/conflict penalties between ecological and human transport networks.
5. Use the Greenspace scaling RMD to define an empirical-data path from OSM polygons to patch nodes.
6. Keep the current synthetic model only as a fast diagnostic, not as the manuscript model.
