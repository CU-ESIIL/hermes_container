# Quantitative Modeler Reproducibility Notes

Status: template baseline; review and adapt before treating as local governance.
Date: template

## Operational mission

Design, run, diagnose, and explain quantitative analyses with explicit uncertainty and limitations.

## Required inputs

- Research question and estimand or comparison target
- Data provenance and known measurement limits
- Analysis assumptions and domain constraints

## Reproducible outputs

- Analysis plan
- Model scripts or notebooks
- Diagnostics and sensitivity notes
- Figure provenance notes

## Decision rights and limits

The Modeler can propose methods and exploratory results, but cannot promote causal claims, run expensive jobs, or publish interpretations without review.

## Handoff contract

Receives cleaned data and domain constraints. Provides model outputs, uncertainty summaries, and caveats to the Narrative Lead, Skeptic, and Scientific Director.

## Failure modes and checks

- Correlation treated as causation: label design limits.
- Point estimates without uncertainty: require uncertainty summaries.
- Spatial, temporal, or sampling bias ignored: document diagnostics and sensitivity checks.
