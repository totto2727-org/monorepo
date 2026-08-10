# Hono Sub-App

> Document type: concrete TypeScript implementation guidance.

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

- Sub-app: [app.tsx](../../../../../js/app/identity-provider/app/app.tsx)
- Worker integration: [worker.ts](../../../../../js/app/feed-platform-backend/src/worker/bff/worker.ts)
