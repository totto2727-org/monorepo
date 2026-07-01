# hono-remix-middleware

Following the same pattern as Hono's built-in [`jsxRenderer`](https://hono.dev/docs/middleware/builtin/jsx-renderer), this is middleware for calling **Remix v3's `remix/ui` SSR**.

Runtime / bundler agnostic, works on Cloudflare Workers / Node / Bun / Deno.

## Installation

```sh
bun add hono-remix-middleware
```

## API

### `remixRenderer(options)`

Middleware factory function that extends Hono's `c.render()`.

```tsx
import { remixRenderer } from 'hono-remix-middleware'

app.use(
  '*',
  remixRenderer({
    fetcher: (request) => app.fetch(request),
  }),
)

app.get('/', (c) =>
  c.render(
    <Document title='Home'>
      <h1>Home</h1>
    </Document>,
  ),
)
```

| Option               | Type                                           | Description                                                                                                                                 |
| -------------------- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `fetcher`            | `typeof fetch`                                 | Called when re-fetching a frame in nested SSR (`resolveFrame` in `remix/ui/server`). Typically pass `(req) => app.fetch(req)` as a closure. |
| `resolveClientEntry` | `(entryId, component) => { exportName, href }` | Optional. Hook to compute `moduleUrl`/`exportName` from the clientEntry ID. Default is to strip the `/assets/` prefix.                      |

A straightforward implementation that passes `c.render(content)`'s `content` directly to `renderToStream`. Composing the Layout / Document is the handler's responsibility.

### `remixAssetServer(assetServer)`

Middleware factory function that integrates Remix v3's asset server.

```ts
import { createAssetServer } from 'remix/assets'
import { remixAssetServer } from 'hono-remix-middleware/asset-server'

const assetServer = createAssetServer({
  basePath: '/assets',
  rootDir: process.cwd(),
  fileMap: {
    'app/*path': 'app/*path',
    'node_modules/*path': 'node_modules/*path',
  },
  allow: ['app/assets/**', 'app/ui/**', 'node_modules/**'],
  deny: ['app/**/*.server.*'],
})

app.use('/assets/*', remixAssetServer(assetServer))
```

Note: `remixAssetServer` is intended for environments where TSX or Bun/Deno run files directly without bundling. Since it manipulates files, it does not work on Workers; if needed, assets must be prepared with a Vite plugin.

---

## Architecture Patterns

|                      | Vite + Cloudflare         | Vite + Node/Bun/Deno     | Native (no bundler)            |
| -------------------- | ------------------------- | ------------------------ | ------------------------------ |
| Client bundle        | `vite-plugin-remix`       | `vite-plugin-remix`      | None — run directly on runtime |
| Asset serving (prod) | wrangler `assets` binding | Hono `serveStatic`       | `remixAssetServer`             |
| Asset serving (dev)  | Vite dev server           | Vite dev server          | `remixAssetServer`             |
| SSR execution target | Workers                   | `@hono/node-server` etc. | tsx / bun / deno               |

[`vite-plugin-remix` README](../vite-plugin-remix/README.md)

### Pattern 1: Vite + Cloudflare Workers

Bundle the client with `vite-plugin-remix`, serve with `wrangler.jsonc`'s `assets` binding.

```ts:vite.config.ts
import { cloudflare } from '@cloudflare/vite-plugin'
import { remix } from 'vite-plugin-remix'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [
    remix({ clientEntry: 'app/assets/entry.ts' }),
    cloudflare(),
  ],
})
```

```jsonc:wrangler.jsonc
{
  "compatibility_date": "2026-02-01",
  "compatibility_flags": ["nodejs_compat"],
  "main": "./app/entry.worker.ts",
  "name": "my-app",
  "assets": {
    "directory": "./dist/client",
    "binding": "ASSETS",
  },
}
```

```tsx:app/app.tsx
import { Hono } from 'hono'
import { remixRenderer } from 'hono-remix-middleware'
import type { RemixNode } from 'remix/ui'
import { Script } from 'vite-plugin-remix/client'

const Document = () => ({ title, children }: { title?: string; children?: RemixNode }) => (
  <html lang='en'>
    <head>
      <meta charSet='utf-8' />
      <meta name='viewport' content='width=device-width, initial-scale=1' />
      <title>{title}</title>
    </head>
    <body>
      {children}
      <Script devSrc='/app/assets/entry.ts' prodSrc='/assets/entry.js' />
    </body>
  </html>
)

const app = new Hono()

app
  .use(
    '*',
    remixRenderer({
      fetcher: (req) => app.fetch(req),
    }),
  )
  .get('/', (c) =>
    c.render(
      <Document title='Home'>
        <h1>Home</h1>
      </Document>,
    ),
  )

export default app
```

```ts:app/entry.worker.ts
import app from './app.tsx'
export default app
```

```ts:app/assets/entry.ts
import { boot } from 'vite-plugin-remix/client'

boot({
  components: import.meta.glob('/app/**/*.client.tsx'),
})
```

### Pattern 2: Vite + Node / Bun / Deno

Serve the build output of `vite-plugin-remix` (`dist/client/`) via Hono's `serveStatic`, and run Hono on the Node/Bun/Deno server runtime.

```ts:vite.config.ts
import { remix } from 'vite-plugin-remix'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' })],
})
```

```tsx:app/app.tsx
// Node example (Bun / Deno: swap the serveStatic import source)
import { Hono } from 'hono'
import { serveStatic } from '@hono/node-server/serve-static'  // Bun: 'hono/bun', Deno: 'hono/deno'
import { remixRenderer } from 'hono-remix-middleware'

const app = new Hono()

app
  .use('/assets/*', serveStatic({ root: './dist/client' }))   // ← prod
  .use('*', remixRenderer({
    fetcher: (req) => app.fetch(req),
  }))
  .get('/', (c) =>
    c.render(
      <Document title='Home'>
        <HomePage />
      </Document>,
    ),
  )

export default app
```

```ts:server.ts
// Node example
import { serve } from '@hono/node-server'
import app from './app/app.tsx'

serve({ fetch: app.fetch, port: 3000 })
```

In dev, Vite handles requests under `/assets/*` (dev URLs are source paths like `/app/assets/entry.ts`), so `serveStatic` is not called; it's only needed for prod. The dev server combines Vite middleware mode with a Node server.

### Pattern 3: Native (no bundler — tsx / bun / deno)

Environments that can run TypeScript directly, such as `tsx`, `bun`, `deno`. Uses the `remix/assets` asset server directly as a Hono middleware.

```tsx:app/app.tsx
import { Hono } from 'hono'
import { createAssetServer } from 'remix/assets'
import { remixRenderer, remixAssetServer } from 'hono-remix-middleware'

const assets = createAssetServer({
  basePath: '/assets',
  rootDir: process.cwd(),
  fileMap: {
    'app/*path': 'app/*path',
    'node_modules/*path': 'node_modules/*path',
  },
  allow: ['app/assets/**', 'app/ui/**', 'node_modules/**'],
  deny: ['app/**/*.server.*'],
  sourceMaps: process.env.NODE_ENV === 'development' ? 'external' : undefined,
})

const app = new Hono()

app
  .use('/assets/*', remixAssetServer(assets))                  // ← Remix asset server
  .use('*', remixRenderer({
    fetcher: (req) => app.fetch(req),
  }))
  .get('/', (c) =>
    c.render(
      <Document title='Home'>
        <HomePage />
      </Document>,
    ),
  )

export default app
```

```ts:app/assets/entry.ts
import { run } from 'remix/ui'

run({
  async loadModule(moduleUrl, exportName) {
    const mod = await import(moduleUrl)
    return mod[exportName]
  },
  async resolveFrame(src, signal, target) {
    const headers = new Headers({ accept: 'text/html' })
    if (target) headers.set('x-remix-target', target)
    const response = await fetch(src, { credentials: 'same-origin', headers, signal })
    return response.body ?? response.text()
  },
})
```

The asset server compiles URLs like `/assets/app/ui/counter.tsx` at runtime and serves them, so the client's dynamic `import()` works directly. Just be careful to adjust `fileMap`/`allow` according to Bun's workspace install structure.

---

## License

MIT
