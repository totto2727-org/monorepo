---
name: js-coding
description: >-
  TypeScript implementation guidance for Effect, Hono, Remix, browser IME input, typed boundaries, and collections. Use when implementing or reviewing these concerns.
---

# TypeScript Coding Index

All references below are concrete TypeScript implementation guidance or an explicit upstream source index. Use [`share-coding`](../share-coding/SKILL.md) for language-independent design decisions.
Read only the relevant reference; already available principles need not be reloaded.

## Type boundaries

- [`boundary-conversion.md`](references/boundary-conversion.md) — decode weak external values into wire models, validate domain models, and encode request models.
- [`state-modeling.md`](references/state-modeling.md) — discriminated unions, exhaustive transitions, and impossible-state elimination.
- [`error-handling.md`](references/error-handling.md) — typed Effect failures, propagation, recovery, and error translation.
- [`collections.md`](references/collections.md) — unique collection choices and boundary conversion.

## Effect

- [`effect-layer.md`](references/effect-layer.md) — service tags and Layer definitions.
- [`effect-layer-composition.md`](references/effect-layer-composition.md) — dependency provision and Layer exposure.
- [`effect-runtime.md`](references/effect-runtime.md) — managed runtimes, disposal, and environment selection.
- [`effect-sources.md`](references/effect-sources.md) — live upstream migration and Schema sources.

## Hono

- [`hono-handler.md`](references/hono-handler.md) — endpoint Effect boundaries and dependency provision.
- [`hono-middleware.md`](references/hono-middleware.md) — middleware context and authentication boundaries.
- [`hono-subapp.md`](references/hono-subapp.md) — sub-application construction.
- [`hono-errors.md`](references/hono-errors.md) — HTTP error types.
- [`hono-ordering.md`](references/hono-ordering.md) — middleware registration order.

## Browser input

- [`ime-safe-enter-submit.md`](references/ime-safe-enter-submit.md) — read when adding or changing custom Enter-to-submit behavior, or fixing premature submission during IME conversion; routes to official Modern Web Guidance.

## Remix

- [`remix-client-events.md`](references/remix-client-events.md) — client event Effect boundaries.

## @totto2727/fp

- [`totto2727-fp.md`](references/totto2727-fp.md) — package-specific reference index.

## Related skills

- `vite-plus` — repository toolchain and build orchestration.
- `remix` — Remix application structure and framework conventions.
- [`js-test`](../js-test/SKILL.md) — tests executable through Vite+ and Vitest.
