---
name: effect-hono
user-invocable: false
description: >-
  Hono middleware and route handler patterns using Effect for this monorepo.
  Use when writing Hono middleware with Effect.gen, creating route handlers
  that access Effect services, defining HTTP error classes with Data.TaggedError,
  or setting up Hono context types with Effect runtime.
  Common triggers: "create middleware", "Hono handler with Effect",
  "HTTP error", "factory.createMiddleware", "catchTags", "runPromise".
  Do NOT use for: Layer/Service definition (use effect-layer), or layer composition/runtime setup (use effect-runtime).
---

# Effect + Hono Integration Patterns

Related skills: [effect-layer](../effect-layer/SKILL.md), [effect-runtime](../effect-runtime/SKILL.md)

## Effect Handler Pattern

Middleware and route handlers share the same structure:

1. Define `program` with `Effect.gen`
2. Define `programWithCatch` to handle errors separately
3. Execute with `c.var.runtime.runPromise(programWithCatch)`

```typescript
const program = Effect.gen(function* () {
  // ... business logic ...
})

const programWithCatch = program.pipe(
  Effect.tapError((e) => Effect.logError(e)),
  Effect.catchTags({
    UnknownError: () => new HttpError.InternalServerError().makeResponseEffect(),
  }),
)

return c.var.runtime.runPromise(programWithCatch)
```

### Key Rules

- Always separate `program` and `programWithCatch`
- Always `Effect.tapError` before `catchTags` for logging
- Middleware: wrap `next()` with `Effect.tryPromise(next)`

## Middleware

```typescript
export const myMiddleware = factory.createMiddleware((c, next) => {
  const program = Effect.gen(function* () {
    // ...
    yield* Effect.tryPromise(next)
  })
  // ... programWithCatch + runPromise
})
```

### Examples

- [auth/middleware.ts](../../js/app/saas-example/src/feature/auth/middleware.ts)

## Sub-App Pattern

Sub-app is composed of: app (from factory) + handlers (same pattern as middleware), then integrated into the parent app via `.route()`.

```typescript
// feature/{name}/app.ts

// 1. Create sub-app from factory
export const app = factory.createApp()
  .get('/path', (c) => {
    const program = Effect.gen(function* () {
      const service = yield* SomeService.Service
      return c.json({ data: ... })
    })
    // ... programWithCatch + runPromise
  })

// 2. Integrate into parent app via .route()
// entry.hono.ts
app.route('/api/v1/{name}', SubApp.app)
```

### Examples

- Sub-app: [auth/app.ts](../../js/app/saas-example/src/feature/auth/app.ts)
- Parent integration: [entry.hono.ts](../../js/app/saas-example/src/entry.hono.ts)

## HTTP Error Template

Define HTTP errors as `Data.TaggedError` with `makeResponseEffect`:

```typescript
export class {Name} extends Data.TaggedError('http/error/{Name}') {
  makeResponseEffect() {
    return Effect.succeed(Context.get().json({ error: '{Display Name}' }, {statusCode}))
  }
}
```

Tag format: `http/error/{ErrorName}`

### Examples

- [http/error.ts](../../js/app/saas-example/src/feature/http/error.ts)

## Middleware Order

1. `contextStorage()` — async-local context access (must be first)
2. Runtime middleware — injects Effect runtime into `c.var.runtime`
3. Logging / other Hono middleware
4. Route-specific sub-apps and middleware

### Examples

- [entry.hono.ts](../../js/app/saas-example/src/entry.hono.ts)
- Context/Factory setup: [context.ts](../../js/app/saas-example/src/feature/share/lib/hono/context.ts), [factory.ts](../../js/app/saas-example/src/feature/share/lib/hono/factory.ts)
