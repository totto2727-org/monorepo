---
confirmed: true
---

# ADR: fold self-review into external review holistic checks

## Context

Review needs both focused specialist perspectives and a holistic consistency check. A standalone self-review gate duplicates independent review, while holistic checks fit naturally inside the external review boundary.

## Decision

Do not maintain a standalone self-review workflow step. Fold that responsibility into external review as a holistic perspective:

- External review covers focused dimensions such as security, performance, readability, test quality, API design, and holistic consistency.
- Holistic review checks artifact consistency, task completion, acceptance criteria coverage, and obvious broken links/frontmatter/YAML/Mermaid issues.
- Retrospectives capture process improvements after validation rather than acting as another review gate.

## Consequences

Review orchestration stays smaller and easier to run. Workflow-level review orchestration belongs outside `totto2727-dev-flow`; this repository-level plugin keeps only the rule that holistic review is part of independent review rather than a separate self-review gate.

> Superseded by [Consolidate durable development guidance in totto2727-coding](2026-07-20-consolidate-development-guidance-in-coding-plugin.md)
