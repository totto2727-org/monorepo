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

The backend must authorize API access with the resource-specific JWT access token
for `feed-platform-backend`. Keep rejecting OIDC ID tokens, including tokens that
have a valid signature but do not carry `token_use=access`.
