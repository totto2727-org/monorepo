# hono-remix-middleware

Hono 組み込みの [`jsxRenderer`](https://hono.dev/docs/middleware/builtin/jsx-renderer) と同じパターンで、**Remix v3 の `remix/ui` SSR** を呼び出すミドルウェアです。

ランタイム／バンドラーに依存せず、Cloudflare Workers / Node / Bun / Deno で動作します。

## インストール

```sh
pnpm add hono-remix-middleware
```

## API

### `remixRenderer(options)`

Hono の `c.render()` を拡張するミドルウェアファクトリー関数。

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

| オプション           | 型                                             | 説明                                                                                                                                                        |
| -------------------- | ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `fetcher`            | `typeof fetch`                                 | ネストされた SSR でフレームを再取得する際に呼ばれます（`remix/ui/server` の `resolveFrame`）。通常はクロージャとして `(req) => app.fetch(req)` を渡します。 |
| `resolveClientEntry` | `(entryId, component) => { exportName, href }` | 省略可能。clientEntry ID から `moduleUrl`/`exportName` を計算するフック。デフォルトは `/assets/` プレフィックスを除去します。                               |

シンプルな実装で、`c.render(content)` の `content` をそのまま `renderToStream` に渡します。Layout / Document の構成はハンドラーの責務です。

### `remixAssetServer(assetServer)`

Remix v3 のアセットサーバーを統合するミドルウェアファクトリー関数。

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

注意: `remixAssetServer` は、TSX や Bun/Deno がファイルをバンドルせず直接実行する環境を想定しています。ファイルを操作するため Workers では動作しません。必要な場合は Vite プラグインでアセットを事前に準備する必要があります。

---

## アーキテクチャパターン

|                              | Vite + Cloudflare                | Vite + Node/Bun/Deno     | Native (バンドラーなし)       |
| ---------------------------- | -------------------------------- | ------------------------ | ----------------------------- |
| クライアントバンドル         | `vite-plugin-remix`              | `vite-plugin-remix`      | なし — ランタイム上で直接実行 |
| プロダクションのアセット配信 | wrangler `assets` バインディング | Hono `serveStatic`       | `remixAssetServer`            |
| 開発時のアセット配信         | Vite 開発サーバー                | Vite 開発サーバー        | `remixAssetServer`            |
| SSR 実行ターゲット           | Workers                          | `@hono/node-server` など | tsx / bun / deno              |

[`vite-plugin-remix` README](../vite-plugin-remix/README.md)

### パターン 1: Vite + Cloudflare Workers

`vite-plugin-remix` でクライアントをバンドルし、`wrangler.jsonc` の `assets` バインディングで配信します。

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

### パターン 2: Vite + Node / Bun / Deno

`vite-plugin-remix` のビルド出力（`dist/client/`）を Hono の `serveStatic` で配信し、Hono を Node/Bun/Deno サーバーランタイム上で実行します。

```ts:vite.config.ts
import { remix } from 'vite-plugin-remix'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' })],
})
```

```tsx:app/app.tsx
// Node の例（Bun / Deno では serveStatic のインポート元を切り替えてください）
import { Hono } from 'hono'
import { serveStatic } from '@hono/node-server/serve-static'  // Bun: 'hono/bun', Deno: 'hono/deno'
import { remixRenderer } from 'hono-remix-middleware'

const app = new Hono()

app
  .use('/assets/*', serveStatic({ root: './dist/client' }))   // ← プロダクション
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
// Node の例
import { serve } from '@hono/node-server'
import app from './app/app.tsx'

serve({ fetch: app.fetch, port: 3000 })
```

開発時は Vite が `/assets/*` 以下のリクエストを処理するため（開発 URL は `/app/assets/entry.ts` のようなソースパス）、`serveStatic` は呼ばれません。プロダクションでのみ必要です。開発サーバーは Vite のミドルウェアモードと Node サーバーを組み合わせます。

### パターン 3: Native（バンドラーなし — tsx / bun / deno）

`tsx`、`bun`、`deno` など、TypeScript を直接実行できる環境。`remix/assets` のアセットサーバーを Hono ミドルウェアとして直接使います。

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
  .use('/assets/*', remixAssetServer(assets))                  // ← Remix アセットサーバー
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

アセットサーバーは `/assets/app/ui/counter.tsx` のような URL を実行時にコンパイルして配信するため、クライアントの動的 `import()` が直接動作します。pnpm のホイスト構造に合わせて `fileMap`/`allow` を適宜調整してください。

---

## ライセンス

MIT
