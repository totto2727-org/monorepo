# @totto2727/fp Usage Guide

A TypeScript functional programming utility library that provides unified re-exports and bridge modules for Effect, option-t, and other FP libraries.

## Installation

`effect@beta` is a required peer dependency and must be installed alongside `@totto2727/fp`.

### Node.js

```bash
bun add jsr:@totto2727/fp effect@beta
```

### Deno

```bash
# Add to deno.json
deno add jsr:@totto2727/fp npm:effect@beta
```

```ts
// Direct import (without deno.json)
import { Result } from 'jsr:@totto2727/fp@<version>/option-t'
```

## Exported Paths

### Core Re-exports

Thin wrappers that re-export external libraries:

- `./case` — change-case (string case conversion)
- `./di` — velona (dependency injection)
- `./memo` — micro-memoize (memoization)
- `./option-t` — option-t (Result/Option types)
- `./temporal` — temporal-polyfill (Temporal API)
- `./type` — type-fest (utility types)

### Custom Modules

- `./duration` — Locale-aware duration formatting with caching
- `./error` — Shared domain error payload type (`TaggedErrorBaseType`) and `ErrorOptions.error` augmentation
- `./effect/cuid` — CUID generator with Effect Schema branding
- `./effect/util` — Effect type helpers (`EffectFn`, `nonEmptyArrayOrNone`, `tap`)
- `./effect/option-t` — Bridge: option-t Result → Effect Exit
- `./option-t/effect` — Bridge: Effect Exit → option-t Result (dual function)
- `./option-t/safe-try` — Rust-like `?` operator for option-t Result using generators

### TypeScript Configs

- `./tsconfig/vite` — Shared tsconfig preset for Vite projects

## Reference

- [Effect AI Guide](https://raw.githubusercontent.com/Effect-TS/effect-smol/refs/heads/main/LLMS.md)

## Error payload and propagation policy

Use `@totto2727/fp/error` as the canonical shape for domain error payloads. `TaggedErrorBaseType` is the only allowed base type for custom `Data.TaggedError` payloads.

```ts
import type { TaggedErrorBaseType } from '@totto2727/fp/error'

export class BackendError extends Data.TaggedError('BackendError')<TaggedErrorBaseType>() {}
```

Rules:

- Root/domain-boundary errors that are created from the current code path must include a human-authored `message`.
- Wrapping a caught error must pass the original caught value through unchanged as `error`; do not stringify, format, map, redact, or replace it.
- If a `catch` block only catches in order to wrap / rethrow, the only allowed payload transformation is `{ error }`.
- Do not use helpers like `formatError`, `formatCause`, `String(error)`, `error.message`, or fallback strings such as `'request failed'` for caught errors.
- If both context and a caught error are needed, use `{ message: '...', error }`: the message describes this boundary, and `error` preserves the original value.

Allowed:

```ts
catch (error) {
  return yield* Effect.fail(new BackendError({ error }))
}

return yield* Effect.fail(new BackendError({ message: 'missing session cookie' }))

catch (error) {
  return yield* Effect.fail(new BackendError({ message: 'backend request failed', error }))
}
```

Forbidden:

```ts
catch (error) {
  return yield* Effect.fail(new BackendError({ error: String(error) }))
}

catch (error) {
  return yield* Effect.fail(new BackendError({ message: error.message }))
}

const formatBackendFailure = (error: unknown) =>
  Predicate.isString(error) ? error : 'backend request failed'
```
