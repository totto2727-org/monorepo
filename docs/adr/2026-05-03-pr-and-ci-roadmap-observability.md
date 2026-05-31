---
confirmed: true
---

# ADR: treat PR and CI state as observable execution signals, not primary roadmap state

## Context

The 2026-05-03 workflow cycle added draft PR creation, PR description updates, CI monitoring, retry guidance, and ready-for-review transitions. Its durable lesson was that PR/CI state is useful operational evidence, but repository artifacts remain the source of progress truth.

## Decision

Use PR and CI state as derived observability around execution:

- Progress state remains in `progress.yaml` for roadmaps and in the execution system for tactical cycles.
- PR descriptions may summarize current state for reviewers, but they are not persisted as repository source-of-truth documents.
- CI results are validation evidence and blockers, not roadmap schema fields unless explicitly linked as PR URLs or notes.
- Roadmap progress may store linked PRs and milestone notes; detailed CI retry procedures belong to the execution workflow system.

## Consequences

Roadmap documents stay concise while still allowing PR links and notes. Tactical PR/CI lifecycle details are no longer maintained in `totto2727-dev-flow` because workflow-level operation is delegated outside this repository.
