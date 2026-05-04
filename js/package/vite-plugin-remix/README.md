# vite-plugin-remix

Remix v3 のクライアントバンドル + ハイドレーションを Vite で扱うための minimal プラグイン。

## 何をしてくれるか

- Vite の `client` environment を登録し、クライアントエントリを 1 ファイルから build
- 各 `*.client.tsx` を rollup に **個別 chunk** として吐かせる（Remix の asset server と同等の per-component lazy loading）
- dev / prod でスクリプト URL を切替える `<Script>` コンポーネント
- `import.meta.glob` の loader を `remix/ui#run` に渡すための `boot()` ヘルパ

ここで言う「クライアント」は user agent 上で実行される側（典型的にはブラウザだが Tauri / Electron の WebView も含む）を指し、SSR が走る Worker / Node 側と区別しています。

`renderToStream` 側 (SSR) の差し替えは [`hono-remix-middleware`](../hono-remix-middleware/README.md) を参照。

## インストール

```sh
pnpm add -D vite-plugin-remix
# peer: vite, remix
```

## クイックスタート

以下で `app` と指定している箇所は `src` を含め任意のディレクトリで設定可能。

### `vite.config.ts`

```ts
import { remix } from 'vite-plugin-remix'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [
    remix({ clientEntry: 'app/assets/entry.ts' }),
  ],
})
```

### `app/assets/entry.ts`（クライアントエントリ）

```ts
import { boot } from 'vite-plugin-remix/client'

boot({
  components: import.meta.glob('/app/**/*.client.tsx'),
})
```

### `<Script>` コンポーネント (SSR HTML 内に挿入)

```tsx
import { Script } from 'vite-plugin-remix/client'

export function Document() {
  return ({ children }) => (
    <html>
      <head>...</head>
      <body>
        {children}
        {/* devSrc は vite.config.ts の clientEntry に対応する project-relative URL */}
        {/* prodSrc は entryFileNames（既定 'assets/entry.js'）に対応する公開 URL */}
        <Script devSrc='/app/assets/entry.ts' prodSrc='/assets/entry.js' />
      </body>
    </html>
  )
}
```

- `devSrc` = Vite dev server が `clientEntry` を解決する project-relative URL
- `prodSrc` = ビルド済みエントリの公開 URL（プラグインの `entryFileNames` に対応）

`<Script>` は `import.meta.env.DEV` で両者を切替:

| 環境 | 出力 |
| -- | -- |
| dev (`vite dev`) | `<script type="module" src={devSrc}></script>` — Vite dev server が source TS を変換配信 |
| prod (`vite build`) | `<script type="module" src={prodSrc}></script>` — ビルド済み chunk を静的配信 |

両 URL は **必須**。デフォルトを持たず、プラグインの `clientEntry` / `entryFileNames` 設定との対応関係を呼び出し-site で明示させます。

## オプション

```ts
remix({
  clientEntry: 'app/assets/entry.ts',      // クライアントエントリの相対パス
  clientOutDir: 'dist/client',             // build 出力先
  entryFileNames: 'assets/entry.js',       // エントリ chunk のファイル名 (no hash by default)
})
```

| オプション | デフォルト | 用途 |
| -- | -- | -- |
| `clientEntry` | **必須** | rollup の input。`boot()` を呼ぶファイル。 |
| `clientOutDir` | `dist/client` | client environment の build 出力先。静的ホスト（`serveStatic` 等）の root に向ける場所。 |
| `entryFileNames` | `assets/entry.js` | メインエントリの出力ファイル名。デフォルトはハッシュなし固定で、SSR HTML から manifest なしで参照可能。cache busting したい場合は `assets/entry.[hash].js` 等に変更し、Vite manifest を SSR から読む経路を別途用意する。 |

`chunkFileNames` / `assetFileNames` はハッシュ付きで固定（component chunk 等）。

## ビルド出力

```text
dist/client/
├── .vite/manifest.json                 # cache busting / 動的解決用 (consumer は任意で参照)
├── assets/
│   ├── entry.js                        # メインエントリ (固定名)
│   ├── counter.client-XXX.js           # *.client.tsx ごとに 1 chunk
│   ├── todo.client-XXX.js
│   └── css-mixin-XXX.js                # 共通 chunk
```

## クライアントエントリの URL とクライアント側の動作

SSR (`hono-remix-middleware` の `resolveClientEntry`) が HTML に書き込む `moduleUrl` は **lookup key** です。実際のネットワーク URL は `import.meta.glob` の loader closure 内に隠蔽され、Vite が build 時に書き換えています:

```text
SSR HTML moduleUrl                    →  components map key
  /app/ui/counter.client.tsx          →  /app/ui/counter.client.tsx
                                              ↓ (loader closure 内)
                                         Vite が build 時に書換
                                              ↓
                                         /assets/counter.client-XXX.js
                                              ↓
                                         静的配信
```

そのため SSR 側は manifest を読む必要がありません。manifest が要るのは `entryFileNames` をハッシュ付きにする等、URL を build 後に解決したい場合だけ。

## Vite environment の build 順

`builder.buildApp` は触っていません。Vite のデフォルト builder が全 environment を build しますが順序は保証されません。現アーキテクチャでは他 environment が client manifest を読まないので順序非依存。

manifest を読む構成にする場合は consumer 側 (`vite.config.ts`) で `builder.buildApp` を上書きして `client` を先に build してください:

```ts
defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' })],
  builder: {
    async buildApp(builder) {
      const client = builder.environments.client
      if (client) await builder.build(client)
      for (const [name, env] of Object.entries(builder.environments)) {
        if (name === 'client') continue
        await builder.build(env)
      }
    },
  },
})
```

`buildApp` は singleton hook（後勝ち）なので、library plugin 側からは触らない方針にしています。

## ライセンス

MIT
