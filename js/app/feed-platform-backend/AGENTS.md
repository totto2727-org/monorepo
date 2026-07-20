# feed-platform-backend

## Authentication flow reference

- See `../identity-provider/docs/auth-flow.md` for the feed login flow, OAuth/OIDC compliance status, and security hardening checklist.

When editing backend auth code, check that document first. The current backend example depends on:

- `src/feature/auth/better-auth.ts` for Better Auth stateless session configuration shared with `feed-platform-web`.
- `src/feature/auth/middleware.ts` for Better Auth session validation through `auth.api.getSession({ headers })`.
- `src/worker/bff/worker.ts` for the protected `/api/v1/me` endpoint.

Do not reintroduce custom JWKS, bearer JWT, issuer, audience, or `token_use` validation unless `docs/auth-flow.md` is updated with a new architecture decision first.
