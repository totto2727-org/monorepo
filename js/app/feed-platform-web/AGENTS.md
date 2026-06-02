# feed-platform-web

## Authentication flow reference

- See `../identity-provider/docs/auth-flow.md` for the feed login flow,
  OAuth/OIDC compliance status, and security hardening checklist.

When editing feed auth code, check that document first. The current feed example
depends on:

- `app/feature/auth/oauth-client.ts` for authorization URL, PKCE, state, and
  nonce generation.
- `app/feature/auth/callback.ts` for code exchange, nonce verification, and
  session cookie creation.
- `app/feature/auth/middleware.ts` for ID-token session verification.
- `app/feature/api/client.ts` for calls to `feed-platform-backend`.

Production follow-up from the IdP document: use a proper API access token or
introspection flow instead of using an ID token as the backend bearer token.
