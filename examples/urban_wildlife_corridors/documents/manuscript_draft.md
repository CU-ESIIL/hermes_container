# Testing Hierarchical Ecological Transport Networks for Urban Metacommunity Flow and Recovery

Status: internal working manuscript draft, revised after full-team consultation on 2026-05-18. External reuse or planning guidance requires human approval.

## Abstract

Urban wildlife corridors are commonly treated as links among habitat fragments, often prioritized by short distance or low resistance. That framing can create connected graphs without necessarily creating multi-scale movement systems that sustain ecological flow, recolonization, and recovery. Building from prior design work by Ty Tuff and Andrew Gonzalez, we frame cities and ecosystems as co-located transport/metabolic networks that must fit into the same geographic footprint. This manuscript develops a testable simulation framework for asking whether hierarchical ecological transport networks, including branch, trunk, and ring motifs, outperform nearest-distance corridor webs under dispersal limitation, disturbance, stochastic extinction, and human-transport crossing constraints. A Phase 0 diagnostic simulation does not support any claim that dendritic corridors improve absolute biodiversity outcomes. Instead, it shows that the current deterministic scaffold is too stabilizing and too distance-centric: all geometries converge to similar quasi-stationary persistence, and apparent efficiency is confounded with corridor length. The next manuscript-scale model must therefore combine graph-mediated metacommunity dynamics, stochastic extinction-recolonization, cost-matched topology controls, effective travel-time and crossing-risk costs, and an empirical path from urban greenspace polygons to habitat nodes.

## 1. Introduction

Urbanization fragments habitat into patches separated by roads, buildings, impervious surfaces, lighting, noise, and other forms of hostile or semi-permeable matrix. Corridors are intended to reduce the ecological consequences of fragmentation by allowing organisms to disperse, recolonize, maintain gene flow, and recover after local disturbance.

Many corridor design workflows emphasize pairwise connectivity: nearby habitat fragments are linked because short connections are cheaper, easier to justify, and often assumed to reduce movement risk. This logic can produce a locally connected web without creating a coherent movement system across neighborhoods, habitat clusters, and city-scale refugia. A graph can be connected while still functioning poorly as a multi-scale dispersal network.

The prior design materials for this project make a stronger claim than "dendritic corridors are shorter." They argue that cities and ecosystems can be understood as co-located transport or metabolic networks. In that view, ecological corridor design should be evaluated by movement function: effective travel time, crossing risk, flow continuity, disturbance recovery, and the ability to support organisms with different movement scales. The design problem is not simply to minimize Euclidean distance among habitat fragments; it is to fit human and non-human transport systems into the same footprint while reducing harmful crossings between their high-flow components.

This manuscript treats hierarchical corridor geometry as a testable hypothesis. Dendritic, branch-trunk, and ringed networks may organize movement across scales better than nearest-distance webs under some conditions. They may also fail: pure trees can create bottlenecks, concentrate risk, and become vulnerable to hub or branch failure. The scientific task is therefore not to assert that dendritic designs are superior, but to identify the ecological and urban-transport conditions under which hierarchical geometry improves metacommunity flow, recovery, or persistence relative to fair controls.

## 2. Conceptual Framework

### 2.1 Ecological Corridors as Transport Networks

A corridor network is not only a set of edges. It is a movement system with paths, capacities, risks, and temporal dynamics. For wildlife, the relevant cost of movement may include distance, time, road mortality, predation risk, lighting, noise, habitat width, vegetation structure, and seasonal permeability. The same geometric corridor can therefore be cheap for one functional group and unusable for another.

The prior design manuscript emphasizes that mature transport systems often develop hierarchical organization: local branches feed larger trunks, and different movement scales are nested. For ecological systems, this suggests a working prediction: hierarchy may matter most when species differ in dispersal ability, when local extinctions require recolonization, or when disturbance disrupts part of the network.

### 2.2 Shared Human and Ecological Footprints

Cities already contain high-flow human transport networks. Ecological corridors placed into that footprint must either cross, follow, avoid, or repurpose parts of those networks. The design materials argue that human and non-human networks should cross as little as possible in their aggregated high-flow forms, while mixing may be acceptable in dispersed low-flow zones.

This implies that corridor evaluation should include a human-network conflict layer. A corridor that is short but crosses several major roads may have a higher effective cost than a longer route aligned with safer movement infrastructure. A manuscript-scale model should therefore measure movement by effective time and risk, not distance alone.

### 2.3 Why Equilibrium Is Not Enough

The user correctly flagged that a short endpoint simulation cannot establish equilibrium, and equilibrium may not be the relevant ecological endpoint. Corridors are often valuable because they affect transient and non-equilibrium processes: rescue effects, recolonization, recovery after disturbance, extinction timing, and movement under changing conditions. A model that always converges smoothly can be useful as a diagnostic scaffold, but it cannot test the strongest version of the corridor theory.

## 3. Working Predictions

These are working predictions, not established design rules.

| Prediction | Expected signal | Required controls | Primary response variables |
| --- | --- | --- | --- |
| P1. Persistence | Hierarchical or hybrid networks increase persistence only under dispersal limitation, disturbance, stochastic extinction, or costly movement. | Nearest web, minimum spanning tree, random geometric graphs, cost-matched rewired controls. | Regional persistence, local occupancy, all-functional-group persistence probability. |
| P2. Recovery | Geometry effects are strongest after disturbance. | Patch disturbance, edge disturbance, hub/trunk disturbance, matched disturbance intensity. | Recolonization probability, recovery time, rescue-effect frequency, time to first extinction. |
| P3. Efficiency | Dendritic or hybrid networks improve recovery or persistence per unit corridor cost only if they outperform low-cost tree controls. | Minimum spanning tree and cost-matched networks. | Persistence per cost, recovery per cost, flow per cost. |
| P4. Robustness | Pure trees are vulnerable to branch or hub failure; hybrid dendritic networks with local redundancy are more plausible. | Pure dendritic, hybrid dendritic, redundant mesh, ring-plus-branch. | Robustness after edge/hub failure, abundance synchrony, network fragmentation. |
| P5. Urban embedding | Networks minimizing effective travel time and high-flow human/ecological crossings outperform Euclidean shortest-distance designs. | Same corridor budget with and without crossing penalties. | Successful dispersal, crossing-risk exposure, persistence per crossing, recolonization after disturbance. |
| P6. Specialization | Hierarchical networks support functional diversity when species differ in movement scale and matrix sensitivity. | Functional group parameter sets and neutral/generic species controls. | Functional group persistence, beta diversity, evenness, response heterogeneity. |

## 4. Source Materials and Model Basis

Three source files anchor the current project direction.

The 2021 design-principles manuscript frames cities and ecosystems as co-located transport/metabolic networks. It motivates branch-trunk-ring motifs, effective time rather than Euclidean distance, reduced crossings between high-flow human and ecological networks, and the idea that growth, movement, and evolution are central design criteria.

The Quarto population-dynamics model develops the mathematical base: logistic growth on graph nodes, node-specific growth rates and carrying capacities, graph-distance dispersal, exponential dispersal decay, stochastic growth and dispersal terms, extinction-time tracking, and a multi-species competition matrix. The later multi-species block is exploratory and does not yet fully reconnect graph dispersal into the community equations; that is a priority for the manuscript-scale model.

The R Markdown greenspace-scaling workflow provides an empirical path from OpenStreetMap polygons and census data to habitat nodes, polygon areas, and possible carrying-capacity inputs. It should be treated as a workflow seed, not validated empirical evidence yet. It needs cleanup, explicit tag choices, reproducible data provenance, and validation before supporting city-specific claims.

## 5. Manuscript-Scale Simulation Design

### 5.1 State Variables

The manuscript-scale model should use a metacommunity state:

N[i, s, t] = abundance of functional group or species s in habitat node i at time t.

Node attributes should include patch area, habitat class, suitability, carrying capacity by species, local growth rate by species, centroid coordinates, and disturbance state. Edge attributes should include corridor length, effective travel time, movement risk, crossing/conflict penalty with human infrastructure, availability through time, and corridor type. Species attributes should include baseline growth, dispersal propensity, dispersal kernel scale, crossing sensitivity, environmental and demographic stochasticity, habitat optimum, and niche width.

### 5.2 Population Dynamics

The model should combine the Quarto equation family into one coherent stochastic graph metacommunity model:

dN_is/dt = r_is(t) N_is [1 - (N_is + sum_k alpha_sk N_ik) / K_is(t)] + I_is(t) - E_is(t) - M_is(t)

where alpha_sk is the competition matrix, K_is(t) is species-specific carrying capacity modified by patch area, habitat suitability, and disturbance, E_is(t) is emigration, I_is(t) is successful immigration through graph-mediated dispersal, and M_is(t) is local mortality from disturbance or matrix exposure.

For the first manuscript-scale implementation, a discrete seasonal or annual timestep may be preferable to stochastic noise inside an ODE derivative. The update order should be explicit: growth, demographic stochasticity, disturbance, emigration, dispersal allocation, dispersal survival, immigration, establishment, and extinction thresholding.

### 5.3 Movement Cost

Movement should be based on effective cost:

cost_ij_s(t) = shortest path sum across edges of [length cost + travel-time cost + species-specific risk + human-crossing penalty + junction penalty]

Dispersal probability can then follow an exponential kernel over effective cost, and successful arrival can decline with cost-sensitive mortality. This implements the design principle that time, risk, and flow continuity can matter more than Euclidean distance.

### 5.4 Corridor Geometries and Controls

The model should compare:

- nearest-distance web;
- minimum spanning tree;
- pure dendritic tree;
- hybrid dendritic network with local redundancy;
- ring-plus-branch network;
- random geometric graph matched by edge count;
- random geometric graph matched by total cost;
- cost-matched rewired network preserving degree or length distribution;
- human-conflict-optimized network minimizing high-flow crossings under a fixed budget.

No dendritic advantage should be claimed unless hierarchical or hybrid networks outperform these controls on ecological response variables after matching total cost, edge count, and relevant topology features.

### 5.5 Response Variables

Primary response variables should emphasize dynamics rather than endpoint richness:

- time to first local extinction;
- time to regional extinction by functional group;
- local occupancy through time;
- recolonization probability after disturbance;
- recovery time after patch, edge, hub, or trunk disturbance;
- rescue-effect frequency;
- realized successful dispersal across modules;
- abundance synchrony among patches;
- metacommunity evenness and beta diversity;
- persistence per unit corridor cost;
- persistence per high-flow crossing;
- robustness to edge, hub, and trunk failure;
- probability that all functional groups persist through the final window;
- quasi-stationarity as a diagnostic, not the sole endpoint.

## 6. Phase 0 Diagnostic Scaffold

The current JavaScript simulation is retained only as a diagnostic scaffold. It now uses 12 seeded landscapes, 24 habitat patches, 6 generic species, 3 scenarios, and 4 corridor geometries, producing 144 replicate-geometry-scenario rows. The script samples after burn-in and reports final-window trend, variability, extinction timing, and quasi-stationarity diagnostics.

The current diagnostic run does not provide evidence that dendritic geometry improves absolute multi-species persistence. It shows that the deterministic scaffold is too stabilizing: runs converge to similar quasi-stationary outcomes, and geometry effects are small relative to construction differences. Apparent efficiency signals are confounded with total corridor length; the minimum spanning tree is an especially important warning because it can appear highly efficient simply by being shortest.

The edge-disturbance scenario is also not yet adequate. Tree geometries cannot lose many edges without disconnecting, so edge-failure disturbance may be unevenly applied across geometries. Future disturbance tests need designs that distinguish topological fragility from implementation artifacts.

## 7. Model Adequacy Criteria

Before the manuscript can make claims about corridor performance, the model must satisfy these criteria:

1. The multi-species dynamics must include graph-mediated dispersal within the species-by-node equations.
2. Low-density populations must be able to go extinct and recolonize.
3. Disturbance must affect patches, edges, hubs, trunks, and human-crossing risk in explicitly documented ways.
4. Corridor comparisons must include cost-matched and topology-matched controls.
5. Functional groups must replace generic species before ecological interpretation.
6. Human-network crossing costs and effective travel-time costs must be implemented, not only discussed.
7. Outputs must include parameter manifests tying every table and figure to script parameters and seeds.
8. Empirical OSM-derived habitat nodes must be treated as unvalidated until tag choices, polygon cleaning, and habitat-quality assumptions are reviewed.
9. Skeptic review must test whether any dendritic benefit is built into network construction rather than emerging from population dynamics.
10. Human review is required before selecting Montreal or any real city as a case study or making planning guidance.

## 8. Limitations

This is an internal model-development draft. It does not validate dendritic corridors as an urban planning recommendation. It does not yet include focal taxa, field-calibrated movement behavior, road mortality, habitat quality validation, lighting/noise, vegetation structure, predation, seasonal movement, genetic dispersal, or empirical biodiversity data.

The source design manuscript contains broader claims about cities, scaling, ecosystem productivity, transport efficiency, green gentrification, and specific real-world examples. Those claims require formal citation and review before they can appear as manuscript evidence.

The greenspace-scaling workflow is promising but exploratory. OpenStreetMap tags are not equivalent to habitat quality without validation, and city-specific claims require reproducible extraction, documented tag choices, and human approval.

## 9. Updated Research Program

Phase 1 should rebuild the model around the Quarto equation family with complete species-by-node dispersal, stochastic extinction-recolonization, functional groups, and disturbance. The first target should be synthetic but source-grounded: synthetic city footprints with habitat-patch size distributions informed by the greenspace-scaling workflow, and human-network conflict layers abstracted from road-like barriers.

Phase 2 can add empirical geography after approval. Montreal is a natural candidate because the prior materials already use it, but it should remain a candidate until the data pipeline is reproducible and the project has explicit approval to make city-specific claims.

Phase 3 should add literature-backed interpretation, formal citation review, skeptic review, and only then a public-facing manuscript version.

## 10. Provisional Conclusion

Hierarchical ecological corridor geometry remains a plausible and testable design hypothesis, but it is unconfirmed. The current diagnostic scaffold does not show a robust biodiversity advantage for dendritic corridors. Its value is that it clarifies what the real test must include: stochastic extinction and recolonization, disturbance recovery, functional groups, cost-matched network controls, effective travel-time and crossing-risk costs, and explicit interaction between ecological and human transport networks.
