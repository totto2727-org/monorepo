---
confirmed: true
---

# ADR: separate roadmap strategy from tactical execution cycles

## Context

Work that is too large for a single PR-sized execution requires a strategic roadmap layer. The roadmap layer keeps worldview, scope, milestone order, and coarse status visible across many execution units.

Tactical workflow execution belongs outside this repository-level plugin. Roadmap governance remains part of `totto2727-dev-flow`.

## Decision

Maintain a roadmap layer with these responsibilities:

- `docs/roadmap/<roadmap-id>/roadmap.md` is the stable strategic plan.
- `docs/roadmap/<roadmap-id>/milestones/` contains milestone-level intent and acceptance boundaries.
- `docs/roadmap/<roadmap-id>/adr/` contains roadmap-scoped architectural decisions.
- `docs/roadmap/<roadmap-id>/progress.yaml` is the machine-managed progress source and is edited through the roadmap CLI.
- Tactical implementation cycles are launched and managed outside this repository-level plugin; roadmap documents track only milestone-level state and references.

## Consequences

`totto2727-dev-flow` keeps high-level roadmap governance. Direct progress YAML editing is avoided so schema updates, timestamps, tasks, and formatting stay controlled by the roadmap CLI.

> Superseded by [Consolidate durable development guidance in totto2727-coding](2026-07-20-consolidate-development-guidance-in-coding-plugin.md)
