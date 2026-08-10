# Effect Runtime

> Document type: concrete TypeScript implementation guidance.

## ManagedRuntime

`ManagedRuntime.make(composedLayer)` creates a runtime that manages the lifecycle of all services.

## DisposableRuntime Pattern

Wrap `ManagedRuntime` with `Symbol.asyncDispose` for automatic cleanup. Use `await using` for request-scoped lifecycle.

## Environment-Based Runtime Selection

Provide separate runtime variants per environment (production, development, test) with different Logger configurations:

- Production: `Logger.consoleJson`
- Development: `Logger.consolePretty()`

## Reference Implementation

- [runtime/server.ts](../../../../../js/app/feed-platform-backend/src/feature/runtime/server.ts) — Layer composition, ManagedRuntime, DisposableRuntime, environment selection
- [runtime/hono.ts](../../../../../js/app/feed-platform-backend/src/feature/runtime/hono.ts) — `await using` middleware integration
