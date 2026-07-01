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
- Use the root [local port registry](../../../LOCAL_PORTS.md) as the single source of truth for local service and DB ports.
- Treat `wrangler dev` as the production-like Worker runtime. Treat `vp dev` as the hot-reload Vite development runtime for Remix apps.
- If you change startup configuration, regenerate Worker types with the package setup task.

## Effect + Hono Runtime and Env Policy

Choose the env strategy from the runtime entrypoint. Do not mix Vite-only signals into direct Wrangler Workers.

### Vite-managed Remix apps

Use this pattern for `identity-provider` and `feed-platform-web` Vite/Cloudflare-plugin development paths:

- Runtime construction may branch on `import.meta.env.PROD` because Vite replaces it.
- Production/runtime bindings come from Hono/Cloudflare `ctx.env` through the app env layer.
- Local Vite development can use a fixed `devLayer` for deterministic endpoints and DB URLs.
- Keep the Vite dev layer aligned with the root port registry and the app's Wrangler config.

### Direct Wrangler Workers

Use this pattern for `feed-platform-backend`, which runs Worker entries directly through Wrangler:

- Do not use `import.meta.env.PROD` for app behavior. It is a Vite convention and is not the source of truth for direct Wrangler execution.
- Build the Effect runtime at the Hono/Worker boundary from `ctx.env` and provide app env once at the top level, for example `Runtime.make(ctx.env)` -> `AppEnv.makeLayer(env)`.
- Middleware and services should consume `ctx.var.runtime` / Effect services. They should not create local env fallback layers or branch between dev/prod themselves.
- Fixed local values must live under the Wrangler local environment, for example `env.local.vars` in `wrangler.jsonc` / `[env.local.vars]` in `wrangler.toml`.
- Local scripts and type generation that need those fixed values must pass `--env local`.
- Deploy scripts must not pass `--env local`; otherwise local-only URLs can be pushed to production.
- Because Wrangler bindings such as `vars` are not inherited across environments, do not put local-only feed/IdP URLs in top-level `vars`.
- Unit tests that call Hono directly must pass an explicit test binding object to `app.request(...)`; do not add application `devLayer` fallbacks only to satisfy tests.

## Local Port Map

See the root [local port registry](../../../LOCAL_PORTS.md). Do not duplicate port values in this skill.

IdP and feed-platform-web must be treated as separate database boundaries. Production runs separate databases, so local development should also use separate DB files and ports instead of sharing one libSQL endpoint.

Backend BFF local Wrangler vars under `env.local.vars` must stay aligned with the IdP URL in the root port registry.

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
vp exec just --justfile js/app/identity-provider/Justfile db-dev
```

feed-platform-web DB:

```bash
vp exec just --justfile js/app/feed-platform-web/Justfile db-dev
```

Before starting each DB server, apply that app's schema and generate types:

```bash
vp run --filter identity-provider setup:kysely
vp run --filter feed-platform-web setup:kysely
```

Each DB-backed app provides its own `db-dev` helper. Do not use a single `db-dev` process as the shared DB for both apps.

Ensure each app's dev env points at its own endpoint from the root port registry.

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
vp run --filter identity-provider start
```

Alternative from inside `js/app/identity-provider`:

```bash
vp run start
```

### 3. Start feed-platform-web with Wrangler

```bash
vp run --filter feed-platform-web start
```

### 4. Start backend BFF with Wrangler

```bash
vp run --filter feed-platform-backend dev:bff
```

Backend health worker, when needed:

```bash
vp run --filter feed-platform-backend dev:health
```

### 5. Verify runtime endpoints

Expected baseline checks:

```bash
curl -i <idp-url>/login
curl -i <web-url>/
curl -i <backend-bff-url>/health
curl -i <backend-bff-url>/api/v1/me
```

Resolve the placeholder URLs from the root port registry before running the checks.

`/api/v1/me` should return `401` with `WWW-Authenticate: Bearer error="invalid_token"` unless a valid IdP-issued Bearer token is supplied.

## Hot-Reload Development Setup

Use this while editing Remix UI or request handlers and wanting Vite/Wrangler hot reload.

### IdP hot reload

```bash
vp run --filter identity-provider dev
```

This runs `vp dev` through the package script and uses the Vite + Cloudflare plugin path. Keep the IdP DB dev process running separately for auth flows.

### feed-platform-web hot reload

```bash
vp run --filter feed-platform-web dev
```

The web app expects IdP, backend, and DB endpoints to match the root port registry through its dev env layer.

### Backend development loop

The backend package does not define a Vite hot-reload `dev` script. Use Wrangler dev for Worker reloads:

```bash
vp run --filter feed-platform-backend dev:bff
vp run --filter feed-platform-backend dev:health
```

If backend local env vars change, edit `src/worker/bff/wrangler.jsonc` under `env.local.vars`, then regenerate types:

```bash
vp run --filter feed-platform-backend setup:cloudflare:bff
```

## OAuth / Auth Flow Verification

Minimum browser flow after preflight setup:

1. Start the IdP DB dev process.
2. Start the feed-platform-web DB dev process.
3. Start IdP.
4. Start feed-platform-web.
5. Visit the web URL from the root port registry and trigger login.
6. Confirm redirect to IdP and back to web callback.
7. Start backend BFF and verify web-to-backend requests exchange local session state for Bearer auth.

For backend-only JWT checks, use tests first:

```bash
vp test run js/app/feed-platform-backend/src/feature/auth/jwt.test.ts js/app/feed-platform-backend/src/feature/auth/middleware.test.ts js/app/feed-platform-backend/src/feature/health.test.ts
```

Then manually check rejected access:

```bash
curl -i <backend-bff-url>/api/v1/me
```

Resolve the placeholder URL from the root port registry before running the check.

## Troubleshooting

- Missing `worker-configuration.d.ts`: run the relevant setup task, or `vp run -r setup`.
- Missing `app/feature/db/generated.ts`: run `vp run --filter identity-provider setup:kysely` or `vp run --filter feed-platform-web setup:kysely`.
- OAuth client not found: run `vp exec just --justfile js/app/identity-provider/Justfile seed-oauth` after schema apply.
- DB connection refused for the IdP DB endpoint: start the IdP DB dev process and keep it alive.
- DB connection refused for the feed-platform-web DB endpoint: start the feed-platform-web DB dev process and keep it alive.
- IdP data appears in web tables or vice versa: stop using a shared DB file/port; production separates these databases, and local verification should mirror that boundary.
- Unexpected 401 from backend: verify IdP and backend BFF URLs match the root port registry, and the token audience is `feed-platform-web`.
- Port conflict: keep the documented port map or update all cross-service env values together.
