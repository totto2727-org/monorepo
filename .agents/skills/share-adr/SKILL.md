---
name: share-adr
description: >-
  Shared ADR policy for decisions that span multiple executions, a roadmap, or
  the project. Use to select General or Roadmap mode, file an ADR, apply
  immutability rules, or coordinate references. Use share-artifacts for the
  ADR authoring guide and template.
---

# Shared ADR Index

Load only the reference required by the current decision.

## References

- [modes.md](references/modes.md) — General and Roadmap mode selection, storage locations, examples, and promotion or demotion.
- [filing.md](references/filing.md) — file specification, filing process, and directory layout.
- [immutability.md](references/immutability.md) — confirmation and supersession rules.
- [references.md](references/references.md) — links, filing-origin coordination, and retrospective boundaries.
- [ADR authoring guide](../share-artifacts/references/adr.md) — frontmatter, body structure, quality criteria, and supersession format.
- [ADR template](../share-artifacts/templates/adr.md) — skeleton used to create an ADR.

## Scope boundary

Use this skill only for durable decisions whose impact extends beyond one implementation effort. Keep local design decisions in that effort's design artifact and keep observations in the corresponding retrospective.
