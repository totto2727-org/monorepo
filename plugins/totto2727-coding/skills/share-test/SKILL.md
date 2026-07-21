---
name: share-test
description: >-
  Language-independent testing philosophy. Use when deciding what makes a test
  trustworthy and meaningful. Load js-test or mbt-test for executable test
  implementation. Use share-test-design-flow for concrete plans and reports.
---

# Shared Testing Philosophy

> Content type: conceptual guidance shared by every language.

## Observable behavior

Test the contract visible to a caller, not private implementation steps. Prefer returned values, emitted effects, durable state, and public errors over internal call order or private helper structure.

## Independence

Every test establishes its own state and remains valid in isolation, in a different order, and under parallel execution. Tests never depend on another test's side effects.

## Determinism

Control time, randomness, network access, and external state at the boundary. A result that depends on timing or ambient machine state is not reliable evidence.

## Behavior scope

Each test has a single reason to fail. Multiple assertions are acceptable when they jointly describe one observable outcome.

## Fixtures

Build only the state required by the behavior under test. Prefer small explicit fixtures over broad shared fixtures that hide causality.

## Scenario names

Test names communicate precondition, action, and expected result in domain language. Framework mechanics belong in the body, not in the name or human report.

## Type integrity

Tests are consumers of the production contract. Do not weaken types, bypass constructors, or suppress errors merely because code is under test.

## Concrete implementation skills

- [`js-test`](../js-test/SKILL.md) — tests executable through Vite+ and Vitest.
- [`mbt-test`](../mbt-test/SKILL.md) — tests executable through repository Vite+ tasks or `moon test`.

## Concrete design flow

- [`share-test-design-flow`](../share-test-design-flow/SKILL.md) — concrete test cases, success-criterion coverage, manual and AI-driven verification, Mermaid flows, and reports for human review.
