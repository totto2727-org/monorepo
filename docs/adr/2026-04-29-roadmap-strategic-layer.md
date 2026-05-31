---
confirmed: true
---

# ADR: separate roadmap strategy from tactical execution cycles

## Context

The 2026-04-29 roadmap cycle introduced a strategic layer for work that is too large for a single PR-sized workflow cycle. The durable need was to keep worldview, scope, milestone order, and coarse status visible across many execution cycles.

The tactical workflow layer has since moved out of this repository, but the roadmap-level responsibility remains.

## Decision

Maintain a roadmap layer with these responsibilities:

- `docs/roadmap/<roadmap-id>/roadmap.md` is the stable strategic plan.
- `docs/roadmap/<roadmap-id>/milestones/` contains milestone-level intent and acceptance boundaries.
- `docs/roadmap/<roadmap-id>/adr/` contains roadmap-scoped architectural decisions.
- `docs/roadmap/<roadmap-id>/progress.yaml` is the machine-managed progress source and is edited through the roadmap CLI.
- Tactical implementation cycles are launched and managed outside this repository-level plugin; roadmap documents track only milestone-level state and references.

## Consequences

The repository now keeps only high-level roadmap governance in `totto2727-dev-flow`. Direct progress YAML editing is avoided so schema migration, timestamps, tasks, and formatting stay controlled by the roadmap CLI.
