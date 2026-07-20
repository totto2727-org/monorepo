# identity-provider

## Project documentation

- Auth flow, OAuth/OIDC compliance, and security hardening notes:
  `docs/auth-flow.md`

Use that document as the source of truth when changing IdP login, consent, OAuth token issuance, OIDC ID token/JWKS behavior, or local feed-platform auth integration.

## Auth integration notes

- The feed example in `docs/auth-flow.md` covers `feed-platform-web` as the OAuth client and `feed-platform-backend` as the JWT-protected BFF.
- Keep Better Auth OAuth model mappings in `app/feature/auth/better-auth.ts` aligned with `db/schema.hcl`.
- Local seeded client secrets are development-only. Do not copy the raw-secret `storeClientSecret` behavior into production configuration without the remediation described in `docs/auth-flow.md`.
