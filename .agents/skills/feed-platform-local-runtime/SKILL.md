---
name: feed-platform-local-runtime
description: Run and verify identity-provider, feed-platform-web, and feed-platform-backend locally with Wrangler and Vite. Use for production-like built Wrangler verification, hot-reload development setup, ports, database prep, OAuth seed data, and local auth-flow QA.
metadata:
  author: totto2727
  version: 1.0.0
---

# Feed Platform Local Runtime Verification

Use this skill when you need to start, verify, debug, or document local runtime flows for:

- `js/app/identity-provider`
- `js/app/feed-platform-web`
- `js/app/feed-platform-backend`

The goal is to choose the right local topology before running commands, so IdP, web, backend, DB, seed data, and ports agree.

## Ground Rules

- Run commands from the repository root unless a command explicitly says to run inside a package.
- Never use `npx` or `bunx`; use `vp run`, `vp exec`, or `vpx`.
- Run `vp run -r setup` before production-like verification so generated Wrangler/Kysely files exist.
- Keep IdP on `http://localhost:8787`, feed-platform-web on `http://localhost:8789`, and backend BFF on `http://localhost:8788` unless you intentionally update every dependent env value.
- Treat `wrangler dev` as the production-like Worker runtime. Treat `vp dev` as the hot-reload Vite development runtime for Remix apps.
- If you change startup configuration, regenerate Worker types with the package setup task.

## Local Port Map

| Service                   | Default URL             | Purpose                                                |
| ------------------------- | ----------------------- | ------------------------------------------------------ |
| IdP                       | `http://localhost:8787` | Better Auth, passkey, magic link, OAuth provider, JWKS |
| feed-platform-web         | `http://localhost:8789` | Browser-facing Remix web app / BFF client              |
| feed-platform-backend BFF | `http://localhost:8788` | Backend API, including protected `/api/v1/me`          |
| IdP DB                    | `http://127.0.0.1:8080` | IdP-only libSQL/Turso database                         |
| feed-platform-web DB      | `http://127.0.0.1:8081` | Web-only libSQL/Turso database                         |

IdP and feed-platform-web must be treated as separate database boundaries. Production runs separate databases, so local development should also use separate DB files and ports instead of sharing one libSQL endpoint.

Backend BFF Wrangler vars currently point at the IdP dev URL:

```jsonc
{
  "IDP_BASE_URL": "http://localhost:8787",
  "IDP_JWKS_URL": "http://localhost:8787/api/v1/auth/jwks",
  "FEED_PLATFORM_AUDIENCE": "feed-platform-web",
}
```

## One-Time / Preflight Setup

Run workspace setup first:

```bash
vp run -r setup
```

For IdP OAuth flows, prepare the local DB and seed the OAuth client:

```bash
vp run --filter identity-provider setup
vp exec just --justfile js/app/identity-provider/Justfile db-schema-apply
vp exec just --justfile js/app/identity-provider/Justfile seed-oauth
```

For local DB-backed flows, start one libSQL/Turso dev server per database boundary.

IdP DB:

```bash
vp exec turso dev --db-file js/app/identity-provider/node_modules/.cache/db --port 8080
```

feed-platform-web DB:

```bash
vp exec turso dev --db-file js/app/feed-platform-web/node_modules/.cache/db --port 8081
```

Before starting each DB server, apply that app's schema and generate types:

```bash
vp run --filter identity-provider setup:kysely
vp run --filter feed-platform-web setup:kysely
```

The IdP `Justfile` also provides `db-dev`, but that helper only starts the IdP DB on the default Turso port. Do not use a single `db-dev` process as the shared DB for both apps.

Ensure each app's dev env points at its own endpoint:

- IdP: `DATABASE_URL=http://127.0.0.1:8080`
- feed-platform-web: `DATABASE_URL=http://127.0.0.1:8081`

## Production-Like Wrangler Verification

Use this when checking behavior close to deployed Workers. Build/setup first, then run Worker entrypoints with Wrangler.

### 1. Build/setup generated artifacts

```bash
vp run -r setup
vp run --filter identity-provider build
vp run --filter feed-platform-web build
vp run --filter feed-platform-backend setup
```

### 2. Start IdP with Wrangler

```bash
vp run --filter identity-provider start -- --port 8787
```

Alternative from inside `js/app/identity-provider`:

```bash
vp run start -- --port 8787
```

### 3. Start feed-platform-web with Wrangler

```bash
vp run --filter feed-platform-web start -- --port 8789
```

### 4. Start backend BFF with Wrangler

```bash
vp run --filter feed-platform-backend dev:bff -- --port 8788
```

Backend health worker, when needed:

```bash
vp run --filter feed-platform-backend dev:health -- --port 8790
```

### 5. Verify runtime endpoints

Expected baseline checks:

```bash
curl -i http://localhost:8787/login
curl -i http://localhost:8789/
curl -i http://localhost:8788/health
curl -i http://localhost:8788/api/v1/me
```

`/api/v1/me` should return `401` with `WWW-Authenticate: Bearer error="invalid_token"` unless a valid IdP-issued Bearer token is supplied.

## Hot-Reload Development Setup

Use this while editing Remix UI or request handlers and wanting Vite/Wrangler hot reload.

### IdP hot reload

```bash
vp run --filter identity-provider dev -- --host 127.0.0.1 --port 8787
```

This runs `vp dev` through the package script and uses the Vite + Cloudflare plugin path. Keep the IdP DB dev process running separately for auth flows.

### feed-platform-web hot reload

```bash
vp run --filter feed-platform-web dev -- --host 127.0.0.1 --port 8789
```

The web app expects IdP at `http://localhost:8787`, backend at `http://localhost:8788`, and its own DB at `http://127.0.0.1:8081` through its dev env layer.

### Backend development loop

The backend package does not define a Vite hot-reload `dev` script. Use Wrangler dev for Worker reloads:

```bash
vp run --filter feed-platform-backend dev:bff -- --port 8788
vp run --filter feed-platform-backend dev:health -- --port 8790
```

If backend env vars change, edit `src/worker/bff/wrangler.jsonc`, then regenerate types:

```bash
vp run --filter feed-platform-backend setup:cloudflare:bff
```

## OAuth / Auth Flow Verification

Minimum browser flow after preflight setup:

1. Start the IdP DB dev process on `8080`.
2. Start the feed-platform-web DB dev process on `8081`.
3. Start IdP on `8787`.
4. Start feed-platform-web on `8789`.
5. Visit `http://localhost:8789` and trigger login.
6. Confirm redirect to IdP and back to web callback.
7. Start backend BFF on `8788` and verify web-to-backend requests exchange local session state for Bearer auth.

For backend-only JWT checks, use tests first:

```bash
vp test run js/app/feed-platform-backend/src/feature/auth/jwt.test.ts js/app/feed-platform-backend/src/feature/auth/middleware.test.ts js/app/feed-platform-backend/src/feature/health.test.ts
```

Then manually check rejected access:

```bash
curl -i http://localhost:8788/api/v1/me
```

## Troubleshooting

- Missing `worker-configuration.d.ts`: run the relevant setup task, or `vp run -r setup`.
- Missing `app/feature/db/generated.ts`: run `vp run --filter identity-provider setup:kysely` or `vp run --filter feed-platform-web setup:kysely`.
- OAuth client not found: run `vp exec just --justfile js/app/identity-provider/Justfile seed-oauth` after schema apply.
- DB connection refused at `127.0.0.1:8080`: start the IdP DB dev process and keep it alive.
- DB connection refused at `127.0.0.1:8081`: start the feed-platform-web DB dev process and keep it alive.
- IdP data appears in web tables or vice versa: stop using a shared DB file/port; production separates these databases, and local verification should mirror that boundary.
- Unexpected 401 from backend: verify IdP is on `8787`, backend BFF vars point at that IdP, and the token audience is `feed-platform-web`.
- Port conflict: keep the documented port map or update all cross-service env values together.
