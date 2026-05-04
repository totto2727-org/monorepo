# vite-plugin-remix

Remix v3 のクライアントバンドル + ハイドレーションを Vite で扱うための minimal プラグイン。

参考：任意のフレームワークにおけるSSRについては [`hono-remix-middleware`](../hono-remix-middleware/README.md) を参照。

## 何をするか？

- Vite の `client` environment を登録し、クライアントエントリを 1 ファイルから build
- 各 `*.client.tsx` を rollup に **個別 chunk** として吐かせる（Remix の asset server と同等の per-component lazy loading）
- dev / prod でスクリプト URL を切替える `<Script>` コンポーネント
- `import.meta.glob` の loader を `remix/ui#run` に渡すための `boot()` ヘルパ

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
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' })],
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

- プロジェクトによってURLが変わるため、明示的に設定する必要がある
- `devSrc` = Vite dev server が `clientEntry` を解決する project-relative URL
- `prodSrc` = ビルド済みエントリの公開 URL（プラグインの `entryFileNames` に対応）

`<Script>` は `import.meta.env.DEV` で両者を切替:

| 環境                | 出力                                                                                     |
| ------------------- | ---------------------------------------------------------------------------------------- |
| dev (`vite dev`)    | `<script type="module" src={devSrc}></script>` — Vite dev server が source TS を変換配信 |
| prod (`vite build`) | `<script type="module" src={prodSrc}></script>` — ビルド済み chunk を静的配信            |

```tsx
import { Script } from 'vite-plugin-remix/client'

export function Document() {
  return ({ children }) => (
    <html>
      <head>...</head>
      <body>
        {children}
        <Script devSrc='/app/assets/entry.ts' prodSrc='/assets/entry.js' />
      </body>
    </html>
  )
}
```

## オプション

```ts
remix({
  clientEntry: 'app/assets/entry.ts', // クライアントエントリの相対パス
  clientOutDir: 'dist/client', // build 出力先
  entryFileNames: 'assets/entry.js', // エントリ chunk のファイル名 (no hash by default)
})
```

| オプション       | デフォルト        | 用途                                                                                                                                                                                                                     |
| ---------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `clientEntry`    | **必須**          | rollup の input。`boot()` を呼ぶファイル。                                                                                                                                                                               |
| `clientOutDir`   | `dist/client`     | client environment の build 出力先。静的ホスト（`serveStatic` 等）の root に向ける場所。                                                                                                                                 |
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

## ライセンス

MIT
