# hono-remix-v3-cloudflare-example Guide

This app uses **Cloudflare Workers + Hono + Remix v3 (UI / SSR)**. Vite (`vp dev`) drives local development via `@cloudflare/vite-plugin`; Wrangler runs the Worker locally and deploys it.

Package management is Bun (via `vp`). Do not introduce package-manager-specific commands when Vite+ tasks already exist.

## Commands

`build` is a Vite+ task in `vite.config.ts`; `dev` / `start` / `deploy` / `typecheck` remain `package.json` scripts. From the repo root:

```sh
vp run --filter hono-remix-v3-cloudflare-example dev        # vp dev — Workers run inside Vite, HMR for client entry
vp run --filter hono-remix-v3-cloudflare-example start      # wrangler dev — Workers run on workerd against built output
vp run --filter hono-remix-v3-cloudflare-example build      # vp build — emit Worker + client bundles (cached)
vp run --filter hono-remix-v3-cloudflare-example deploy     # wrangler deploy
vp run --filter hono-remix-v3-cloudflare-example typecheck  # tsgo --noEmit
```

Run-from-app-dir works too (`cd js/app/hono-remix-v3-cloudflare-example && vp run build`). Install dependencies from the repo root with `bun install`.

## Building Features

Refer to `.claude/skills/remix/SKILL.md` for Remix UI / SSR guidance. Note that this app does **not** use `remix/fetch-router` or `remix/assets`; routing is Hono and bundling is Vite.

## Starter Layout

- `app/entry.worker.ts` — Worker entry that re-exports the Hono app
- `app/app.ts` — Hono app definition and route wiring
- `app/controllers/home.tsx` owns the home page
- `app/controllers/auth.tsx` owns the auth page
- `app/ui/` holds the shared document and layout wrappers
- `app/utils/render.tsx` wraps `remix/ui/server` `renderToStream` for HTML responses
- `app/assets/entry.ts` is the client entry served by Vite (referenced from `<script>` in the Document)

## Route Ownership

- Define routes in `app/app.ts` and map each route to the narrowest owner on disk.
- Keep simple pages in flat files like `app/controllers/home.tsx` and `app/controllers/auth.tsx`.
- Promote a route into a controller folder with `controller.tsx` only when it gains nested routes, multiple actions, or route-owned modules.
- Keep route-owned page modules next to the route that owns them.
- Move shared UI to `app/ui/`, not `app/controllers/`.

## Build-Out Notes

- The client entry is served by Vite during `vp dev`; for production, `vite build` emits both the Worker and the client bundle, and Wrangler ships them.
- Add `public/` (Cloudflare Workers Assets) only when you need to ship static files.
- Prefer putting code in the narrowest owner before introducing shared modules.
- Avoid generic dumping-ground directories like `app/lib/` or `app/components/`.
