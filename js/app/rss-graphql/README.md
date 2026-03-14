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
# Start development server
bun run dev

# Start Wrangler local server
bun run start

# Type check
bun run check

# Deploy to Cloudflare
bun run deploy
```

## Architecture

- `app/entry.worker.ts` - Cloudflare Worker entry point
- `app/app.ts` - Main Hono application
- `app/feature/graphql/` - GraphQL schema and resolvers
- `app/feature/hono/` - Hono context utilities

Path alias: `#@/*` maps to `./app/*`
