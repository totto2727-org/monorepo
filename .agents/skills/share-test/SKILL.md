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

## Assertion and expectation APIs

Use the narrowest language- or framework-provided assertion, matcher, snapshot, or expected-failure notation that directly expresses the observable contract. Do not reimplement an available assertion with boolean comparisons, mutable control state, or manual bookkeeping.

Use the test framework's native error, exception, rejection, or panic expectation instead of assigning occurrence or a caught exception to a temporary variable. Treat mutable sentinel state and catch-only bookkeeping as anti-patterns because they obscure the expected behavior and can let an unintended execution path pass.

Catch an error explicitly only when its identity, variant, payload, message, or another property is itself part of the observable contract and the framework cannot assert it directly. Assert the captured property rather than using the catch merely to control whether the test passes.

Follow the language-specific implementation guides for executable examples:

- [`js-test`](../js-test/SKILL.md) — use semantic Vitest matchers, `toThrow`, and awaited `rejects`.
- [`mbt-test`](../mbt-test/SKILL.md) — use inspection APIs for direct results and `panic_` plus `try!` for raised errors.

## Independence

Every test establishes its own state and remains valid in isolation, in a different order, and under parallel execution. Tests never depend on another test's side effects.

## Determinism

Control time, randomness, network access, and external state at the boundary. A result that depends on timing or ambient machine state is not reliable evidence.

## Behavior scope

Each test has a single reason to fail. Multiple assertions are acceptable when one setup and one system-under-test invocation produce multiple observable facts that jointly describe one outcome.

Do not treat a shared fixture as sufficient reason to combine cases. When verification requires invoking the system under test again with different arguments or input, define a separate test case for each invocation.

A documented family-conformance exception may group multiple related functions when they intentionally implement the same branch contract and the test verifies that branch consistently across the whole family. Keep conversion rules, type-specific behavior, and unrelated branches out of such a grouped case.

## Fixtures

Build only the state required by the behavior under test. Prefer small explicit fixtures over broad shared fixtures that hide causality.

## Scenario names

Test names communicate precondition, action, and expected result in domain language. Framework mechanics belong in the body, not in the name or human report.

When test cases are numbered, include the case number in the executable test title so runtime output maps back to the design. Prefer numbering within a stable scope such as a function and format the title as `<scope> <number>` so adding a case does not renumber unrelated tests. Separate the scope and number with a space, never a hyphen. Hierarchical numbers such as `<scope> 1-1` are acceptable only when the design flow is split into matching top-level groups. Preserve any framework-required title prefix.

## Type integrity

Tests are consumers of the production contract. Do not weaken types, bypass constructors, or suppress errors merely because code is under test.

## Concrete implementation skills

- [`js-test`](../js-test/SKILL.md) — tests executable through Vite+ and Vitest.
- [`mbt-test`](../mbt-test/SKILL.md) — tests executable through repository Vite+ tasks or `moon test`.

## Concrete design flow

- [`share-test-design-flow`](../share-test-design-flow/SKILL.md) — concrete test cases, success-criterion coverage, manual and AI-driven verification, Mermaid flows, and reports for human review.
