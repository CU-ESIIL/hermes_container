---
hide:
  - toc
---

<section class="hero" markdown>

<div class="hero-copy" markdown>

<p class="eyebrow">ESIIL / OASIS</p>

# Hermes Container

Hermes Container is an ESIIL/OASIS research appliance for running Hermes in a reproducible, authorized, workspace-aware container.

GitHub is the control plane. The repo is memory. The container is runtime. The filesystem and GitHub panels make the runtime inspectable, and the Verde authorization model keeps deployment credentials out of the codebase.

<div class="cta-buttons" markdown>

[Start Here](start-here/index.md){ .md-button .md-button--primary }
[First 10 Minutes](start-here/first-10-minutes.md){ .md-button }
[Build and Run](build-and-run.md){ .md-button }
[Secrets and Authorization](security-and-credentials.md){ .md-button }

</div>

</div>

<div class="hero-art" markdown>

![Hermes mark](assets/brand/hermes.svg)

</div>

</section>

<section class="section-band" markdown>

<p class="section-label">Why Hermes</p>

## A practical research appliance

Hermes is not just a chat wrapper. It gives teams a bounded runtime, a mounted workspace, a visible filesystem, safe GitHub controls, and reproducible startup paths that can be smoke-tested locally and in CI.

<div class="homepage-card-grid" markdown>

<a class="homepage-card" href="agent-interface/">
  <strong>Agent Interface</strong>
  <p>Use the Hermes workbench with safe auth status and workspace context.</p>
  <span>Open the gateway</span>
</a>

<a class="homepage-card" href="workspace-file-manager/">
  <strong>Filesystem</strong>
  <p>Browse `/workspace`, outputs, docs, and mounted storage without exposing secrets.</p>
  <span>Inspect files</span>
</a>

<a class="homepage-card" href="github-repository-manager/">
  <strong>GitHub Integration</strong>
  <p>Treat approved repositories as project memory and a bounded control plane.</p>
  <span>Manage repos</span>
</a>

<a class="homepage-card" href="verde-api/">
  <strong>Verde API</strong>
  <p>Authorize Verde-backed model routes using the same secrets contract as the container runtime.</p>
  <span>Configure models</span>
</a>

</div>

</section>

<section class="section-band section-band--soft" markdown>

<p class="section-label">Workspace Model</p>

## Keep runtime, memory, and outputs legible

<div class="homepage-card-grid" markdown>

<a class="homepage-card" href="project-workspaces/">
  <strong>Project Workspaces</strong>
  <p>Understand how the mounted workspace holds active project context and connected repos.</p>
  <span>Organize work</span>
</a>

<a class="homepage-card" href="data-layout/">
  <strong>Data Layout</strong>
  <p>See where repo files, generated outputs, storage roots, and secret locations belong.</p>
  <span>Place files well</span>
</a>

<a class="homepage-card" href="runtime-state/">
  <strong>Runtime State</strong>
  <p>Understand `HERMES_STATE_DIR`, multi-instance launches, and safe runtime-root fallbacks.</p>
  <span>Operate safely</span>
</a>

</div>

</section>

<section class="section-band section-band--feature" markdown>

<p class="section-label">Validation</p>

## Verify before you trust

<div class="homepage-card-grid" markdown>

<a class="homepage-card" href="build-and-run/">
  <strong>Build and Run</strong>
  <p>Build the image, launch the stack, and start isolated additional instances.</p>
  <span>Run locally</span>
</a>

<a class="homepage-card" href="smoke-tests/">
  <strong>Smoke Tests</strong>
  <p>Validate docs, scripts, filesystem integration, GitHub safety checks, and demo workflow outputs.</p>
  <span>Test the appliance</span>
</a>

<a class="homepage-card" href="troubleshooting/">
  <strong>Troubleshooting</strong>
  <p>Recover from common problems with ports, auth, branding refreshes, and runtime state.</p>
  <span>Recover quickly</span>
</a>

</div>

</section>
