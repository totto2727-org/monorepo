# Roadmap Retrospective Authoring Guide

> Document type: concrete artifact authoring guide.

## Purpose

A roadmap retrospective explains what the roadmap achieved, how its milestone structure behaved in practice, and what should change in future roadmap work. It aggregates evidence without copying each implementation retrospective.

## Location

Write the report to `docs/retrospective/roadmap-<roadmap-id>.md`. The `roadmap-` prefix distinguishes it from implementation retrospectives stored in the same directory.

## Inputs

- `docs/roadmap/<roadmap-id>/roadmap.md`
- Every milestone file under `docs/roadmap/<roadmap-id>/milestones/`
- Final CLI-managed `progress.yaml`
- Retrospectives or summaries for linked implementation efforts

## Content

### Roadmap result

Summarize what the roadmap achieved against its stated purpose. Report incomplete, blocked, and cancelled milestones as explicitly as completed milestones.

### Milestone results

For each milestone, record its final status, the evidence supporting that status, and its linked workflow identifiers. The table must agree with `progress.yaml.milestones[]`.

### Dependency graph review

Identify dependencies that were necessary, unnecessary, or missing. Compare planned parallelism with actual execution and explain any resulting delay or rework.

### Implementation summary

Write one short paragraph per linked implementation effort. Include its identifier, milestone, notable result or issue, and a link to its retained retrospective or summary. Do not reproduce the source report.

### Improvements

Record only improvements that affect roadmap definition, milestone decomposition, dependency tracking, or shared state. Keep implementation-local improvements with their owning effort. Phrase each proposal as a concrete action under a stated condition.

### Handoff

Capture reusable milestone patterns, risks, and unresolved strategic work for the next roadmap. Generalize lessons where possible.

### Cost

Record total elapsed time, number of linked implementation efforts, and effective parallelism when those values are available from source data.

## Lifecycle

The report may be removed after its useful findings have been consumed. Before removal, file any durable cross-effort decision as an ADR.

## Quality criteria

- Every milestone has a final status and evidence.
- Every linked implementation effort is represented once.
- Claims are grounded in roadmap artifacts or execution records.
- Strategic improvements are separated from implementation-local improvements.
- Durable decisions are extracted into ADRs.

## Related documents

- [Roadmap Authoring Guide](roadmap.md)
- [Milestone Authoring Guide](milestone.md)
- [ADR Authoring Guide](adr.md)
