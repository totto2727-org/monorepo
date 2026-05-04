# @app/rss-graphql

GraphQL API server for RSS feed processing and querying.

## Tech Stack

- **Runtime**: Cloudflare Workers
- **Framework**: Hono
- **GraphQL**: Pothos schema builder + GraphQL Scalars
- **RSS**: @mikaelporttila/rss for feed parsing
- **FP**: Effect for functional error handling
- **Build**: Vite + @cloudflare/vite-plugin

## Development

```bash
# Start development server (run from this directory; vp built-in)
vp dev

# Start Wrangler local server (still a package.json script)
vp run --filter @app/rss-graphql start

# Lint, format, and type check — root `check` task (workspace-wide)
vp run check

# Deploy to Cloudflare (still a package.json script)
vp run --filter @app/rss-graphql deploy
```

This package has no `build` / `setup` task: deploy is wrangler-driven directly.

## Architecture

- `app/entry.worker.ts` - Cloudflare Worker entry point
- `app/app.ts` - Main Hono application
- `app/feature/graphql/` - GraphQL schema and resolvers
- `app/feature/hono/` - Hono context utilities

Path alias: `#@/*` maps to `./app/*`
