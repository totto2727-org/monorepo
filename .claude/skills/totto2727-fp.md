---
description: Guide for working with the @totto2727/fp package — a TypeScript functional programming utility library that re-exports and bridges Effect, option-t, and other FP libraries. Use when modifying, extending, or consuming @totto2727/fp modules.
globs:
  - 'js/package/fp/**/*'
---

# @totto2727/fp

Unified TypeScript functional programming utility library. Re-exports multiple FP libraries under a single namespace and provides custom bridge modules between Effect and option-t ecosystems.

## Module Map

### Core Re-exports

| Export Path  | Source Library    | Description                                     |
| ------------ | ----------------- | ----------------------------------------------- |
| `./effect`   | effect            | Full Effect library re-export                   |
| `./type`     | type-fest         | TypeScript utility types                        |
| `./option-t` | option-t          | Nullable, Maybe, Undefinable, Result namespaces |
| `./temporal` | temporal-polyfill | Temporal API polyfill                           |
| `./memo`     | moize             | Memoization                                     |
| `./case`     | change-case       | String case conversion                          |
| `./di`       | velona            | Dependency injection                            |

### Custom Modules

| Export Path           | Description                                                                 |
| --------------------- | --------------------------------------------------------------------------- |
| `./duration`          | Locale-aware duration formatting with caching                               |
| `./effect/cuid`       | CUID generator with Effect Schema validation and branded types              |
| `./effect/util`       | Effect utility types and helpers (`EffectFn`, `nonEmptyArrayOrNone`, `tap`) |
| `./effect/option-t`   | Bridge: option-t `Result` → Effect `Exit`                                   |
| `./option-t/effect`   | Bridge: Effect `Exit` → option-t `Result` (dual function)                   |
| `./option-t/safe-try` | Rust-like `?` operator for option-t Result using generators                 |
| `./effect/test/bun`   | Bun test wrapper for Effect (`it.effect()`, `it.scoped()`)                  |

### Effect Platform Modules

| Export Path                     | Source                                    |
| ------------------------------- | ----------------------------------------- |
| `./effect/platform`             | @effect/platform                          |
| `./effect/platform/browser`     | @effect/platform-browser                  |
| `./effect/platform/bun`         | @effect/platform-bun                      |
| `./effect/platform/node`        | @effect/platform-node                     |
| `./effect/platform/node-share`  | @effect/platform-node-shared (namespaced) |
| `./effect/cli`                  | @effect/cli                               |
| `./effect/experimental/machine` | @effect/experimental Machine module       |
| `./effect/test/vitest`          | @effect/vitest                            |

### TypeScript Config Exports

Paths: `./tsconfig/base`, `./tsconfig/node22`, `./tsconfig/node24`, `./tsconfig/bun`, `./tsconfig/lib`, `./tsconfig/react`, `./tsconfig/react-router`, `./tsconfig/expo`, `./tsconfig/tanstack-start`

## Key Patterns

- **Re-export strategy**: Most modules are thin re-exports (`export * from "library"`). Custom logic exists only in bridge modules, CUID, duration, and test helpers.
- **Effect/option-t bridge**: Bidirectional conversion between Effect `Exit` and option-t `Result` via `./effect/option-t` and `./option-t/effect`.
- **Platform separation**: Effect platform modules are split by runtime (browser, bun, node) to enable tree-shaking.
- **Branded types**: CUID uses Effect Schema branding for type-safe ID handling.

## Dependencies Reference

### Effect Ecosystem

- **effect** — Core Effect library for typed functional programming
  - llms.txt: https://effect.website/llms.txt
  - llms-full.txt: https://effect.website/llms-full.txt
  - llms-small.txt: https://effect.website/llms-small.txt
- **@effect/cli** — CLI argument parsing for Effect
- **@effect/platform** — Platform abstraction layer for Effect
- **@effect/platform-browser** — Browser platform implementation
- **@effect/platform-bun** — Bun runtime platform implementation
- **@effect/platform-node** — Node.js platform implementation
- **@effect/platform-node-shared** — Shared Node.js utilities
- **@effect/experimental** — Experimental Effect features (Machine module)
- **@effect/vitest** — Vitest integration for Effect testing

### Utility Libraries

| Package                       | Description                            | GitHub                                            |
| ----------------------------- | -------------------------------------- | ------------------------------------------------- |
| option-t                      | Option/Result types inspired by Rust   | https://github.com/option-t/option-t              |
| type-fest                     | TypeScript utility types collection    | https://github.com/sindresorhus/type-fest         |
| moize                         | High-performance memoization           | https://github.com/planttheidea/moize             |
| change-case                   | String case conversion utilities       | https://github.com/blakeembrey/change-case        |
| velona                        | Dependency injection for TypeScript    | https://github.com/frouriojs/velona               |
| temporal-polyfill             | TC39 Temporal API polyfill             | https://github.com/fullcalendar/temporal-polyfill |
| @formatjs/intl-durationformat | Intl.DurationFormat polyfill           | https://github.com/formatjs/formatjs              |
| @noble/hashes                 | Audited cryptographic hash functions   | https://github.com/paulmillr/noble-hashes         |
| base-x                        | Base encoding/decoding                 | https://github.com/cryptocoinjs/base-x            |
| bignumber.js                  | Arbitrary-precision decimal arithmetic | https://github.com/MikeMcl/bignumber.js           |
| seedrandom                    | Seeded pseudo-random number generator  | https://github.com/davidbau/seedrandom            |
