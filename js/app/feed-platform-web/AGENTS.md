# feed-platform-web

## Authentication flow reference

- See `../identity-provider/docs/auth-flow.md` for the feed login flow,
  OAuth/OIDC compliance status, and security hardening checklist.

When editing feed auth code, check that document first. The current feed example
depends on:

- `app/feature/auth/oauth-client.ts` for authorization URL, PKCE, state, and
  nonce generation.
- `app/feature/auth/callback.ts` for code exchange, nonce verification, and
  session cookie creation plus server-side access/refresh token storage.
- `app/feature/auth/middleware.ts` for ID-token session verification.
- `app/feature/api/client.ts` for calls to `feed-platform-backend` using the
  server-side JWT access token, not the `feed-session` ID token.

The backend bearer token must be the resource-specific JWT access token obtained
with `resource=feed-platform-backend`. Keep `feed-session` scoped to web session
identity.
