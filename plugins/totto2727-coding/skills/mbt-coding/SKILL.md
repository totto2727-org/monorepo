---
name: mbt-coding
description: >-
  Index of concrete MoonBit production-code practices for this repository.
  Apply share-coding first for language-independent principles. Use mbt-test
  for executable tests. Load only the reference matching the implementation
  concern.
---

# MoonBit Coding Index

All references below are concrete MoonBit implementation guidance. Conceptual guidance belongs to [`share-coding`](../share-coding/SKILL.md).

## Type boundaries

- [`boundary-conversion.md`](references/boundary-conversion.md) — decode boundary values, validate domain models, and encode request models.
- [`state-modeling.md`](references/state-modeling.md) — enum state variants and exhaustive transitions.

## Language conventions

- [`style.md`](references/style.md) — documentation, identifiers, callbacks, and ignored results.
- [`constructors.md`](references/constructors.md) — canonical constructors and factories.
- [`updates.md`](references/updates.md) — immutable value updates and mutable builder updates.
- [`sequences.md`](references/sequences.md) — Array and Iter return shapes.
- [`variants.md`](references/variants.md) — enum representation and typed extraction.
- [`traits.md`](references/traits.md) — trait definitions and implementations.
- [`pattern-matching.md`](references/pattern-matching.md) — patterns and guards.

## Structured values

- [`paths.md`](references/paths.md) — preserve `Path` values and join path segments structurally.
- [`json.md`](references/json.md) — confine `Json` to serialization boundaries and serialize request models with `ToJson`.

## Failures

- [`errors.md`](references/errors.md) — typed failures, effect signatures, recovery, and repository policy.

## Collections

- [`arrays.md`](references/arrays.md) — construction, alias safety, mutation exceptions, and review criteria.

## Execution

- [`concurrency.md`](references/concurrency.md) — structured concurrent work.
- [`cli-application.md`](references/cli-application.md) — index of Admiral-based CLI practices.

## Code analysis

- [`code-analysis.md`](references/code-analysis.md) — semantic navigation with `moon ide` before code changes.

## Related skills

- [`docs-moonbit`](../docs-moonbit/SKILL.md) — generated MoonBit language reference.
- [`mbt-test`](../mbt-test/SKILL.md) — tests executable through repository Vite+ tasks or `moon test`.
