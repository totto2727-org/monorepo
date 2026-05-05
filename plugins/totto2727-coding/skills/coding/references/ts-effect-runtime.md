# Effect Runtime & Layer Composition Patterns

Related skills: [ts-effect-layer](./ts-effect-layer.md), [ts-effect-hono](./ts-effect-hono.md)

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

- [runtime/server.ts](../../../../../js/app/saas-example/src/feature/runtime/server.ts) — Layer composition, ManagedRuntime, DisposableRuntime, environment selection
- [runtime/hono.ts](../../../../../js/app/saas-example/src/feature/runtime/hono.ts) — `await using` middleware integration
