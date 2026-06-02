# feed-platform-backend

## Authentication flow reference

- See `../identity-provider/docs/auth-flow.md` for the feed login flow,
  OAuth/OIDC compliance status, and security hardening checklist.

When editing backend auth code, check that document first. The current backend
example depends on:

- `src/feature/auth/jwt.ts` for IdP JWKS verification, expected issuer, expected
  audience, and required claims.
- `src/feature/auth/middleware.ts` for `Authorization: Bearer ...` enforcement.
- `src/worker/bff/worker.ts` for the protected `/api/v1/me` endpoint.

Production follow-up from the IdP document: the backend should authorize API
access with a proper access token or introspection result, not an OIDC ID token.
