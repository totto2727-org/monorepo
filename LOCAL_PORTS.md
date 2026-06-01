# Local Connected System Ports

This file is the local port registry for systems that are designed to run together during feed-platform development. Keep these defaults unique so `vp run dev`, `wrangler dev`, and local DB servers can run at the same time.

| System                              | Command                                                            | Default URL             | Config owner                                                    |
| ----------------------------------- | ------------------------------------------------------------------ | ----------------------- | --------------------------------------------------------------- |
| identity-provider Vite dev server   | `vp run --filter identity-provider dev`                            | `http://127.0.0.1:8787` | `js/app/identity-provider/vite.config.ts`                       |
| identity-provider Wrangler worker   | `vp run --filter identity-provider start`                          | `http://127.0.0.1:8787` | `js/app/identity-provider/wrangler.jsonc`                       |
| identity-provider DB                | `vp exec just --justfile js/app/identity-provider/Justfile db-dev` | `http://127.0.0.1:8080` | `js/app/identity-provider/Justfile`                             |
| feed-platform-web Vite dev server   | `vp run --filter feed-platform-web dev`                            | `http://127.0.0.1:8789` | `js/app/feed-platform-web/vite.config.ts`                       |
| feed-platform-web Wrangler worker   | `vp run --filter feed-platform-web start`                          | `http://127.0.0.1:8789` | `js/app/feed-platform-web/wrangler.jsonc`                       |
| feed-platform-web DB                | `vp exec just --justfile js/app/feed-platform-web/Justfile db-dev` | `http://127.0.0.1:8081` | `js/app/feed-platform-web/Justfile`                             |
| feed-platform-backend BFF worker    | `vp run --filter feed-platform-backend dev:bff`                    | `http://127.0.0.1:8788` | `js/app/feed-platform-backend/src/worker/bff/wrangler.jsonc`    |
| feed-platform-backend health worker | `vp run --filter feed-platform-backend dev:health`                 | `http://127.0.0.1:8790` | `js/app/feed-platform-backend/src/worker/health/wrangler.jsonc` |

## Cross-Service Expectations

- `identity-provider` accepts `feed-platform-web` and `http://127.0.0.1:8789` as local OAuth audiences.
- `feed-platform-web` expects IdP at `http://localhost:8787`, backend BFF at `http://localhost:8788`, and its own DB at `http://127.0.0.1:8081`.
- `feed-platform-backend` expects IdP and JWKS at `http://localhost:8787`.
- IdP DB and feed-platform-web DB are separate local database boundaries, matching production separation. Do not point both apps at the same `turso dev` process.
