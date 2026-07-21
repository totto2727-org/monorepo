---
confirmed: true
---

# ADR: treat PR and CI state as observable execution signals, not primary roadmap state

## Context

PR and CI state are useful operational evidence around execution, but repository artifacts remain the source of progress truth. Roadmap documents should not become a mirror of transient PR lifecycle details.

## Decision

Use PR and CI state as derived observability around execution:

- Progress state remains in `progress.yaml` for roadmaps and in the execution system for tactical cycles.
- PR descriptions may summarize current state for reviewers, but they are not persisted as repository source-of-truth documents.
- CI results are validation evidence and blockers, not roadmap schema fields unless explicitly linked as PR URLs or notes.
- Roadmap progress may store linked PRs and milestone notes; detailed CI retry procedures belong to the execution workflow system.

## Consequences

Roadmap documents stay concise while still allowing PR links and notes. Tactical PR/CI lifecycle details belong outside `totto2727-dev-flow`.

> Superseded by [Consolidate durable development guidance in totto2727-coding](2026-07-20-consolidate-development-guidance-in-coding-plugin.md)
