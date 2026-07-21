# Hono Handler Boundary

> Document type: concrete TypeScript implementation guidance.

## Effect Handler Pattern

Middleware and route handlers share the same structure: the Hono boundary is the only place that converts an `Effect` into a `Promise<Response | void>`.

1. Define the whole request workflow as one `Effect.gen`
2. Define `programWithCatch` to handle errors separately when the endpoint has typed recoverable errors
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
  request parsing, service lookup, DB/API calls, cookie mutation, redirects, JSX server-side rendering, and response construction all belong inside the same `Effect.gen`.
- Do not write `async (c) => { ... await c.var.runtime.runPromise(partialEffect); ... }`.
  That splits the workflow and hides side effects outside Effect.
- Do not create several nested or sequential `Effect.gen` / `runPromise` blocks inside one Hono handler. Compose effects inside the single top-level program.
- Do not `Effect.provide(...)` route-local application layers inside handlers.
  Services (`BackendClient`, DB, `HttpClient`, etc.) must be provided by the request runtime assembled in `runtime/server.ts`. Route-level `provide` is only for genuinely local, test-only, or explicitly scoped values.
- Always separate `program` and `programWithCatch` when typed error recovery is needed; otherwise a direct `c.var.runtime.runPromise(Effect.gen(...))` is acceptable.
- Always `Effect.tapError` before `catchTags` for logging.
- Middleware: wrap `next()` with `Effect.tryPromise(next)` or `Effect.promise(() => next())` inside the same program.

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

Service implementations may require `HttpClient.HttpClient`, but they must not provide `FetchHttpClient.layer` internally. The request runtime provides it.
