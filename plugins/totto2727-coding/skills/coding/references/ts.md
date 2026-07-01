# TypeScript Conventions Index

This file is the Tier-2 index for TypeScript coding conventions inside the `coding` skill. Each in-plugin detail file lives under `coding/references/ts/`. External skill references list related skills owned outside this plugin; resolve them by name via Claude Code's auto-discovery (no Markdown link, because their on-disk path is unstable).

## In-plugin detail files

- [`effect-layer.md`](./ts/effect-layer.md) — Effect Layer / Service definition patterns. Use when defining services or DI with `Layer.effect` / `Layer.sync` / `Layer.succeed` / `Layer.scoped` and `ServiceMap.Service` tags.
- [`effect-runtime.md`](./ts/effect-runtime.md) — Layer composition + ManagedRuntime. Use when wiring runtimes, composing layers with `Layer.provideMerge` / `Layer.provide`, or creating `DisposableRuntime` for request-scoped lifecycle.
- [`effect-latest-api.md`](./ts/effect-latest-api.md) — Raw upstream Effect Smol `MIGRATION.md` and `packages/effect/SCHEMA.md` content. Use when checking latest Effect v4 API names, migration notes, package organization, or Schema API details.
- [`effect-hono.md`](./ts/effect-hono.md) — Hono middleware + route handler patterns with Effect. Use when writing HTTP handlers / sub-apps, defining `Data.TaggedError` HTTP errors, or wiring `factory.createMiddleware` against an Effect runtime.
- [`effect-remix.md`](./ts/effect-remix.md) — Remix `clientEntry` / `on(...)` client event patterns with Effect. Use when writing browser event handlers that perform HTTP calls, state mutation, WebAuthn, or navigation.
- [`totto2727-fp.md`](./ts/totto2727-fp.md) — `@totto2727/fp` package usage. Use when adding `@totto2727/fp` as a dependency, importing its modules (Effect / option-t bridges, FP utilities), or defining domain error payloads / caught-error propagation.

## External skill references

- `vite-plus` — Vite+ unified toolchain (Vite / Vitest / monorepo orchestration). Use for `vp run` / `vp test` / build pipelines.
- `remix` — Remix 3 application development (routes / controllers / middleware / hydration / etc.). Use when building or reviewing Remix apps.
