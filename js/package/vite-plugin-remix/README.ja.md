# vite-plugin-remix

Remix v3 のクライアントバンドルとハイドレーションを Vite で扱うためのミニマルなプラグインです。

参考: 任意のフレームワークでの SSR については、[`hono-remix-middleware`](../hono-remix-middleware/README.md) を参照してください。

## 機能

- Vite の `client` 環境を登録し、単一ファイルからクライアントエントリをビルドします
- 各 `*.client.tsx` を rollup に **個別のチャンク** として出力させます (Remix のアセットサーバーに相当するコンポーネント単位の遅延読み込み)
- 開発時/本番時でスクリプト URL を切り替える `<Script>` コンポーネント
- `import.meta.glob` ローダーを `remix/ui#run` に渡すための `boot()` ヘルパー

## インストール

```sh
pnpm add -D vite-plugin-remix
# peer: vite, remix
```

## クイックスタート

以下の `app` に指定するディレクトリは、`src` を含む任意のディレクトリに設定できます。

### `vite.config.ts`

```ts
import { remix } from 'vite-plugin-remix'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' })],
})
```

### `app/assets/entry.ts` (クライアントエントリ)

```ts
import { boot } from 'vite-plugin-remix/client'

boot({
  components: import.meta.glob('/app/**/*.client.tsx'),
})
```

### `<Script>` コンポーネント (SSR HTML に挿入)

- URL はプロジェクトごとに変わるため、明示的に設定する必要があります
- `devSrc` = Vite 開発サーバーが `clientEntry` を解決するプロジェクト相対 URL
- `prodSrc` = ビルドされたエントリの公開 URL (プラグインの `entryFileNames` に対応)

`<Script>` は `import.meta.env.DEV` によってこの2つを切り替えます:

| 環境              | 出力                                                                                              |
| ----------------- | ------------------------------------------------------------------------------------------------- |
| dev (`vite dev`)    | `<script type="module" src={devSrc}></script>` — Vite 開発サーバーが変換後のソース TS を配信します    |
| prod (`vite build`) | `<script type="module" src={prodSrc}></script>` — ビルドされたチャンクを静的配信します               |

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
  clientEntry: 'app/assets/entry.ts', // クライアントエントリへの相対パス
  clientOutDir: 'dist/client', // ビルド出力ディレクトリ
  entryFileNames: 'assets/entry.js', // エントリチャンクのファイル名 (デフォルトはハッシュなし)
})
```

| オプション         | デフォルト        | 目的                                                                                                                                                                                              |
| ----------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `clientEntry`     | **必須**          | rollup の入力。`boot()` を呼び出すファイルです。                                                                                                                                                 |
| `clientOutDir`    | `dist/client`     | クライアント環境のビルド出力先。静的ホスト (例: `serveStatic`) が参照するディレクトリです。                                                                                                      |
| `entryFileNames`  | `assets/entry.js` | メインエントリの出力ファイル名。デフォルトはハッシュなしの固定名で、マニフェストを使わずに SSR HTML から参照できます。キャッシュバスティングを行う場合は `assets/entry.[hash].js` などに変更し、SSR から Vite マニフェストを読むルートを別途設定してください。 |

`chunkFileNames` / `assetFileNames` はハッシュ付きで固定されています (コンポーネントチャンクなど)。

## ビルド出力

```text
dist/client/
├── .vite/manifest.json                 # キャッシュバスティング / 動的解決用 (コンシューマーがオプションで参照)
├── assets/
│   ├── entry.js                        # メインエントリ (固定名)
│   ├── counter.client-XXX.js           # *.client.tsx ごとに1チャンク
│   ├── todo.client-XXX.js
│   └── css-mixin-XXX.js                # 共有チャンク
```

## ライセンス

MIT