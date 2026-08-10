---
name: share-test-design-flow
description: >-
  Shared test-design workflow for concrete test cases and human-facing reports.
  Use for qa-design.md, qa-flow.md, success-criterion coverage,
  automated/manual/AI-driven rationale, or a reviewable test plan and report.
  Do not use for choosing or running a test CLI.
---

# Shared Test Design Flow Index

This skill owns framework-agnostic test design and human-facing reporting. Testing philosophy belongs to share-test; executable implementation belongs to js-test or mbt-test.

## Workflow

- [workflow.md](references/workflow.md) — inputs, procedure, actor and verification-style rules, decision guidance, and exit criteria.

## Artifact pairs

- QA design: [guide](references/qa-design.md) and [template](templates/qa-design.md).
- QA flow: [guide](references/qa-flow.md) for standalone and embedded executable flows, and [template](templates/qa-flow.md) for standalone artifacts.

Produce qa-design.md and qa-flow.md together unless the user explicitly narrows the requested output. Present the artifacts themselves for human review.

## Related skills

- [share-test](../share-test/SKILL.md) — language-independent testing philosophy.
- [js-test](../js-test/SKILL.md) and [mbt-test](../mbt-test/SKILL.md) — executable test implementation.

## Out of scope

- Test command execution and CI verification.
- Framework-specific implementation patterns.
- Editing CI workflows.
