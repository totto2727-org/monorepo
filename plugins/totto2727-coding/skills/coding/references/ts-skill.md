# TypeScript Conventions Index

This file is the Tier-2 index for TypeScript coding conventions inside the `coding` skill. Each in-plugin detail file lives next to this file under `coding/references/`. External skill references list related skills owned outside this plugin; resolve them by name via Claude Code's auto-discovery (no Markdown link, because their on-disk path is unstable).

## In-plugin detail files

- [`ts-effect-layer.md`](./ts-effect-layer.md) — Effect Layer / Service definition patterns. Use when defining services or DI with `Layer.effect` / `Layer.sync` / `Layer.succeed` / `Layer.scoped` and `ServiceMap.Service` tags.
- [`ts-effect-runtime.md`](./ts-effect-runtime.md) — Layer composition + ManagedRuntime. Use when wiring runtimes, composing layers with `Layer.provideMerge` / `Layer.provide`, or creating `DisposableRuntime` for request-scoped lifecycle.
- [`ts-effect-hono.md`](./ts-effect-hono.md) — Hono middleware + route handler patterns with Effect. Use when writing HTTP handlers / sub-apps, defining `Data.TaggedError` HTTP errors, or wiring `factory.createMiddleware` against an Effect runtime.
- [`ts-totto2727-fp.md`](./ts-totto2727-fp.md) — `@totto2727/fp` package usage. Use when adding `@totto2727/fp` as a dependency or importing its modules (Effect / option-t bridges, FP utilities).

## External skill references

- `vite-plus` — Vite+ unified toolchain (Vite / Vitest / monorepo orchestration). Use for `vp run` / `vp test` / build pipelines.
- `remix` — Remix 3 application development (routes / controllers / middleware / hydration / etc.). Use when building or reviewing Remix apps.
