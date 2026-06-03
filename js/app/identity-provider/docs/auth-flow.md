# Authentication Flow

This document describes the Identity Provider authentication flow and uses
`feed-platform-web` plus `feed-platform-backend` as the concrete relying-party
example. It also records the OAuth 2.0, OpenID Connect, and security
best-practice status of the current implementation.

## Scope

The Identity Provider is implemented with Better Auth and exposes its auth API
under `/api/v1/auth`. It currently provides:

- Magic Link login.
- Passkey login and registration.
- OAuth 2.0 Authorization Code flow for `feed-platform-web`.
- OIDC ID tokens signed by the Better Auth JWT/JWKS plugin.
- JWT access tokens for API calls when the token request includes a valid
  `resource` audience.
- Refresh tokens for the `offline_access` scope.

The feed example consists of:

- `identity-provider` on `http://localhost:8787` for Better Auth endpoints and
  IdP UI pages.
- `feed-platform-web` on `http://127.0.0.1:8789` as the OAuth client and browser
  app.
- `feed-platform-backend` on `http://127.0.0.1:8788` as the BFF API protected by
  IdP-issued JWTs.

## Sequence diagram

```mermaid
sequenceDiagram
  autonumber
  actor User
  participant Web as feed-platform-web
  participant IdP as identity-provider
  participant BetterAuth as Better Auth OAuth/OIDC
  participant Backend as feed-platform-backend

  User->>Web: GET /login
  Web-->>User: Set oauth_state and pkce_verifier cookies; redirect to /oauth2/authorize
  User->>IdP: GET /api/v1/auth/oauth2/authorize?state&nonce&code_challenge
  IdP->>BetterAuth: Validate OAuth client, redirect URI, scope, state, PKCE challenge
  BetterAuth-->>User: Redirect to /app/login when no IdP session exists
  User->>IdP: Complete Magic Link or Passkey login
  IdP-->>User: Restore login_return_to and redirect to original authorize URL
  User->>IdP: GET /api/v1/auth/oauth2/authorize?...original query...
  BetterAuth-->>User: Redirect to /app/oauth/consent
  User->>IdP: POST /api/v1/auth/oauth2/consent with accept and oauth_query
  IdP->>BetterAuth: Verify signed oauth_query and record consent
  BetterAuth-->>User: Redirect to feed /auth/callback?code&state
  User->>Web: GET /auth/callback?code&state
  Web->>Web: Verify oauth_state cookie and load pkce_verifier
  Web->>BetterAuth: POST /oauth2/token with code, client credentials, PKCE verifier, resource=feed-platform-backend
  BetterAuth-->>Web: JWT access_token, id_token, optional refresh_token
  Web->>Web: Verify ID token nonce; store ID token cookie plus access/refresh tokens server-side
  Web-->>User: Redirect to /dashboard
  User->>Web: GET /dashboard
  Web->>Web: Look up JWT access token by feed-session ID token
  Web->>Backend: GET /api/v1/me with Authorization: Bearer JWT access_token
  Backend->>IdP: Fetch JWKS when needed
  Backend-->>Web: JWT-derived user payload or 401
  Web-->>User: Render dashboard or unauthenticated state
```

## Local feed OAuth flow

### 1. Login starts in feed-platform-web

`GET /login` in `feed-platform-web` generates:

- `state`, stored in the `oauth_state` HTTP-only cookie.
- PKCE `code_verifier`, stored in the `pkce_verifier` HTTP-only cookie.
- `nonce`, stored in the feed web database and later checked against the ID
  token.
- PKCE `code_challenge` using S256.

The browser is redirected to:

```text
http://localhost:8787/api/v1/auth/oauth2/authorize
```

with `response_type=code`, `client_id=feed-platform-web`,
`redirect_uri=http://127.0.0.1:8789/auth/callback`, `scope=openid profile email
offline_access`, `state`, `nonce`, `code_challenge`, and
`code_challenge_method=S256`.

### 2. Identity Provider login

If the user is not signed in, Better Auth redirects to the configured login page:

```text
/app/login
```

The IdP login page recognizes OAuth authorization parameters in the current URL
and converts them into a safe return target:

```text
/api/v1/auth/oauth2/authorize?...original OAuth query...
```

For Magic Link login, this return target is stored in a `login_return_to` cookie.
This avoids passing a nested OAuth authorization URL through Better Auth's Magic
Link `callbackURL` validation. After the Magic Link callback validates the IdP
session, the IdP deletes `login_return_to` and redirects back to the original
OAuth authorize request.

### 3. Consent page

Better Auth redirects to the configured consent page:

```text
/app/oauth/consent
```

The consent screen displays `client_id`, `scope`, and `redirect_uri`. The client
entry `oauth-consent.client.tsx` submits the decision to:

```text
POST /api/v1/auth/oauth2/consent
```

with JSON:

```json
{
  "accept": true,
  "oauth_query": "...signed OAuth query from window.location.search..."
}
```

Better Auth requires `oauth_query` so it can verify the signed authorization
request and reconstruct provider state. When consent is accepted, Better Auth
returns a JSON object containing `redirect: true` and the final callback URL.
The browser is then sent to `feed-platform-web` with an authorization code.

### 4. Authorization callback and token exchange

`feed-platform-web` handles:

```text
GET /auth/callback
```

It validates that the returned `state` matches the `oauth_state` cookie, then
exchanges the authorization code at:

```text
POST http://localhost:8787/api/v1/auth/oauth2/token
```

with form-encoded `grant_type=authorization_code`, `client_id`,
`client_secret`, `code`, `code_verifier`, `redirect_uri`, and
`resource=feed-platform-backend`.

The token response is decoded as:

- `access_token`: JWT OAuth access token for the `feed-platform-backend`
  resource.
- `id_token`: OIDC JWT when `openid` is requested.
- `refresh_token`: opaque refresh token when `offline_access` is granted.

`feed-platform-web` verifies the `nonce` claim in the ID token against its stored
nonce. It stores the ID token in the `feed-session` HTTP-only cookie for the web
login session only. The JWT access token and refresh token are stored
server-side in `oauth_refresh_session` keyed by the current `feed-session` token;
neither token is sent to the browser.

### 5. Dashboard and backend call

`feed-platform-web` auth middleware verifies the `feed-session` signature against:

```text
http://localhost:8787/api/v1/auth/jwks
```

The current web middleware does not validate issuer or audience. The backend
does validate those claims, so the backend is the stricter JWT enforcement point
in the feed example.

Before calling the backend, feed web looks up the server-side access token for
the current `feed-session`. The dashboard then calls `feed-platform-backend`:

```text
GET http://localhost:8788/api/v1/me
Authorization: Bearer <JWT access token>
```

`feed-platform-backend` verifies:

- `alg=ES256`.
- `aud=feed-platform-backend`.
- `iss=http://localhost:8787/api/v1/auth`.
- signature through `http://localhost:8787/api/v1/auth/jwks`.
- `token_use=access`, rejecting ID tokens even when they are otherwise valid
  JWTs.
- required `sub` and `email` claims.

The backend returns the JWT-derived `sub` and `email` payload. `feed-platform-web`
uses `sub` as the OIDC subject and does not fall back to an application `id`.

### 6. Refresh

If the backend call fails and a server-side refresh token exists for the current
`feed-session`, `feed-platform-web` attempts `grant_type=refresh_token` at the
IdP token endpoint with `resource=feed-platform-backend`. The refresh response
must include a refreshed ID token for `feed-session` and a refreshed JWT access
token for the backend. The refreshed or previous refresh token remains
server-side, then feed web retries the backend call with the refreshed access
token.

### 7. Logout

`GET /logout` in `feed-platform-web` clears `feed-session`, deletes the
server-side refresh session for that browser session, and attempts to call Better
Auth sign-out with an empty JSON body to satisfy the endpoint content-type
contract.

Current logout is a local best-effort operation. It is not a complete OIDC
RP-Initiated Logout or OAuth token revocation flow.

## OAuth 2.0 and OIDC compliance status

The references used for this status are OAuth 2.0 Authorization Framework
(RFC 6749), PKCE (RFC 7636), OAuth 2.0 Security Best Current Practice
(RFC 9700), OAuth token revocation (RFC 7009), OAuth discovery metadata
(RFC 8414), JSON Web Token (RFC 7519), JSON Web Key (RFC 7517), OpenID Connect
Core 1.0, and the OWASP OAuth2 Cheat Sheet.

### Implemented or mostly compliant

| Area                      | Status                     | Evidence                                                                                               |
| ------------------------- | -------------------------- | ------------------------------------------------------------------------------------------------------ |
| Authorization Code flow   | Implemented                | Feed web uses `/oauth2/authorize`, receives `code`, and exchanges it at `/oauth2/token`.               |
| PKCE                      | Implemented                | Feed web generates a verifier and S256 challenge; the callback sends `code_verifier`.                  |
| `state` CSRF binding      | Implemented                | Feed web stores `oauth_state` in an HTTP-only cookie and rejects callback state mismatch.              |
| OIDC `nonce`              | Implemented                | Feed web stores a nonce and verifies the ID token nonce before accepting the login.                    |
| Exact redirect URI        | Implemented for local feed | Seeded client redirect URI is `http://127.0.0.1:8789/auth/callback`.                                   |
| ID token signing and JWKS | Implemented                | IdP uses Better Auth `jwt` with ES256 and exposes `/api/v1/auth/jwks`.                                 |
| JWT access token boundary | Implemented                | Feed web requests `resource=feed-platform-backend`; backend rejects tokens without `token_use=access`. |
| Audience validation       | Implemented                | Backend verifies `aud=feed-platform-backend`; IdP has `validAudiences`.                                |
| Issuer validation         | Implemented                | Backend verifies issuer `http://localhost:8787/api/v1/auth`.                                           |
| Refresh token table       | Implemented                | `oauth_refresh_token` table exists and maps `scopes` to `scope`.                                       |
| Consent endpoint          | Implemented                | Consent screen calls `/oauth2/consent` with Better Auth `oauth_query`.                                 |

### Non-compliant, incomplete, or local-only behavior

#### Raw local client secret storage

Current behavior:

- `identity-provider` configures `storeClientSecret` with identity `hash` and
  equality `verify`.
- The local seed stores the raw dev secret.

Why this is a problem:

- OAuth clients with `client_secret` are confidential clients. A stored raw
  secret increases blast radius if the IdP database is disclosed.
- This is acceptable only as a deterministic local-development exception.

Fix:

- In production, remove the identity `storeClientSecret` override and store
  Better Auth's default hashed secret value.
- Alternatively use a custom KMS-backed encrypted storage strategy with
  rotation.
- Document the one-time migration that hashes existing stored client secrets.

#### HTTP localhost origins

Current behavior:

- Local IdP runs on `http://localhost:8787`.
- Feed web runs on `http://127.0.0.1:8789`.

Why this is a problem:

- OAuth/OIDC production deployments must use HTTPS. Plain HTTP is only suitable
  for local loopback development.
- `localhost` and `127.0.0.1` are not interchangeable in redirect validation,
  cookie scoping, or issuer strings.

Fix:

- Production origins must be HTTPS and stable.
- Keep redirect URIs exact and environment-specific.
- Avoid mixing `localhost` and `127.0.0.1` except where the local topology
  explicitly requires separate cookie scopes.

#### Consent information is minimal

Current behavior:

- Consent shows `client_id`, requested scopes, and redirect URI.

Why this is incomplete:

- OIDC consent should be understandable to users. `client_id` alone is not a
  friendly application identity.
- Users are not told what each scope permits, how long access lasts, or whether
  refresh/offline access is being granted.

Fix:

- Resolve and display registered client name, owner/contact, and client URI.
- Explain each requested scope in product language.
- Highlight `offline_access` separately because it grants refresh-token based
  access.

#### No persisted consent review or revocation UI

Current behavior:

- Consent can be recorded by Better Auth, but there is no user-facing page to
  review or revoke existing grants.

Why this is incomplete:

- Security best practices expect users or administrators to revoke application
  access without deleting the whole account.

Fix:

- Add an IdP account page section listing `oauth_consent`, access tokens, and
  refresh tokens by client.
- Provide a revoke action using token/consent deletion or Better Auth revoke
  endpoints where applicable.

#### Logout is not OIDC RP-Initiated Logout

Current behavior:

- Feed web clears its cookies and attempts Better Auth sign-out.
- It does not perform standards-based RP-Initiated Logout.
- It does not revoke the OAuth refresh token.

Why this is incomplete:

- Clearing local cookies does not necessarily invalidate server-side refresh
  tokens or all relying-party sessions.

Fix:

- Implement token revocation for server-side feed refresh sessions using
  RFC 7009-compatible revoke behavior if the provider exposes it.
- Add OIDC RP-Initiated Logout support when Better Auth configuration and client
  metadata support `end_session_endpoint` and `post_logout_redirect_uri`.
- Ensure logout does not send an ID token in a cookie named as an access-token
  session to the wrong endpoint.

#### Backend access token purpose is separated from web session identity

Current behavior:

- Feed web requests a JWT access token by sending
  `resource=feed-platform-backend` to the token endpoint.
- The IdP includes `aud=feed-platform-backend`, `azp=feed-platform-web`, and
  `token_use=access` in the access token.
- Feed web stores the ID token in `feed-session` only for the web login session.
- Feed web stores the JWT access token server-side and sends that token, not the
  ID token, to `feed-platform-backend`.
- The backend verifies issuer, audience, ES256 signature, required user claims,
  and `token_use=access`.

Why this matters:

- ID tokens are intended to authenticate the user to the client, while access
  tokens authorize API access. A backend that accepts ID tokens as bearer tokens
  conflates token purposes and can accidentally accept tokens minted for a
  different relying party.
- Requiring a resource-specific JWT access token keeps the BFF authorization
  boundary aligned with OAuth token purpose and audience semantics.

Remaining hardening:

- Keep the ID-token rejection test in `feed-platform-backend` whenever changing
  JWT claims or token exchange behavior.
- If the IdP ever returns opaque access tokens for this flow, replace backend JWT
  verification with RFC 7662-style introspection or a server-to-server token
  minted specifically for the backend.
- Do not send `feed-session` ID tokens to backend APIs.

#### Feed web JWT validation is weaker than backend validation

Current behavior:

- `feed-platform-web` middleware verifies JWT signatures with the IdP JWKS.
- It does not pass expected `issuer`, `audience`, or `algorithms` to `jwtVerify`.
- `feed-platform-backend` does validate issuer, audience, and ES256.

Why this is incomplete:

- A relying party should reject tokens from the wrong issuer, for the wrong
  audience, or with an unexpected algorithm before treating the user as signed
  in.

Fix:

- Update `feed-platform-web` auth middleware to verify `issuer`, `audience`, and
  `algorithms: ['ES256']`, matching backend validation.
- Keep the backend validation as the API authorization enforcement point.

#### Refresh-token storage and rotation policy is not documented in code

Current behavior:

- Better Auth stores provider-side refresh tokens in `oauth_refresh_token`.
- Feed web stores the client refresh token server-side in `oauth_refresh_session`
  keyed by the current `feed-session` token.

Why this needs follow-up:

- Refresh tokens are long-lived and high-value.
- The implementation should clearly enforce rotation, replay detection, expiry,
  and revocation.

Fix:

- Confirm Better Auth refresh-token family invalidation and rotation settings for
  the deployed version.
- Add tests for refresh replay and revoked refresh-token rejection.
- Add explicit refresh-token revocation and replay tests for the
  `oauth_refresh_session` store.

#### CSRF and origin policy around sign-out and consent need explicit tests

Current behavior:

- Better Auth validates signed `oauth_query` for consent.
- Feed web and IdP cookies are `HttpOnly` and `SameSite=Lax` where relevant.
- There are no explicit tests proving malicious cross-site POSTs cannot mutate
  consent or sign-out state.

Why this is incomplete:

- OAuth state protects the authorization callback. It does not automatically
  protect every state-changing endpoint.

Fix:

- Add tests for untrusted-origin POSTs to Better Auth state-changing endpoints.
- Configure `trustedOrigins` explicitly for production origins.
- Add CSRF tokens for custom state-changing UI endpoints if they are introduced
  outside Better Auth.

#### Discovery metadata warning remains

Current behavior:

- Better Auth logs a warning requesting
  `/.well-known/oauth-authorization-server/api/v1/auth`.

Why this is incomplete:

- OAuth/OIDC clients use discovery metadata for issuer, JWKS URI, token endpoint,
  supported algorithms, and logout/revocation capabilities.

Fix:

- Expose and test OAuth Authorization Server Metadata and OIDC configuration
  endpoints for the deployed issuer.
- Silence warnings only after the metadata endpoints are intentionally served and
  verified.

#### Database schema drift from Better Auth is a recurring risk

Current behavior:

- The IdP schema manually maps Better Auth OAuth models and fields.
- Recent runtime verification found missing `oauth_refresh_token`, missing access
  token columns, and an incompatible `updated_at` constraint.

Why this is a problem:

- Manual schema drift causes runtime token issuance failures that type checks do
  not catch.

Fix:

- Add a schema compatibility test that runs an authorization-code token exchange
  against the local database.
- Track Better Auth OAuth provider schema changes on dependency updates.
- Prefer generated migrations from the provider schema when available.

## Production hardening checklist

Before using this flow beyond local development:

1. Use HTTPS-only origins and exact registered redirect URIs.
2. Store client secrets hashed or encrypted; do not use the local identity
   secret verifier.
3. Keep backend API authorization on resource-specific access tokens; never send
   ID tokens as backend bearer tokens.
4. Validate issuer, audience, and allowed algorithms in every JWT-consuming
   relying party, including `feed-platform-web` middleware.
5. Implement or validate token revocation for refresh tokens.
6. Add consent review and revocation UI.
7. Serve OAuth/OIDC discovery metadata and test issuer/JWKS consistency.
8. Add end-to-end tests for authorization code, PKCE, nonce, refresh, revocation,
   and logout.
9. Add negative tests for invalid state, invalid nonce, invalid redirect URI,
   invalid client secret, replayed authorization code, and untrusted origins.
10. Keep local DB schema migrations in sync with Better Auth model names and field
    mappings.

## Key implementation files

- IdP Better Auth config: `app/feature/auth/better-auth.ts`
- IdP app routes: `app/app.tsx`
- IdP consent UI: `app/ui/oauth-consent.tsx`
- IdP consent client entry: `app/ui/oauth-consent.client.tsx`
- IdP OAuth schema: `db/schema.hcl`
- Feed OAuth client helpers: `../../feed-platform-web/app/feature/auth/oauth-client.ts`
- Feed callback: `../../feed-platform-web/app/feature/auth/callback.ts`
- Feed auth middleware: `../../feed-platform-web/app/feature/auth/middleware.ts`
- Feed backend client: `../../feed-platform-web/app/feature/api/client.ts`
- Backend JWT verifier: `../../feed-platform-backend/src/feature/auth/jwt.ts`
