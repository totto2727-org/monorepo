---
confirmed: true
---

# ADR: add QA design as an explicit workflow artifact boundary

## Context

The 2026-04-26 workflow cycle found that implementation planning was mixing task decomposition with test strategy. That made success criteria harder to observe and encouraged later validators to infer intended behavior from implementation details.

## Decision

Introduce a dedicated QA design boundary between design and task decomposition:

- `qa-design.md` records observable test cases, with stable test case IDs and execution/validation classification.
- `qa-flow.md` records the essential branching logic as Mermaid flowcharts and links leaves to test case IDs.
- Task decomposition may reference test case IDs, but it does not own the test strategy.
- Implementers and validators consume QA artifacts as inputs and may update them when implementation reveals missing branches.

## Consequences

Behavioral acceptance moved earlier in the cycle and became easier to validate. The exact tactical QA step is no longer maintained in this repository, but the document formats remain valuable and are preserved under the dev-flow shared artifacts.
