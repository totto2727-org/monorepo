---
name: effect-runtime
user-invocable: false
description: >-
  Effect Layer composition and ManagedRuntime patterns for this monorepo.
  Use when composing multiple layers into a runtime, resolving dependencies,
  or creating disposable runtimes for request-scoped lifecycle.
  Common triggers: "compose layers", "create runtime", "ManagedRuntime",
  "Layer.provideMerge", "Layer.provide", "DisposableRuntime", "await using runtime".
  Do NOT use for: defining individual services/layers (use effect-layer), or Hono handler patterns (use effect-hono).
---

# Effect Runtime & Layer Composition Patterns

Related skills: [effect-layer](../effect-layer/SKILL.md), [effect-hono](../effect-hono/SKILL.md)

## Layer Composition

| Method               | Role                                          | Why                                                                                                                       |
| -------------------- | --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `Layer.provideMerge` | Provide deps and expose both layers' services | Use when downstream consumers need access to both the provider and the dependent layer's services                         |
| `Layer.provide`      | Provide deps without exposing them            | Use for internal dependencies (logging, tracing, etc.) that should stay encapsulated and not leak to downstream consumers |

Start from the highest-level service and chain dependencies downward with `.pipe()`.

## ManagedRuntime

`ManagedRuntime.make(composedLayer)` creates a runtime that manages the lifecycle of all services.

## DisposableRuntime Pattern

Wrap `ManagedRuntime` with `Symbol.asyncDispose` for automatic cleanup. Use `await using` for request-scoped lifecycle.

## Environment-Based Runtime Selection

Provide separate runtime variants per environment (production, development, test) with different Logger configurations:

- Production: `Logger.consoleJson`
- Development: `Logger.consolePretty()`

## Reference Implementation

- [runtime/server.ts](../../js/app/saas-example/src/feature/runtime/server.ts) — Layer composition, ManagedRuntime, DisposableRuntime, environment selection
- [runtime/hono.ts](../../js/app/saas-example/src/feature/runtime/hono.ts) — `await using` middleware integration
