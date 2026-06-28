# feed-platform-web

## Authentication flow reference

- See `../identity-provider/docs/auth-flow.md` for the feed login flow,
  OAuth/OIDC compliance status, and security hardening checklist.

When editing feed auth code, check that document first. The current feed example
depends on:

- `app/feature/auth/better-auth.ts` for Better Auth `genericOAuth` and stateless
  session configuration.
- `app/feature/auth/middleware.ts` for Better Auth session validation through
  `auth.api.getSession({ headers })`.
- `app/feature/api/client.ts` for calls to `feed-platform-backend` using the
  Better Auth session cookie.

Do not add feed-specific OAuth state, PKCE, nonce, refresh-token, access-token,
or JWT verification code unless `docs/auth-flow.md` is updated with a new
architecture decision first.
