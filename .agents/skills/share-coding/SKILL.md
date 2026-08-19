---
name: share-coding
description: >-
  Language-independent coding philosophy for production code. Use before a
  language-specific coding skill when reasoning about types, effects, naming,
  boundaries, abstractions, readability, or change scope. Do not use for test
  implementation or language-specific APIs.
---

# Shared Coding Philosophy

> Content type: conceptual guidance shared by every language.

## Type safety

Express invariants in the type system whenever possible. Preserve paths, identifiers, commands, and domain payloads as specific structural values while they cross application layers. Keep generic JSON at serialization boundaries, and convert structural values to text only when an external protocol or display requires it.

## Single-value invariants

When a value must satisfy a condition independently of other values, consider representing that condition with a dedicated type. Validate and normalize raw input in the type's constructor or an equivalent factory, then pass the validated value through internal layers. Examples include an integer constrained to a fixed range and a path that must always be absolute. Do not repeat the same validation in each function that consumes the value; scattered checks reduce readability and make omissions likely.

Keep rules that describe a relationship between multiple values in the function or domain policy that owns that relationship. Do not force a contextual relationship into a type that represents only one value.

## Collection invariants

Do not construct a unique array with manual `contains`, `filter`, `fold`, or a local deduplication helper. When uniqueness is a domain invariant, store the values in a collection whose type guarantees uniqueness. Prefer the language's `Set` or a library set such as Effect `HashSet` for TypeScript and `@immut/hashset` or `@immut/sorted_set` for MoonBit. Convert the set to an array only at a consumer or API boundary that requires a sequence, such as serialization, presentation, interoperability, or a detached public snapshot.

Choose the collection by its observable semantics as well as uniqueness: insertion order versus comparison order, `Eq` and `Hash` identity, and mutable versus persistent updates. Do not replace an order-preserving representation with a sorted collection unless the domain contract explicitly requires sorted order.

When duplicate input is invalid, reject it at the boundary before collection construction can collapse it. Silently deduplicate only when deduplication is the explicit domain behavior.

If a private array exists only to stop callers from mutating it, prefer a readonly or persistent immutable collection. Keep a mutable private collection only when controlled mutation is part of the implementation's behavior.

## Strict boundary conversion

Keep untrusted or weakly typed values at the boundary where they enter or leave the program. Convert an external response into a wire model, convert the wire model into a validated domain model, convert the domain model into an outbound request model, and serialize only that request model. Apply the same rule to library values whose types are too broad to preserve domain invariants. Do not pass `any`, generic JSON, stringly typed identifiers, or parser contexts through internal application layers.

## Path form invariants

When internal code expects a specific path form, validate and normalize external raw paths or strings in a constructor or equivalent factory before passing them into internal layers. Represent relative paths such as `./...` or `../...`, absolute paths, and URI forms such as `file://...` with types that preserve their distinct invariants. Keep filesystem paths and URIs separate; validate a URI scheme before constructing its domain type. Do not repeat checks such as `is_absolute` in terminal functions.

For example, normalize a MoonBit `Path` before checking and storing its absolute-path invariant:

```mbt check
pub struct AbsolutePath {
  path : @path.Path
}

pub fn AbsolutePath::AbsolutePath(path : @path.Path) -> AbsolutePath raise {
  let normalized = path.normalize()
  guard normalized.is_absolute() else {
    fail("absolute path required")
  }
  { path: normalized }
}
```

## State models

Represent each valid state as a distinct variant whose payload contains exactly the data available in that state. Prefer an algebraic data type such as `Success(data) | Failure(error)` over independent flags and optional fields such as `{ error: boolean, data: unknown }`. A state transition should construct another valid variant rather than mutate unrelated fields into a temporarily inconsistent combination.

## Failures

Make failure visible in a function's type with `Result`, `Effect`, a typed error effect, or the closest language mechanism. Propagate failures to the application boundary by default. Catch only when the current layer can recover, must select a different behavior, or must translate an external failure into the boundary's error vocabulary. Define a custom error only when a caller needs to distinguish that failure or inspect structured context; do not create one merely to rename a generic failure.

## Side effects

Keep I/O, mutation, randomness, and time at program boundaries. Prefer pure functions in the core and make effects and failure modes visible in function signatures.

## Naming

Names state what callers can rely on, not how the implementation works. Reuse established domain vocabulary and avoid abbreviations unless they are standard in the domain.

## Testability

Inject dependencies at boundaries, keep branches understandable, and model failures explicitly. A unit that requires disproportionate setup usually has the wrong boundary or too many responsibilities.

## Change scope

Prefer small local changes and composable units. Extract a shared abstraction only after concrete use demonstrates a stable invariant or policy.

## Readability

Choose explicit control flow over compact cleverness. Comments explain non-obvious reasons and constraints; the code itself explains what it does.

## Just defaults

When a repository uses Just, make the default recipe display the available recipes with a recipe body that runs `@just --list`. Do not make the default recipe run checks, builds, tests, setup, or any other operational command.

## Consistency

Look for prior art in the same package before introducing a new pattern. Record the reason close to the decision when a deliberate divergence is necessary.

## Abstractions

Keep a wrapper only when it owns a real invariant, reusable policy, or typed boundary. A helper that merely renames one standard operation and has one call site adds indirection without preserving knowledge.

## Domain boundaries

Place discovery, resolution, and domain rules in the library that owns the concept. Entry points request resolved domain values rather than reimplementing filesystem walks, lookup rules, or naming policies.

## Concrete implementation skills

- [`js-coding`](../js-coding/SKILL.md) — TypeScript, Effect, Hono, Remix, and `@totto2727/fp`.
- [`mbt-coding`](../mbt-coding/SKILL.md) — MoonBit language and CLI implementation practices.

## Related skills

- [`share-test`](../share-test/SKILL.md), [`js-test`](../js-test/SKILL.md), and [`mbt-test`](../mbt-test/SKILL.md) — testing philosophy and executable tests.
- [`share-test-design-flow`](../share-test-design-flow/SKILL.md) — concrete test design and human-facing reporting.
- [`docs-moonbit`](../docs-moonbit/SKILL.md) and [`docs-components-build`](../docs-components-build/SKILL.md) — generated external specifications.
- [`share-artifact`](../share-artifact/SKILL.md) — durable README, AGENTS, and ADR authoring.
