---
confirmed: true
---

# ADR: fold self-review into external review holistic checks

## Context

The 2026-04-29 review cleanup found that a standalone self-review step duplicated external review while missing issues that independent reviewers were better at finding. The useful part of self-review was the holistic check: alignment with design, task completion, success criteria coverage, and obvious artifact breakage.

## Decision

Do not maintain a standalone self-review workflow step. Fold that responsibility into external review as a holistic perspective:

- External review covers focused dimensions such as security, performance, readability, test quality, API design, and holistic consistency.
- Holistic review checks artifact consistency, task completion, acceptance criteria coverage, and obvious broken links/frontmatter/YAML/Mermaid issues.
- Retrospectives capture process improvements after validation rather than acting as another review gate.

## Consequences

The workflow became smaller and easier to run. In the current repository direction, oh-my-codingagent owns workflow-level review orchestration; this ADR preserves only the durable decision that holistic review belongs with independent review rather than a separate self-review gate.
