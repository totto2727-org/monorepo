# Hono Middleware

> Document type: concrete TypeScript implementation guidance.

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

Middleware-specific state belongs in the shared Hono environment type, not in individual route files. Define variables in the runtime/context boundary:

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

Route files should import this `Env`; they must not locally widen `Variables` with endpoint-specific intersections such as `Variables & { user: AuthUser | null }`.

### Auth middleware boundaries

Keep route and app middleware focused on policy, not auth plumbing. Shared auth helpers should own session lookup, user decoding, and pass-through vs unauthenticated branching. App middleware should provide only app-specific responses such as redirects, return-to cookies, or JSON 401 responses.

Platform-specific auth design notes live directly in the ms-02 milestone's current implementation section: [`docs/roadmap/feed-platform/milestones/ms-02-auth-passkey-magiclink.md`](../../../../../docs/roadmap/feed-platform/milestones/ms-02-auth-passkey-magiclink.md#current-implementation-design). Historical context remains in the auth provider and cross-app session ADRs: [`docs/adr/2026-05-24-feed-platform-auth-provider.md`](../../../../../docs/adr/2026-05-24-feed-platform-auth-provider.md) and [`docs/adr/2026-05-24-feed-platform-cross-app-session-strategy.md`](../../../../../docs/adr/2026-05-24-feed-platform-cross-app-session-strategy.md).

- Prefer source-native user fields in application auth types. Better Auth uses `user.id`, so app-level shared users should expose `id`; reserve `sub` for JWT/OIDC payload types and translate only at that protocol boundary.
- Do not add app-specific `mapUser` callbacks to shared setup middleware for the normal application user. Divergent UI or protocol shapes should be mapped at the boundary that needs them.
- Do not store long-lived services such as `auth` in `ctx.var`. Services belong in the runtime/service layer; request context should contain request-scoped values such as the resolved `user`.
- Handlers behind require-auth middleware should trust the middleware contract and avoid repeating `null` checks for `ctx.var.user`. If the type does not express the guarantee, fix the shared helper or Hono context typing instead of weakening every handler.

### Examples

- [auth/middleware.ts](../../../../../js/app/feed-platform-backend/src/feature/auth/middleware.ts)
