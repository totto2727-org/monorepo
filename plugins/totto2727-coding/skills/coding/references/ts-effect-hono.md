# Effect + Hono Integration Patterns

Related skills: [ts-effect-layer](./ts-effect-layer.md), [ts-effect-runtime](./ts-effect-runtime.md)

## Effect Handler Pattern

Middleware and route handlers share the same structure: the Hono boundary is
the only place that converts an `Effect` into a `Promise<Response | void>`.

1. Define the whole request workflow as one `Effect.gen`
2. Define `programWithCatch` to handle errors separately when the endpoint has
   typed recoverable errors
3. Execute once with `c.var.runtime.runPromise(programWithCatch)`

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

- Each Hono endpoint / middleware must contain **0 or 1 runtime execution**:
  - 0 when it is purely synchronous Hono code (`c.json`, simple redirects, etc.)
  - 1 when it performs any Effectful work
- The single `runPromise` must wrap the **entire** endpoint / middleware workflow:
  request parsing, service lookup, DB/API calls, cookie mutation, redirects,
  JSX server-side rendering, and response construction all belong inside the
  same `Effect.gen`.
- Do not write `async (c) => { ... await c.var.runtime.runPromise(partialEffect); ... }`.
  That splits the workflow and hides side effects outside Effect.
- Do not create several nested or sequential `Effect.gen` / `runPromise` blocks
  inside one Hono handler. Compose effects inside the single top-level program.
- Do not `Effect.provide(...)` route-local application layers inside handlers.
  Services (`BackendClient`, DB, `HttpClient`, etc.) must be provided by the
  request runtime assembled in `runtime/server.ts`. Route-level `provide` is
  only for genuinely local, test-only, or explicitly scoped values.
- Always separate `program` and `programWithCatch` when typed error recovery is
  needed; otherwise a direct `c.var.runtime.runPromise(Effect.gen(...))` is
  acceptable.
- Always `Effect.tapError` before `catchTags` for logging.
- Middleware: wrap `next()` with `Effect.tryPromise(next)` or
  `Effect.promise(() => next())` inside the same program.

## Endpoint Boundary Shape

Preferred route handler shape:

```typescript
app.get('/dashboard', (c) =>
  // oxlint-disable-next-line rules/no-effect-runtime-run -- HTTP handler boundary executes the whole request workflow once.
  c.var.runtime.runPromise(
    Effect.gen(function* () {
      const service = yield* SomeService
      const data = yield* service.load(c.req.param('id'))

      setCookie(c, 'session', data.sessionId, { httpOnly: true, path: '/' })

      return c.render(
        <Document>
          <h1>{data.title}</h1>
        </Document>,
      )
    }),
  ),
)
```

Forbidden partial boundary shape:

```typescript
app.get('/dashboard', async (c) => {
  const data = await c.var.runtime.runPromise(loadDataOnly)

  // Cookie mutation and rendering are outside Effect: forbidden.
  setCookie(c, 'session', data.sessionId, { httpOnly: true, path: '/' })
  return c.render(<Document>{data.title}</Document>)
})
```

### Dependency provision

Request-runtime dependencies are wired once in `runtime/server.ts`:

```typescript
const runtime = ManagedRuntime.make(
  App.layer.pipe(
    Layer.provideMerge(Api.liveLayer),
    Layer.provideMerge(DB.remoteLayer),
    Layer.provideMerge(FetchHttpClient.layer),
    Layer.provide(Env.makeLayer(env)),
  ),
)
```

Handlers consume services; they do not provide them:

```typescript
app.get('/me', (c) =>
  c.var.runtime.runPromise(
    Effect.gen(function* () {
      const client = yield* BackendClient
      const user = yield* client.callMe(c.req.header('authorization') ?? null)
      return c.json(user)
    }),
  ),
)
```

Service implementations may require `HttpClient.HttpClient`, but they must not
provide `FetchHttpClient.layer` internally. The request runtime provides it.

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

Middleware-specific state belongs in the shared Hono environment type, not in
individual route files. Define variables in the runtime/context boundary:

```typescript
// feature/runtime/hono.ts
export interface Variables {
  readonly runtime: Runtime.Runtime
  readonly user: AuthUser | null
}
```

```typescript
// feature/share/lib/hono/context.ts
export interface Env {
  Bindings: Bindings
  Variables: Variables
}
```

Route files should import this `Env`; they must not locally widen
`Variables` with endpoint-specific intersections such as
`Variables & { user: AuthUser | null }`.

### Examples

- [auth/middleware.ts](../../../../../js/app/saas-example/src/feature/auth/middleware.ts)

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

- Sub-app: [auth/app.ts](../../../../../js/app/saas-example/src/feature/auth/app.ts)
- Parent integration: [entry.hono.ts](../../../../../js/app/saas-example/src/entry.hono.ts)

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

- [http/error.ts](../../../../../js/app/saas-example/src/feature/http/error.ts)

## Middleware Order

1. `contextStorage()` — async-local context access (must be first)
2. Runtime middleware — injects Effect runtime into `c.var.runtime`
3. Logging / other Hono middleware
4. Route-specific sub-apps and middleware

### Examples

- [entry.hono.ts](../../../../../js/app/saas-example/src/entry.hono.ts)
- Context/Factory setup: [context.ts](../../../../../js/app/saas-example/src/feature/share/lib/hono/context.ts), [factory.ts](../../../../../js/app/saas-example/src/feature/share/lib/hono/factory.ts)
