# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this package.

## Architecture

### Overview

`@totto2727/fp` is a TypeScript functional programming utility library published to NPM. It re-exports multiple FP libraries under a unified namespace and provides custom bridge modules between Effect and option-t ecosystems.

Type checker: vp check | Registry: NPM, JSR

### Module Categories

**Core Re-exports** — Thin wrappers that re-export external libraries:
`./type`, `./option-t`, `./temporal`, `./memo`, `./case`, `./di`

**Custom Modules** — Original implementations:

- `./duration` — Locale-aware duration formatting with caching
- `./effect/cuid` — CUID generator with Effect Schema branding
- `./effect/util` — Effect type helpers (`EffectFn`, `nonEmptyArrayOrNone`, `tap`)
- `./effect/option-t` — Bridge: option-t Result → Effect Exit
- `./option-t/effect` — Bridge: Effect Exit → option-t Result (dual function)
- `./option-t/safe-try` — Rust-like `?` operator for option-t Result using generators

**TypeScript Configs** — Shared tsconfig presets:
`./tsconfig/vite`

### Key Design Patterns

1. **Re-export strategy**: Most modules are `export * from "library"`. Custom logic only exists in bridge modules, CUID, and duration.
2. **Effect/option-t bridge**: Bidirectional conversion between Effect `Exit` and option-t `Result`.
3. **Branded types**: CUID uses Effect Schema branding for type-safe ID handling.
4. **Source publishing**: Published with raw `.ts` source files (no build step). Consumers must support TypeScript imports.
