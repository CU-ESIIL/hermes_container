#!/usr/bin/env node

/*
 * Urban wildlife corridor geometry simulation.
 *
 * This is a deliberately inspectable Phase 1 model scaffold. It does not assume
 * that the community reaches equilibrium. Each replicate is run for a long
 * horizon, sampled after burn-in, and classified by final-window trend and
 * variability so the manuscript can distinguish equilibria from persistent
 * transients, cycles, or slow declines.
 */

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const ANALYSIS_DIR = path.join(ROOT, "analysis", "urban_wildlife_corridors");
const FIG_DIR = path.join(ROOT, "figures", "urban_wildlife_corridors");

const PARAMS = {
  replicates: 12,
  patches: 24,
  species: 6,
  maxSteps: 2200,
  burnInSteps: 1200,
  sampleEvery: 25,
  convergenceWindowSteps: 600,
  carryingCapacity: 95,
  growthMin: 0.16,
  growthMax: 0.34,
  competition: 0.26,
  dispersalRateMin: 0.018,
  dispersalRateMax: 0.080,
  kernelMin: 0.12,
  kernelMax: 0.30,
  nicheWidthMin: 0.10,
  nicheWidthMax: 0.24,
  demographicFloor: 1e-9,
  extinctionThreshold: 1e-5,
  occupancyThreshold: 4.0,
  presentRegionalThreshold: 6.0,
  convergenceRelativeTrendTolerance: 0.010,
  convergenceCvTolerance: 0.030,
  seed: 20260518,
};

const GEOMETRIES = ["nearest_web", "minimum_spanning_tree", "dendritic_tree", "hybrid_dendritic"];

const SCENARIOS = [
  {
    name: "benign_long_run",
    dispersalMortalityPerDistance: 0.00,
    edgeFailureFraction: 0.00,
    hubPenalty: 0.04,
  },
  {
    name: "costly_movement",
    dispersalMortalityPerDistance: 0.18,
    edgeFailureFraction: 0.00,
    hubPenalty: 0.07,
  },
  {
    name: "edge_disturbance",
    dispersalMortalityPerDistance: 0.10,
    edgeFailureFraction: 0.12,
    hubPenalty: 0.08,
  },
];

function ensureDirs() {
  fs.mkdirSync(ANALYSIS_DIR, { recursive: true });
  fs.mkdirSync(FIG_DIR, { recursive: true });
}

function mulberry32(seed) {
  let t = seed >>> 0;
  return function rand() {
    t += 0x6D2B79F5;
    let x = t;
    x = Math.imul(x ^ (x >>> 15), x | 1);
    x ^= x + Math.imul(x ^ (x >>> 7), x | 61);
    return ((x ^ (x >>> 14)) >>> 0) / 4294967296;
  };
}

function randn(rand) {
  const u = Math.max(rand(), 1e-12);
  const v = Math.max(rand(), 1e-12);
  return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
}

function dist(a, b) {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  return Math.sqrt(dx * dx + dy * dy);
}

function clamp(x, lo, hi) {
  return Math.min(hi, Math.max(lo, x));
}

function makeLandscape(rand, n) {
  const centers = [
    { x: 0.22, y: 0.25 },
    { x: 0.73, y: 0.29 },
    { x: 0.54, y: 0.72 },
  ];
  const patches = [];
  for (let i = 0; i < n; i++) {
    const c = centers[i % centers.length];
    const x = clamp(c.x + 0.13 * randn(rand), 0.03, 0.97);
    const y = clamp(c.y + 0.13 * randn(rand), 0.03, 0.97);
    patches.push({ id: i, x, y, env: clamp(0.58 * x + 0.32 * y + 0.12 * randn(rand), 0, 1) });
  }
  return patches;
}

function addEdge(edges, a, b, nodes, kind = "corridor") {
  if (a === b) return;
  const u = Math.min(a, b);
  const v = Math.max(a, b);
  const key = u + "-" + v;
  if (edges.has(key)) return;
  edges.set(key, { u, v, length: dist(nodes[u], nodes[v]), kind });
}

function nearestWeb(patches) {
  const nodes = patches.map((p) => ({ ...p, habitat: true }));
  const edges = new Map();
  for (const p of patches) {
    const neighbors = patches
      .filter((q) => q.id !== p.id)
      .map((q) => ({ id: q.id, d: dist(p, q) }))
      .sort((a, b) => a.d - b.d)
      .slice(0, 3);
    for (const q of neighbors) addEdge(edges, p.id, q.id, nodes, "shortest");
  }
  connectComponents(nodes, edges);
  return { nodes, edges: [...edges.values()], habitatIds: patches.map((p) => p.id) };
}

function minimumSpanningTree(patches) {
  const nodes = patches.map((p) => ({ ...p, habitat: true }));
  const inTree = new Set([0]);
  const edges = new Map();
  while (inTree.size < patches.length) {
    let best = null;
    for (const a of inTree) {
      for (const b of patches.map((p) => p.id)) {
        if (inTree.has(b)) continue;
        const d = dist(nodes[a], nodes[b]);
        if (!best || d < best.d) best = { a, b, d };
      }
    }
    addEdge(edges, best.a, best.b, nodes, "mst");
    inTree.add(best.b);
  }
  return { nodes, edges: [...edges.values()], habitatIds: patches.map((p) => p.id) };
}

function dendriticTree(patches, hybrid = false) {
  const nodes = patches.map((p) => ({ ...p, habitat: true }));
  const edges = new Map();

  function recurse(ids, depth) {
    const centroid = {
      id: nodes.length,
      x: ids.reduce((s, id) => s + nodes[id].x, 0) / ids.length,
      y: ids.reduce((s, id) => s + nodes[id].y, 0) / ids.length,
      env: ids.reduce((s, id) => s + nodes[id].env, 0) / ids.length,
      habitat: false,
      depth,
    };
    nodes.push(centroid);
    if (ids.length <= 3) {
      for (const id of ids) addEdge(edges, centroid.id, id, nodes, "terminal_branch");
      return centroid.id;
    }
    const xs = ids.map((id) => nodes[id].x);
    const ys = ids.map((id) => nodes[id].y);
    const splitByX = Math.max(...xs) - Math.min(...xs) >= Math.max(...ys) - Math.min(...ys);
    const sorted = ids.slice().sort((a, b) => splitByX ? nodes[a].x - nodes[b].x : nodes[a].y - nodes[b].y);
    const mid = Math.ceil(sorted.length / 2);
    const leftHub = recurse(sorted.slice(0, mid), depth + 1);
    const rightHub = recurse(sorted.slice(mid), depth + 1);
    addEdge(edges, centroid.id, leftHub, nodes, "trunk");
    addEdge(edges, centroid.id, rightHub, nodes, "trunk");
    return centroid.id;
  }

  recurse(patches.map((p) => p.id), 0);
  if (hybrid) {
    const longTerminalEdges = [...edges.values()]
      .filter((e) => nodes[e.u].habitat || nodes[e.v].habitat)
      .sort((a, b) => b.length - a.length)
      .slice(0, Math.max(2, Math.floor(patches.length / 8)));
    for (const e of longTerminalEdges) {
      const habitatEnd = nodes[e.u].habitat ? e.u : e.v;
      const candidates = patches
        .filter((p) => p.id !== habitatEnd)
        .map((p) => ({ id: p.id, d: dist(nodes[habitatEnd], p) }))
        .sort((a, b) => a.d - b.d);
      addEdge(edges, habitatEnd, candidates[0].id, nodes, "local_redundancy");
    }
  }
  return { nodes, edges: [...edges.values()], habitatIds: patches.map((p) => p.id) };
}

function connectComponents(nodes, edges) {
  while (true) {
    const comps = components(nodes.length, [...edges.values()]);
    if (comps.length <= 1) return;
    let best = null;
    for (const a of comps[0]) {
      for (let c = 1; c < comps.length; c++) {
        for (const b of comps[c]) {
          const d = dist(nodes[a], nodes[b]);
          if (!best || d < best.d) best = { a, b, d };
        }
      }
    }
    addEdge(edges, best.a, best.b, nodes, "component_bridge");
  }
}

function components(n, edges) {
  const adj = Array.from({ length: n }, () => []);
  for (const e of edges) {
    adj[e.u].push(e.v);
    adj[e.v].push(e.u);
  }
  const seen = Array(n).fill(false);
  const comps = [];
  for (let i = 0; i < n; i++) {
    if (seen[i]) continue;
    const stack = [i];
    const comp = [];
    seen[i] = true;
    while (stack.length) {
      const u = stack.pop();
      comp.push(u);
      for (const v of adj[u]) {
        if (!seen[v]) {
          seen[v] = true;
          stack.push(v);
        }
      }
    }
    comps.push(comp);
  }
  return comps;
}

function graphFor(geometry, patches) {
  if (geometry === "nearest_web") return nearestWeb(patches);
  if (geometry === "minimum_spanning_tree") return minimumSpanningTree(patches);
  if (geometry === "dendritic_tree") return dendriticTree(patches, false);
  if (geometry === "hybrid_dendritic") return dendriticTree(patches, true);
  throw new Error("unknown geometry " + geometry);
}

function disturbedEdges(edges, scenario, rand) {
  if (scenario.edgeFailureFraction <= 0) return edges;
  const edgeCount = Math.max(1, Math.floor(edges.length * scenario.edgeFailureFraction));
  const ranked = edges
    .map((e) => ({ e, score: e.length * (0.85 + 0.30 * rand()) }))
    .sort((a, b) => b.score - a.score);
  const failed = new Set(ranked.slice(0, edgeCount).map((x) => edgeKey(x.e.u, x.e.v)));
  const kept = edges.filter((e) => !failed.has(edgeKey(e.u, e.v)));
  return components(maxNodeId(edges) + 1, kept).length > 1 ? edges : kept;
}

function maxNodeId(edges) {
  return edges.reduce((m, e) => Math.max(m, e.u, e.v), 0);
}

function edgeKey(a, b) {
  return Math.min(a, b) + "-" + Math.max(a, b);
}

function movementMatrix(graph, speciesKernel, scenario) {
  const n = graph.nodes.length;
  const habitatN = graph.habitatIds.length;
  const adj = Array.from({ length: n }, () => []);
  const degree = Array(n).fill(0);
  for (const e of graph.edges) {
    degree[e.u]++;
    degree[e.v]++;
  }
  for (const e of graph.edges) {
    const junctionPenalty = 1 + scenario.hubPenalty * Math.max(0, degree[e.u] - 3) + scenario.hubPenalty * Math.max(0, degree[e.v] - 3);
    const w = e.length * junctionPenalty;
    adj[e.u].push({ v: e.v, w });
    adj[e.v].push({ v: e.u, w });
  }
  const M = Array.from({ length: habitatN }, () => Array(habitatN).fill(0));
  const survival = Array.from({ length: habitatN }, () => Array(habitatN).fill(0));
  for (let from = 0; from < habitatN; from++) {
    const d = dijkstra(adj, graph.habitatIds[from]);
    let totalPreference = 0;
    for (let to = 0; to < habitatN; to++) {
      if (from === to || !Number.isFinite(d[graph.habitatIds[to]])) continue;
      const distance = d[graph.habitatIds[to]];
      M[from][to] = Math.exp(-distance / speciesKernel);
      survival[from][to] = Math.exp(-scenario.dispersalMortalityPerDistance * distance);
      totalPreference += M[from][to];
    }
    if (totalPreference > 0) {
      for (let to = 0; to < habitatN; to++) M[from][to] /= totalPreference;
    }
  }
  const links = M.map((row, from) => row
    .map((p, to) => ({ to, value: p * survival[from][to] }))
    .filter((x) => x.to !== from && x.value > 0));
  return { links };
}

function dijkstra(adj, source) {
  const n = adj.length;
  const d = Array(n).fill(Infinity);
  const used = Array(n).fill(false);
  d[source] = 0;
  for (let k = 0; k < n; k++) {
    let u = -1;
    let best = Infinity;
    for (let i = 0; i < n; i++) {
      if (!used[i] && d[i] < best) {
        best = d[i];
        u = i;
      }
    }
    if (u < 0) break;
    used[u] = true;
    for (const edge of adj[u]) {
      const nd = d[u] + edge.w;
      if (nd < d[edge.v]) d[edge.v] = nd;
    }
  }
  return d;
}

function makeSpecies(rand, s) {
  const species = [];
  for (let i = 0; i < s; i++) {
    species.push({
      id: i,
      optimum: (i + 0.5) / s,
      width: PARAMS.nicheWidthMin + rand() * (PARAMS.nicheWidthMax - PARAMS.nicheWidthMin),
      r: PARAMS.growthMin + rand() * (PARAMS.growthMax - PARAMS.growthMin),
      dispersal: PARAMS.dispersalRateMin + rand() * (PARAMS.dispersalRateMax - PARAMS.dispersalRateMin),
      kernel: PARAMS.kernelMin + rand() * (PARAMS.kernelMax - PARAMS.kernelMin),
    });
  }
  return species;
}

function simulateOne(rep, geometry, scenario) {
  const rand = mulberry32(PARAMS.seed + rep * 1009);
  const disturbanceRand = mulberry32(PARAMS.seed + rep * 1009 + scenario.name.length * 313);
  const patches = makeLandscape(rand, PARAMS.patches);
  const species = makeSpecies(rand, PARAMS.species);
  const rawGraph = graphFor(geometry, patches);
  const graph = { ...rawGraph, edges: disturbedEdges(rawGraph.edges, scenario, disturbanceRand) };
  const habitatN = PARAMS.patches;

  const K = species.map((sp) => patches.map((p) => {
    const z = (p.env - sp.optimum) / sp.width;
    return 8 + PARAMS.carryingCapacity * Math.exp(-0.5 * z * z);
  }));
  const movement = species.map((sp) => movementMatrix(graph, sp.kernel, scenario));
  let N = species.map((sp, s) => patches.map((p, i) => 0.08 * K[s][i] * (0.4 + 1.2 * rand())));

  const samples = [];
  const speciesExtinctionStep = Array(species.length).fill(null);
  const sampleStartStep = PARAMS.burnInSteps;
  for (let t = 0; t <= PARAMS.maxSteps; t++) {
    if (t >= sampleStartStep && t % PARAMS.sampleEvery === 0) {
      samples.push(sampleState(t, N));
    }
    if (t === PARAMS.maxSteps) break;

    const afterGrowth = species.map(() => Array(habitatN).fill(0));
    const patchTotals = Array(habitatN).fill(0);
    for (let i = 0; i < habitatN; i++) {
      for (let s = 0; s < species.length; s++) patchTotals[i] += N[s][i];
    }
    for (let s = 0; s < species.length; s++) {
      for (let i = 0; i < habitatN; i++) {
        const competitiveLoad = N[s][i] + PARAMS.competition * (patchTotals[i] - N[s][i]);
        const growth = species[s].r * N[s][i] * (1 - competitiveLoad / K[s][i]);
        afterGrowth[s][i] = Math.max(PARAMS.demographicFloor, N[s][i] + growth);
      }
    }

    const next = species.map(() => Array(habitatN).fill(0));
    for (let s = 0; s < species.length; s++) {
      const m = species[s].dispersal;
      const links = movement[s].links;
      for (let from = 0; from < habitatN; from++) {
        next[s][from] += afterGrowth[s][from] * (1 - m);
        const emigrants = afterGrowth[s][from] * m;
        for (const link of links[from]) next[s][link.to] += emigrants * link.value;
      }
    }
    N = next;

    for (let s = 0; s < species.length; s++) {
      if (speciesExtinctionStep[s] === null && regionalTotalForSpecies(N, s) < PARAMS.extinctionThreshold) speciesExtinctionStep[s] = t + 1;
    }
  }

  const final = samples[samples.length - 1];
  const recentSamples = samples.filter((x) => x.step >= PARAMS.maxSteps - PARAMS.convergenceWindowSteps);
  const longRunPersistentMean = mean(samples.map((x) => x.persistentSpecies));
  const recentPersistentMean = mean(recentSamples.map((x) => x.persistentSpecies));
  const recentTotalMean = mean(recentSamples.map((x) => x.regionalTotal));
  const recentTotalCv = cv(recentSamples.map((x) => x.regionalTotal));
  const trend = relativeTrendPer1000Steps(recentSamples.map((x) => x.step), recentSamples.map((x) => x.regionalTotal));
  const stableFlag = Math.abs(trend) <= PARAMS.convergenceRelativeTrendTolerance && recentTotalCv <= PARAMS.convergenceCvTolerance;
  const edgeLength = graph.edges.reduce((a, e) => a + e.length, 0);
  const extinctions = speciesExtinctionStep.filter((x) => x !== null).length;
  const meanExtinctionStep = extinctions ? mean(speciesExtinctionStep.filter((x) => x !== null)) : "";

  return {
    replicate: rep,
    scenario: scenario.name,
    geometry,
    habitat_patches: habitatN,
    graph_nodes: graph.nodes.length,
    graph_edges: graph.edges.length,
    total_corridor_length: edgeLength,
    failed_edges: rawGraph.edges.length - graph.edges.length,
    final_persistent_species: final.persistentSpecies,
    long_run_persistent_species: longRunPersistentMean,
    recent_persistent_species: recentPersistentMean,
    persistent_species_per_length: recentPersistentMean / edgeLength,
    final_mean_occupancy: final.meanOccupancy,
    recent_evenness: mean(recentSamples.map((x) => x.evenness)),
    recent_regional_total: recentTotalMean,
    recent_regional_total_cv: recentTotalCv,
    recent_relative_trend_per_1000_steps: trend,
    quasi_stationary_flag: stableFlag ? 1 : 0,
    species_extinctions: extinctions,
    mean_extinction_step: meanExtinctionStep,
  };
}

function sampleState(step, N) {
  const speciesTotals = N.map((row) => row.reduce((a, b) => a + b, 0));
  const regionalTotal = speciesTotals.reduce((a, b) => a + b, 0);
  const rel = speciesTotals.map((x) => x / Math.max(regionalTotal, PARAMS.demographicFloor));
  const shannon = -rel.reduce((a, p) => p > 0 ? a + p * Math.log(p) : a, 0);
  const evenness = shannon / Math.log(speciesTotals.length);
  const persistentSpecies = speciesTotals.filter((x) => x > PARAMS.presentRegionalThreshold).length;
  const occupancy = N.map((row) => row.filter((x) => x >= PARAMS.occupancyThreshold).length / PARAMS.patches);
  return {
    step,
    persistentSpecies,
    meanOccupancy: mean(occupancy),
    evenness,
    regionalTotal,
  };
}

function regionalTotalForSpecies(N, s) {
  return N[s].reduce((a, b) => a + b, 0);
}

function relativeTrendPer1000Steps(xs, ys) {
  const yMean = Math.max(mean(ys), PARAMS.demographicFloor);
  const xMean = mean(xs);
  const numerator = xs.reduce((acc, x, i) => acc + (x - xMean) * (ys[i] - mean(ys)), 0);
  const denominator = xs.reduce((acc, x) => acc + (x - xMean) * (x - xMean), 0);
  if (denominator === 0) return 0;
  return (numerator / denominator) * 1000 / yMean;
}

function summarize(rows) {
  const grouped = {};
  for (const row of rows) {
    const key = row.scenario + "|" + row.geometry;
    grouped[key] ||= [];
    grouped[key].push(row);
  }
  const metrics = [
    "graph_edges",
    "total_corridor_length",
    "failed_edges",
    "final_persistent_species",
    "long_run_persistent_species",
    "recent_persistent_species",
    "persistent_species_per_length",
    "final_mean_occupancy",
    "recent_evenness",
    "recent_regional_total",
    "recent_regional_total_cv",
    "recent_relative_trend_per_1000_steps",
    "quasi_stationary_flag",
    "species_extinctions",
  ];
  const summary = [];
  for (const scenario of SCENARIOS) {
    for (const geometry of GEOMETRIES) {
      const subset = grouped[scenario.name + "|" + geometry];
      for (const metric of metrics) {
        const values = subset.map((r) => r[metric]).filter((x) => typeof x === "number" && Number.isFinite(x)).sort((a, b) => a - b);
        summary.push({
          scenario: scenario.name,
          geometry,
          metric,
          mean: mean(values),
          sd: sd(values),
          q05: quantile(values, 0.05),
          q50: quantile(values, 0.5),
          q95: quantile(values, 0.95),
        });
      }
    }
  }
  return summary;
}

function mean(xs) {
  return xs.reduce((a, b) => a + b, 0) / xs.length;
}

function sd(xs) {
  const m = mean(xs);
  return Math.sqrt(xs.reduce((a, b) => a + (b - m) * (b - m), 0) / Math.max(1, xs.length - 1));
}

function cv(xs) {
  const m = Math.abs(mean(xs));
  if (m < PARAMS.demographicFloor) return 0;
  return sd(xs) / m;
}

function quantile(xs, p) {
  const idx = (xs.length - 1) * p;
  const lo = Math.floor(idx);
  const hi = Math.ceil(idx);
  if (lo === hi) return xs[lo];
  return xs[lo] + (xs[hi] - xs[lo]) * (idx - lo);
}

function writeCsv(file, rows, columns) {
  const lines = [columns.join(",")];
  for (const row of rows) {
    lines.push(columns.map((c) => {
      const value = row[c];
      if (typeof value === "number") return Number.isFinite(value) ? value.toFixed(6) : "";
      return value;
    }).join(","));
  }
  fs.writeFileSync(file, lines.join("\n") + "\n");
}

function makeSvg(summary) {
  const metrics = [
    { key: "recent_persistent_species", label: "Recent persistent species" },
    { key: "persistent_species_per_length", label: "Recent species per length" },
    { key: "recent_regional_total_cv", label: "Recent total CV" },
    { key: "quasi_stationary_flag", label: "Quasi-stationary fraction" },
  ];
  const colors = {
    nearest_web: "#4e6b7d",
    minimum_spanning_tree: "#7b6a53",
    dendritic_tree: "#2f8f6f",
    hybrid_dendritic: "#b7791f",
  };
  const width = 1080;
  const height = 820;
  const panelW = 465;
  const panelH = 205;
  let svg = "";
  svg += '<svg xmlns="http://www.w3.org/2000/svg" width="' + width + '" height="' + height + '" viewBox="0 0 ' + width + ' ' + height + '">';
  svg += '<rect width="100%" height="100%" fill="#ffffff"/>';
  svg += '<text x="38" y="38" font-family="Arial" font-size="22" font-weight="700">Urban corridor geometry long-run simulation, preliminary</text>';
  svg += '<text x="38" y="62" font-family="Arial" font-size="13" fill="#555">Mean across ' + PARAMS.replicates + ' seeded landscapes; sampled after burn-in through step ' + PARAMS.maxSteps + '.</text>';
  let panel = 0;
  for (const scenario of SCENARIOS) {
    for (const metric of metrics) {
      if (panel >= 6) break;
      const x0 = 48 + (panel % 2) * 520;
      const y0 = 105 + Math.floor(panel / 2) * 235;
      panel++;
      const rows = GEOMETRIES.map((g) => summary.find((r) => r.scenario === scenario.name && r.geometry === g && r.metric === metric.key));
      const maxVal = Math.max(...rows.map((r) => r.q95)) * 1.15 || 1;
      svg += '<text x="' + x0 + '" y="' + (y0 - 32) + '" font-family="Arial" font-size="13" fill="#555">' + scenario.name.replace(/_/g, " ") + '</text>';
      svg += '<text x="' + x0 + '" y="' + (y0 - 12) + '" font-family="Arial" font-size="15" font-weight="700">' + metric.label + '</text>';
      svg += '<line x1="' + x0 + '" y1="' + (y0 + panelH) + '" x2="' + (x0 + panelW) + '" y2="' + (y0 + panelH) + '" stroke="#333"/>';
      svg += '<line x1="' + x0 + '" y1="' + y0 + '" x2="' + x0 + '" y2="' + (y0 + panelH) + '" stroke="#333"/>';
      rows.forEach((r, j) => {
        const cx = x0 + 58 + j * 108;
        const barW = 42;
        const barH = (r.mean / maxVal) * (panelH - 28);
        const y = y0 + panelH - barH;
        const q05 = y0 + panelH - (r.q05 / maxVal) * (panelH - 28);
        const q95 = y0 + panelH - (r.q95 / maxVal) * (panelH - 28);
        svg += '<rect x="' + (cx - barW / 2) + '" y="' + y + '" width="' + barW + '" height="' + barH + '" fill="' + colors[r.geometry] + '"/>';
        svg += '<line x1="' + cx + '" x2="' + cx + '" y1="' + q95 + '" y2="' + q05 + '" stroke="#222" stroke-width="2"/>';
        svg += '<line x1="' + (cx - 9) + '" x2="' + (cx + 9) + '" y1="' + q05 + '" y2="' + q05 + '" stroke="#222" stroke-width="2"/>';
        svg += '<line x1="' + (cx - 9) + '" x2="' + (cx + 9) + '" y1="' + q95 + '" y2="' + q95 + '" stroke="#222" stroke-width="2"/>';
        svg += '<text x="' + cx + '" y="' + (y0 + panelH + 17) + '" text-anchor="middle" font-family="Arial" font-size="10" fill="#333">' + shortName(r.geometry) + '</text>';
        svg += '<text x="' + cx + '" y="' + (y - 6) + '" text-anchor="middle" font-family="Arial" font-size="10" fill="#333">' + r.mean.toFixed(metric.key === "recent_regional_total_cv" || metric.key === "quasi_stationary_flag" ? 2 : 1) + '</text>';
      });
    }
  }
  svg += '</svg>';
  fs.writeFileSync(path.join(FIG_DIR, "simulation_summary.svg"), svg);
}

function shortName(geometry) {
  return {
    nearest_web: "web",
    minimum_spanning_tree: "mst",
    dendritic_tree: "tree",
    hybrid_dendritic: "hybrid",
  }[geometry] || geometry;
}

function writeReadme(summary) {
  const lines = [];
  lines.push("# Urban Wildlife Corridors Simulation Outputs");
  lines.push("");
  lines.push("Generated by scripts/simulate_corridor_population_dynamics.js on " + new Date().toISOString() + ".");
  lines.push("");
  lines.push("This is a preliminary long-run model scaffold, not a validated ecological result. It explicitly avoids assuming equilibrium: each replicate is sampled after burn-in, summarized over a final window, and assigned a quasi-stationary flag based on recent trend and variability.");
  lines.push("");
  lines.push("## Parameters");
  lines.push("");
  lines.push(JSON.stringify(PARAMS, null, 2));
  lines.push("");
  lines.push("## Scenario definitions");
  lines.push("");
  lines.push(JSON.stringify(SCENARIOS, null, 2));
  lines.push("");
  lines.push("## Main summary");
  lines.push("");
  lines.push("| Scenario | Geometry | Recent persistent species | Species per corridor length | Recent total CV | Trend per 1000 steps | Quasi-stationary fraction | Corridor length |");
  lines.push("| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |");
  for (const scenario of SCENARIOS) {
    for (const g of GEOMETRIES) {
      const get = (m) => summary.find((r) => r.scenario === scenario.name && r.geometry === g && r.metric === m).mean;
      lines.push("| " + scenario.name + " | " + g + " | " + get("recent_persistent_species").toFixed(2) + " | " + get("persistent_species_per_length").toFixed(3) + " | " + get("recent_regional_total_cv").toFixed(3) + " | " + get("recent_relative_trend_per_1000_steps").toFixed(4) + " | " + get("quasi_stationary_flag").toFixed(2) + " | " + get("total_corridor_length").toFixed(2) + " |");
    }
  }
  fs.writeFileSync(path.join(ANALYSIS_DIR, "README.md"), lines.join("\n") + "\n");
}

function main() {
  ensureDirs();
  const rows = [];
  for (let rep = 0; rep < PARAMS.replicates; rep++) {
    for (const scenario of SCENARIOS) {
      for (const geometry of GEOMETRIES) rows.push(simulateOne(rep, geometry, scenario));
    }
  }
  const summary = summarize(rows);
  writeCsv(path.join(ANALYSIS_DIR, "simulation_replicates.csv"), rows, [
    "replicate",
    "scenario",
    "geometry",
    "habitat_patches",
    "graph_nodes",
    "graph_edges",
    "total_corridor_length",
    "failed_edges",
    "final_persistent_species",
    "long_run_persistent_species",
    "recent_persistent_species",
    "persistent_species_per_length",
    "final_mean_occupancy",
    "recent_evenness",
    "recent_regional_total",
    "recent_regional_total_cv",
    "recent_relative_trend_per_1000_steps",
    "quasi_stationary_flag",
    "species_extinctions",
    "mean_extinction_step",
  ]);
  writeCsv(path.join(ANALYSIS_DIR, "simulation_summary.csv"), summary, ["scenario", "geometry", "metric", "mean", "sd", "q05", "q50", "q95"]);
  makeSvg(summary);
  writeReadme(summary);
  console.log("Wrote analysis to " + ANALYSIS_DIR);
  console.log("Wrote figure to " + path.join(FIG_DIR, "simulation_summary.svg"));
}

main();
