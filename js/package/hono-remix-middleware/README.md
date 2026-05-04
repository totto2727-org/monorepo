# hono-remix-middleware

Hono の組み込み [`jsxRenderer`](https://hono.dev/docs/middleware/builtin/jsx-renderer) と同じ作法で **Remix v3 の `remix/ui` SSR** を呼び出すための middleware。

ランタイム / バンドラ非依存で、Cloudflare Workers / Node / Bun / Deno のいずれでも動きます。

## インストール

```sh
pnpm add hono-remix-middleware
# peer: hono, remix
```

## API

### `remixRenderer(options)`

Hono の `c.render()` をひっかけて `remix/ui/server` の `renderToStream` を呼び、`text/html` の Response を返す middleware を生成。

```ts
import { remixRenderer } from 'hono-remix-middleware'

app.use(
  '*',
  remixRenderer<{ title?: string }>({
    fetcher: (request) => app.fetch(request),
    wrap: (content, { title }) => <Layout title={title}>{content}</Layout>,
  }),
)
```

| Option | 型 | 説明 |
| -- | -- | -- |
| `fetcher` | `(req: Request) => Promise<Response>` | 入れ子 SSR (`remix/ui/server` の `resolveFrame`) で frame を再取得するときに呼ばれる。通常 `(req) => app.fetch(req)` を closure で渡す。 |
| `wrap` | `(content, props) => RemixNode` | 任意。`c.render(content, props)` の content を Layout / Document で包む関数。省略時は content をそのまま SSR。 |
| `resolveClientEntry` | `(entryId, component) => { exportName, href }` | 任意。clientEntry の ID から `moduleUrl`/`exportName` を計算するフック。デフォルトは `/assets/` プレフィックスを剥がすだけ。 |

`c.render()` の型は consumer 側で `declare module 'hono'` して augmentation する形を想定:

```ts
import type { RemixNode } from 'remix/ui'

declare module 'hono' {
  interface ContextRenderer {
    (content: RemixNode, props?: { title?: string }): Response
  }
}
```

`title` 等を持たない最小形でよければ `import 'hono-remix-middleware/types'` で props なしのデフォルト augmentation が読み込まれる。

### `remixAssetServer(assets)`

`hono-remix-middleware/asset-server` から import。`remix/assets#createAssetServer` で作った `AssetServer` インスタンスを Hono middleware にラップ。Native パターン（バンドラなし）専用。

```ts
import { createAssetServer } from 'remix/assets'
import { remixAssetServer } from 'hono-remix-middleware/asset-server'

const assets = createAssetServer({
  basePath: '/assets',
  rootDir: process.cwd(),
  fileMap: {
    'app/*path': 'app/*path',
    'node_modules/*path': 'node_modules/*path',
  },
  allow: ['app/assets/**', 'app/ui/**', 'node_modules/**'],
  deny: ['app/**/*.server.*'],
})

app.use('/assets/*', remixAssetServer(assets))
```

`remix/assets` は Node の `fs` / `path` に依存するため、Cloudflare Workers では使えません。Workers 用には Workers Assets binding を使ってください（後述パターン 1）。

---

## 構成パターン

| | Vite + Cloudflare | Vite + Node/Bun/Deno | Native (no bundler) |
| -- | -- | -- | -- |
| クライアントバンドル | `vite-plugin-remix` | `vite-plugin-remix` | なし — runtime 直実行 |
| アセット配信 (prod) | wrangler `assets` binding | Hono `serveStatic` | `remixAssetServer` |
| アセット配信 (dev) | Vite dev server | Vite dev server | `remixAssetServer` |
| SSR 実行先 | Workers | `@hono/node-server` 等 | tsx / bun / deno |

### パターン 1: Vite + Cloudflare Workers

`vite-plugin-remix` でクライアントバンドル、`wrangler.jsonc` の `assets` binding で配信。本リポジトリの `js/app/my-remix-app` がこの構成。

```ts
// vite.config.ts
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

```jsonc
// wrangler.jsonc
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

```tsx
// app/app.tsx
import { Hono } from 'hono'
import { remixRenderer } from 'hono-remix-middleware'

const app = new Hono()

app
  .use('*', remixRenderer<{ title?: string }>({
    fetcher: (req) => app.fetch(req),
    wrap: (content, { title }) => <Layout title={title}>{content}</Layout>,
  }))
  .get('/', (c) => c.render(<HomePage />, { title: 'Home' }))

export default app
```

```ts
// app/entry.worker.ts
import app from './app.tsx'
export default app
```

クライアントエントリは `vite-plugin-remix` の `boot()` ヘルパで:

```ts
// app/assets/entry.ts
import { boot } from 'vite-plugin-remix/client'

boot({
  components: import.meta.glob('/app/**/*.client.tsx'),
})
```

`Document` の `<script>` は `vite-plugin-remix/client` の `<Script>` を使い、`vite.config.ts` の `clientEntry` / `entryFileNames` と URL を一致させる:

```tsx
import { Script } from 'vite-plugin-remix/client'

// <Script devSrc='/app/assets/entry.ts' prodSrc='/assets/entry.js' />
```

詳細は [`vite-plugin-remix` の README](../vite-plugin-remix/README.md) 参照。

### パターン 2: Vite + Node / Bun / Deno

`vite-plugin-remix` のビルド出力 (`dist/client/`) を Hono の `serveStatic` で配信、Hono を Node/Bun/Deno のサーバランタイム上で起動。

```ts
// vite.config.ts
import { remix } from 'vite-plugin-remix'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' })],
})
```

```ts
// app/app.tsx (Node の例)
import { Hono } from 'hono'
import { serveStatic } from '@hono/node-server/serve-static'  // Bun: 'hono/bun', Deno: 'hono/deno'
import { remixRenderer } from 'hono-remix-middleware'

const app = new Hono()

app
  .use('/assets/*', serveStatic({ root: './dist/client' }))   // ← prod 用
  .use('*', remixRenderer<{ title?: string }>({
    fetcher: (req) => app.fetch(req),
    wrap: (content, { title }) => <Layout title={title}>{content}</Layout>,
  }))
  .get('/', (c) => c.render(<HomePage />, { title: 'Home' }))

export default app
```

```ts
// server.ts (Node)
import { serve } from '@hono/node-server'
import app from './app/app.tsx'

serve({ fetch: app.fetch, port: 3000 })
```

dev では Vite が `/assets/*` 配下のリクエストを受けない（dev 用 URL は `/app/assets/entry.ts` 等の source パス）ので `serveStatic` は呼ばれず、prod でのみ実体が要求される。dev サーバは Vite middleware mode + Node サーバを組合せる。

### パターン 3: Native（バンドラ不使用 — tsx / bun / deno）

`tsx`, `bun`, `deno` などが TypeScript を直接実行できる環境。`vite-plugin-remix` 不要、`remix/assets` の asset server をそのまま Hono middleware として使う。

```tsx
// app/app.tsx
import { Hono } from 'hono'
import { createAssetServer } from 'remix/assets'
import { remixRenderer, remixAssetServer } from 'hono-remix-middleware'
// remixAssetServer は 'hono-remix-middleware/asset-server' から個別 import でも可

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
  .use('*', remixRenderer<{ title?: string }>({
    fetcher: (req) => app.fetch(req),
    wrap: (content, { title }) => <Layout title={title}>{content}</Layout>,
  }))
  .get('/', (c) => c.render(<HomePage />, { title: 'Home' }))

export default app
```

クライアントエントリは素朴な `import()`:

```ts
// app/assets/entry.ts
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

`/assets/app/ui/counter.tsx` のような URL を asset server がランタイム コンパイルして配信するので、クライアントの動的 `import()` がそのまま通る。pnpm の hoist 構造に合わせて `fileMap` / `allow` を調整する点だけ注意。

実装サンプル: `js/app/my-remix-app2/app/assets.ts` 参照。

---

## ライセンス

MIT
