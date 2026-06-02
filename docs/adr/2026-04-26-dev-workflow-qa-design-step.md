---
confirmed: true
---

# ADR: add QA design as an explicit workflow artifact boundary

## Context

Implementation planning, task decomposition, and test strategy require separate artifact boundaries. Observable success criteria must be defined before implementation tasks so validators can check behavior without inferring intent from implementation details.

## Decision

Introduce a dedicated QA design boundary between design and task decomposition:

- `qa-design.md` records observable test cases, with stable test case IDs and execution/validation classification.
- `qa-flow.md` records the essential branching logic as Mermaid flowcharts and links leaves to test case IDs.
- Task decomposition may reference test case IDs, but it does not own the test strategy.
- Implementers and validators consume QA artifacts as inputs and may update them when implementation reveals missing branches.

## Consequences

Behavioral acceptance is defined before task execution and remains easy to validate. `totto2727-dev-flow` preserves the QA document formats as shared artifacts; tactical QA orchestration belongs outside this repository-level plugin.
