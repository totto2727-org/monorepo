---
name: totto2727-fp
description: >-
  How to install and use @totto2727/fp package. Use when adding @totto2727/fp
  as a dependency or importing its modules.
---

# @totto2727/fp Usage Guide

A TypeScript functional programming utility library that provides unified re-exports and bridge modules for Effect, option-t, and other FP libraries.

## Installation

`effect@beta` is a required peer dependency and must be installed alongside `@totto2727/fp`.

### Node.js

```bash
pnpm i jsr:@totto2727/fp effect@beta
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
- `./effect/cuid` — CUID generator with Effect Schema branding
- `./effect/util` — Effect type helpers (`EffectFn`, `nonEmptyArrayOrNone`, `tap`)
- `./effect/option-t` — Bridge: option-t Result → Effect Exit
- `./option-t/effect` — Bridge: Effect Exit → option-t Result (dual function)
- `./option-t/safe-try` — Rust-like `?` operator for option-t Result using generators

### TypeScript Configs

- `./tsconfig/vite` — Shared tsconfig preset for Vite projects

## Reference

- [Effect AI Guide](https://raw.githubusercontent.com/Effect-TS/effect-smol/refs/heads/main/LLMS.md)
