# TOT-23 platform auth current design

## Scope

This note records the current platform auth design after the shared auth helper
work. Historical ADRs under `docs/adr/` remain unchanged; this file is the
worktree-level progress and correction note for the latest codebase state.

## Current state

- Shared application auth lives in `js/package/auth/`. Older docs and review
  notes may still call this package `auth-helper`, but the current workspace
  package name is `auth`.
- `createBetterAuthSetupMiddleware` in
  `js/package/auth/src/better-auth.ts` owns Better Auth session lookup and
  decoding. It resolves the Better Auth service from the Effect runtime layer,
  reads the session from request headers, maps the Better Auth user into the
  shared app user shape, and stores only `user` in Hono request variables.
- `requireAuthMiddleware` in `js/package/auth/src/require-auth.ts` owns the
  shared require-auth branch. Apps pass only their unauthenticated policy:
  redirects for browser apps and a JSON 401 response for the backend.
- The shared app user shape is `User` in `js/package/auth/src/type.ts` and uses
  `id` plus `email`. This follows Better Auth's native `user.id` field.
- JWT and OIDC payload boundaries keep protocol names. `AppJWTPayload` in
  `js/package/auth/src/jwt-payload.ts` uses `sub`, and translation between
  `sub` and application `id` belongs at that protocol boundary only.
- Shared setup no longer takes app-specific `mapUser` callbacks. If a route or
  protocol needs another shape, it should transform at that boundary rather
  than diverging the shared middleware contract.
- Auth services are not stored in `ctx.var.auth`. Long-lived services stay in
  the Effect runtime/service layer; request context carries request-scoped
  values such as `user`.
- Handlers behind `requireAuthMiddleware` should trust the middleware contract
  instead of repeating defensive `null` checks. If TypeScript cannot see the
  guarantee, fix the shared helper or Hono context typing.

## App boundaries

- `js/app/feed-platform-web/app/feature/auth/middleware.ts` wires
  `createBetterAuthSetupMiddleware` with `BetterAuth.Service` and uses
  `requireAuthMiddleware` to set the return-to cookie and redirect to
  `/app/login`.
- `js/app/feed-platform-backend/src/feature/auth/middleware.ts` wires the same
  setup helper and uses `requireAuthMiddleware` to return a JSON 401 with a
  `WWW-Authenticate` header.
- `js/app/identity-provider/app/feature/auth/middleware.ts` wires the same
  setup helper and uses app-specific redirect policies for normal auth and
  login-session auth.

## Progress notes

- The current codebase has already incorporated the core shared-helper review
  direction: middleware plumbing is centralized, app middleware expresses
  unauthenticated policy, and the app user shape uses `id`.
- The package rename from `auth-helper` to `auth` is now part of the current
  baseline and should be reflected in new docs and coding guidance.
- Remaining future auth design work should treat historical ADRs as context and
  place new implementation-state corrections in worktree or roadmap progress
  notes rather than rewriting adopted ADRs.
