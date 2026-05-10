# Research Note: hono-remix-cloudflare-example-structure

- **Identifier:** feed-platform-ms-01-workspace-foundation
- **Topic:** hono-remix-cloudflare-example-structure
- **Researcher:** researcher (single instance)
- **Created at:** 2026-05-06
- **Scope:** `js/app/hono-remix-v3-cloudflare-example/` の **最新ファイル構成・依存関係・設定値・実装パターン** をファイル単位で棚卸しし、ms-01 で起こす `feed-platform-web` / `identity-provider` 雛形が「そのまま踏襲すべき箇所」と「再考すべき箇所」を識別する

## Subject of investigation

intent-spec の確定事項 Q2.10 / Q2.12 / SC-9 が「`feed-platform-web` と `identity-provider` は **`js/app/hono-remix-v3-cloudflare-example` 最新構成踏襲**」と明示しているため (`docs/workflow/feed-platform-ms-01-workspace-foundation/intent-spec.md:71-72,79,147-148`)、その「踏襲対象の最新スナップショット」をファイル単位で固定する。具体的には:

- ディレクトリ / ファイル inventory (root + `app/` 全ファイル)
- `package.json` の依存・scripts・catalog 利用形態
- `tsconfig.json` の継承元と上書きポイント
- `vite.config.ts` 内 Vite+ `run.tasks` 定義 + Remix プラグイン + Cloudflare 統合プラグインの組み立て
- `wrangler.jsonc` の主要キー (compatibility / observability / assets binding / placement)
- `app/entry.worker.ts` を起点とする Hono アプリの組み立て方
- `app/app.tsx` `app/routes.ts` の役割分担と Remix v3 SSR との統合点
- ビルド出力先と `vp run -r build` 上の扱い
- ms-01 雛形作成時の踏襲 / 再考マッピング

スコープ外 (他リサーチャー責務 / out-of-scope): wrangler のマルチエントリ詳細 (バックエンド側の `worker.ts` × N 構造) / Vite+ task 全般の規約 / Effect レイヤーパターン。

## Findings

### F1. ルートディレクトリ inventory (`js/app/hono-remix-v3-cloudflare-example/`)

`ls -la` 実測結果より、リポジトリ管理対象は **8 ファイル + 1 サブディレクトリ** のみ (`node_modules/` を除く):

| パス             | 役割                                                                                     |
| ---------------- | ---------------------------------------------------------------------------------------- |
| `.gitignore`     | `dist/` `.wrangler/` の 2 行のみ                                                         |
| `CLAUDE.md`      | プロジェクト固有ガイダンス (Cloudflare Workers + Hono + Remix v3 / pnpm 使用 / Bun 禁止) |
| `README.md`      | アーキテクチャ解説 + SSR シーケンス図                                                    |
| `package.json`   | 依存・scripts                                                                            |
| `tsconfig.json`  | TypeScript 設定                                                                          |
| `vite.config.ts` | Vite+ 設定 (Remix + Cloudflare プラグイン + `run.tasks`)                                 |
| `wrangler.jsonc` | Cloudflare Workers 設定                                                                  |
| `app/`           | アプリ実体 (後述)                                                                        |

特筆点:

- **`public/` ディレクトリは存在しない** (CLAUDE.md L46 が "Add `public/` only when you need to ship static files" と明示)。CF Workers Assets の出力は `dist/client/` にビルド時生成されるのみ
- **`src/` ディレクトリは存在せず**、すべて `app/` 配下に集約 (Remix v3 / Hono が JSX + SSR + ルート定義を一括するため、Worker 用 `src/` 分割は採用していない)
- **`tests/` ディレクトリも存在しない** (テストは現状未整備)

### F2. `app/` 配下 inventory

`ls -la app/ app/ui/ app/assets/` 実測結果:

```text
app/
├── app.tsx                          # Hono アプリ + ルート定義 + middleware 登録 (790 bytes)
├── entry.worker.ts                  # CF Worker エントリ — `app.tsx` を default re-export (48 bytes)
├── routes.ts                        # frame 名のレジストリ + isFrameRequest ヘルパ (1040 bytes)
├── assets/
│   └── entry.ts                     # クライアントエントリ (vite-plugin-remix `boot()`)
└── ui/
    ├── content-layout.tsx           # ナビ + main + Frame 配置の Layout (PageOrFrame factory 適用)
    ├── counter.client.tsx           # `*.client.tsx` 規約のインタラクティブコンポーネント
    ├── document.tsx                 # `<html>/<head>/<body>` + `<Script>` (dev/prod 切替)
    ├── frame-link.tsx               # `<a rmx-target rmx-src>` 型付きアンカー
    ├── page-or-frame.tsx            # フルページ vs フラグメント返却を切り替える HOC
    └── todo.client.tsx              # インタラクティブ TODO リスト
```

注: README L29-33 (アプリ root の `README.md`) は `app/controllers/home.tsx` `app/controllers/auth.tsx` `app/utils/render.tsx` に言及しているが、**実装コードには `controllers/` も `utils/` も存在しない** (実体は `app/ui/*` に集約)。README L50 (アプリ root の README.md ではなく `js/app/hono-remix-v3-cloudflare-example/README.md:50`) は逆に「controller / utils レイヤーも持っていません」と明記しており、CLAUDE.md (`js/app/hono-remix-v3-cloudflare-example/CLAUDE.md:30-41`) との間で**ガイダンスの内部矛盾**がある (タイポ / 改修取りこぼしの可能性大)。

### F3. `package.json` (`js/app/hono-remix-v3-cloudflare-example/package.json:1-26`)

```json
{
  "name": "hono-remix-v3-cloudflare-example",
  "private": true,
  "type": "module",
  "imports": { "#@/*": "./app/*" },
  "scripts": {
    "deploy": "wrangler deploy",
    "dev": "vp dev",
    "start": "wrangler dev",
    "typecheck": "tsgo --noEmit"
  },
  "dependencies": {
    "effect": "catalog:effect",
    "hono": "catalog:hono",
    "hono-remix-middleware": "workspace:*",
    "remix": "catalog:remix",
    "vite-plugin-remix": "workspace:*"
  },
  "devDependencies": {
    "@cloudflare/vite-plugin": "catalog:cloudflare",
    "@totto2727/fp": "workspace:*",
    "wrangler": "catalog:cloudflare"
  }
}
```

要点:

- **すべて catalog 経由** (`pnpm-workspace.yaml` の `effect` / `hono` / `remix` / `cloudflare` カタログ)。直接版指定なし → 既存規約完全準拠
- **2 つの workspace ローカルパッケージに依存**: `hono-remix-middleware` (Hono の `c.render` を Remix v3 SSR に橋渡し) / `vite-plugin-remix` (Vite の client environment 設定 + `boot()` ランタイム)
- **`#@/*` → `./app/*`** の Node.js imports 経由パスエイリアス (CLAUDE.md グローバルガイドライン §Path Aliases に整合)
- **scripts は 4 個のみ**: `dev` (Vite 経由 dev server) / `start` (wrangler dev = workerd 直接) / `deploy` (wrangler deploy) / `typecheck` (tsgo)。`build` / `check` / `fix` / `test` は **package.json の scripts ではなく `vite.config.ts` の `run.tasks` 側で定義** (= Vite+ 規約)

### F4. `tsconfig.json` (`js/app/hono-remix-v3-cloudflare-example/tsconfig.json:1-8`)

```jsonc
{
  "extends": ["@totto2727/fp/tsconfig/vite"],
  "compilerOptions": { "jsxImportSource": "remix/ui" },
}
```

実質 2 行で完結:

- 継承元 `@totto2727/fp/tsconfig/vite` (`js/package/fp/src/tsconfig/vite.json:1-26`) は `@tsconfig/strictest` を再 extends し、`vite-plus/client` types / `target: esnext` / `module: esnext` / `moduleResolution: bundler` / `jsx: react-jsx` / `verbatimModuleSyntax: true` / `noUncheckedSideEffectImports: true` / `erasableSyntaxOnly: true` 等を一括適用する
- 上書きは `jsxImportSource: "remix/ui"` のみ。これにより `<html>` `<button mix={...}>` 等の JSX が Remix v3 のランタイムにバインドされる
- **`paths`** は **指定していない** (`#@/*` は package.json の `imports` 側で解決)

### F5. `vite.config.ts` (`js/app/hono-remix-v3-cloudflare-example/vite.config.ts:1-15`)

```ts
import { cloudflare } from '@cloudflare/vite-plugin'
import { remix } from 'vite-plugin-remix'
import { defineConfig } from 'vite-plus'

export default defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' }), cloudflare()],
  run: {
    tasks: {
      build: {
        command: 'vp build',
        input: [{ auto: true }, '!.wrangler/**', '!dist/**'],
      },
    },
  },
})
```

要点:

- **`defineConfig` は `vite-plus` から import** (Vite+ 由来の拡張型を含む)
- **plugin 順序**: `remix({ clientEntry: 'app/assets/entry.ts' })` → `cloudflare()`。Remix プラグインは Vite の `client` environment に対する rollup input / outDir / entryFileNames を設定する (`js/package/vite-plugin-remix/src/plugin.ts:42-65`)。`cloudflare()` は `@cloudflare/vite-plugin` (catalog `cloudflare`) で、Vite を CF Workers 上で走らせる
- **Vite+ task は `build` のみ定義**。`check` / `fix` / `test` / `setup` 等はこのファイルでは定義されていない (= Vite+ デフォルトに委ねる)
- **`input` の `!.wrangler/**` `!dist/**`** は Vite+ のタスクキャッシュ対象から成果物・wrangler 一時ファイルを除外。`.gitignore` (`js/app/hono-remix-v3-cloudflare-example/.gitignore:1-2`) と完全に同じ 2 ディレクトリを除外している

### F6. `wrangler.jsonc` (`js/app/hono-remix-v3-cloudflare-example/wrangler.jsonc:1-20`)

```jsonc
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "compatibility_date": "2026-02-01",
  "compatibility_flags": ["nodejs_compat"],
  "main": "./app/entry.worker.ts",
  "name": "hono-remix-v3-cloudflare-example",
  "assets": {
    "directory": "./dist/client",
    "binding": "ASSETS",
    "not_found_handling": "none",
    "run_worker_first": false,
  },
  "observability": { "enabled": true, "head_sampling_rate": 1 },
  "placement": { "mode": "smart" },
}
```

要点:

- **`main` が TypeScript ファイルを直接指定** (`./app/entry.worker.ts`)。wrangler の TS 解釈はビルドツール側 (Vite+) の協調に依存 (= `vp dev` モードでは Vite が `entry.worker.ts` を `client/server` 環境で変換、`wrangler dev` モードでは wrangler 内蔵の esbuild が処理)
- **`assets` ブロックで Vite ビルド成果物 (`dist/client`) を Workers Assets binding `ASSETS` として配信**。`not_found_handling: "none"` により asset 404 時は Worker (= Hono アプリ) 側にフォールスルー、`run_worker_first: false` でアセット先・Worker 後の順
- **`compatibility_flags: ["nodejs_compat"]`** は Hono / Effect / `crypto.randomUUID` 等の Node 互換 API のため
- **`vars` / `bindings` (D1 / KV / R2 / Queues 等) は一切設定なし** — 純粋な Hello World 検証用
- **`placement.mode: "smart"`** は smart placement 機能を有効化

### F7. `app/entry.worker.ts` (`js/app/hono-remix-v3-cloudflare-example/app/entry.worker.ts:1-3`)

```ts
import app from './app.tsx'

export default app
```

3 行のみ。Worker ハンドラ (`fetch` メソッドを持つオブジェクト) としては Hono 側の `Hono` インスタンスがそのまま `fetch(request, env, ctx)` シグネチャを満たすため、**追加の adapter / wrapper は不要**で `app` をそのまま `default export` している。

### F8. `app/app.tsx` (`js/app/hono-remix-v3-cloudflare-example/app/app.tsx:1-37`)

Hono のルート定義・middleware 登録が **1 ファイルに集約**される設計。

主要構造:

- `app.use(logger())` — 標準 Hono ロガー
- `app.use(contextStorage())` — `hono/context-storage`。AsyncLocalStorage でリクエストコンテキストを `getContext()` 経由で任意箇所から参照可能にする (`routes.ts` の `isFrameRequest` 等が利用)
- `app.use('*', remixRenderer({ fetcher: ... }))` — `hono-remix-middleware` の SSR ミドルウェア。`c.setRenderer(content => Response)` を仕込み、ルートハンドラから `c.render(<JSX/>)` で Remix v3 SSR ストリームを返せるようにする
  - `fetcher` は `(input) => Promise.resolve(app.fetch(input instanceof Request ? input : new Request(input)))` で **自身を再帰呼び出し** = Frame の resolveFrame でアプリ内 URL を再 fetch する用
- ルート定義は `app.get('/', c => c.render(<PageOrFrame .../>)) ` / `app.get('/todo', ...)` の 2 つのみ
- すべてが `app/ui/content-layout.tsx` と `app/ui/todo.client.tsx` に依存

### F9. `app/routes.ts` (`js/app/hono-remix-v3-cloudflare-example/app/routes.ts:1-27`)

**ルーティング定義ファイルではなく、Frame 名レジストリ + 判定ヘルパ**:

```ts
export const frames = { content: 'content' } as const
export type FrameName = (typeof frames)[keyof typeof frames]
export const isFrameRequest = (frame: FrameName): boolean => getContext().req.header('x-remix-target') === frame
```

`<Frame name="content">` ↔ `<a rmx-target="content">` を **コードレベルで型整合させる** ためのシングル・ソース・オブ・トゥルース。実際のルート (URL → ハンドラ) 定義は前述の `app.tsx` 側で `app.get(...)` として行う (= 命名「routes.ts」と実装内容のズレ。Remix の `routes.ts` 命名規約と紛らわしい点に注意)。

### F10. UI 層構造 (`app/ui/*`)

| ファイル             | 責務                                                                                                                                                                          |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `document.tsx`       | `<html>/<head>/<body>` + `<Script devSrc='/app/assets/entry.ts' prodSrc='/assets/entry.js'>` (`vite-plugin-remix/client` の `<Script>` が dev/prod 切替)                      |
| `content-layout.tsx` | ヘッダー nav + main + 内部に `<Counter>` + `<Frame name={frames.content}>` を配置。最下部で `createPageOrFrame(frames.content, Layout)` を export 値 `PageOrFrame` として公開 |
| `page-or-frame.tsx`  | `createPageOrFrame` HOC。Frame 再入リクエスト (`isFrameRequest`) のときは children のみ、通常リクエストのときは Layout 全体をレンダリング                                     |
| `frame-link.tsx`     | `<a href rmx-target rmx-src>` の **3 属性必須型付きアンカー**。`rmx-target` は `FrameName` 型で typo を型エラー化                                                             |
| `counter.client.tsx` | `clientEntry('/assets/app/ui/counter.client.tsx#Counter', ...)` でクライアントハイドレーション対象を宣言。`mix` / `css` / `on` が Remix v3 のスタイル + イベントハンドラ DSL  |
| `todo.client.tsx`    | 同上。Effect の `Predicate` / `String` / `Array` を使ったフォーム処理を含む                                                                                                   |

`*.client.tsx` 命名規約は `app/assets/entry.ts` の `import.meta.glob('/app/**/*.client.tsx')` (`app/assets/entry.ts:7-9`) と対応するため、**ファイル名サフィックスがビルド時にハイドレーション対象を決定する**。

### F11. `app/assets/entry.ts` (`js/app/hono-remix-v3-cloudflare-example/app/assets/entry.ts:1-10`)

```ts
import { boot } from 'vite-plugin-remix/client'

boot({
  components: import.meta.glob('/app/**/*.client.tsx'),
})
```

`boot()` は `vite-plugin-remix/client` (`js/package/vite-plugin-remix/src/client/index.tsx`) が提供するクライアントブート関数。`import.meta.glob` は Vite のコンパイル時構文のため、**この呼び出し位置はアプリ側 (バンドラから見える consumer source) でなければならない** (コメント L4-6 が明記)。

### F12. ビルド出力と `vp run -r build` での扱い

- **ビルド出力先は `dist/`**。`vite-plugin-remix` の `clientOutDir` デフォルトが `dist/client`、`@cloudflare/vite-plugin` が Worker バンドルを `dist/<workerName>` 等に出力 (実測ログは未取得だが `wrangler.jsonc` の `assets.directory: "./dist/client"` から `dist/client/` の存在は確定)
- **`.gitignore` で `dist/` `.wrangler/` を除外**
- **`vp run -r build`** はワークスペース全体の `build` task を再帰実行する。本プロジェクトは `vite.config.ts` の `run.tasks.build` (`vite.config.ts:7-12`) で `command: 'vp build'` + `input` キャッシュキーから `dist/**` `.wrangler/**` を除外しているため、**変更がなければキャッシュヒット**で no-op
- `package.json:8` の `scripts.dev` も `vp dev` であり、`vp` 経由 / Vite+ 規約一貫

### F13. `setup` task は **未定義**

- `vite.config.ts` の `run.tasks` には `build` しか登録されていない
- `package.json` の scripts にも `setup` 相当はなし
- 結論: 本プロジェクトには `setup` task は **存在しない** (ms-01 で `setup` を追加するか否かは別判断)

## Sources

- 必読ドキュメント
  - `docs/workflow/feed-platform-ms-01-workspace-foundation/intent-spec.md:71-72,79,147-148` (踏襲対象指定)
  - `docs/roadmap/feed-platform/milestones/ms-01-workspace-foundation.md:18-22` (到達点定性記述)
- 例 app root
  - `js/app/hono-remix-v3-cloudflare-example/package.json:1-26`
  - `js/app/hono-remix-v3-cloudflare-example/tsconfig.json:1-8`
  - `js/app/hono-remix-v3-cloudflare-example/vite.config.ts:1-15`
  - `js/app/hono-remix-v3-cloudflare-example/wrangler.jsonc:1-20`
  - `js/app/hono-remix-v3-cloudflare-example/.gitignore:1-2`
  - `js/app/hono-remix-v3-cloudflare-example/CLAUDE.md:1-49`
  - `js/app/hono-remix-v3-cloudflare-example/README.md:1-89`
- 例 app `app/`
  - `js/app/hono-remix-v3-cloudflare-example/app/entry.worker.ts:1-3`
  - `js/app/hono-remix-v3-cloudflare-example/app/app.tsx:1-37`
  - `js/app/hono-remix-v3-cloudflare-example/app/routes.ts:1-27`
  - `js/app/hono-remix-v3-cloudflare-example/app/assets/entry.ts:1-10`
  - `js/app/hono-remix-v3-cloudflare-example/app/ui/document.tsx:1-22`
  - `js/app/hono-remix-v3-cloudflare-example/app/ui/content-layout.tsx:1-63`
  - `js/app/hono-remix-v3-cloudflare-example/app/ui/page-or-frame.tsx:1-32`
  - `js/app/hono-remix-v3-cloudflare-example/app/ui/frame-link.tsx:1-30`
  - `js/app/hono-remix-v3-cloudflare-example/app/ui/counter.client.tsx:1-104`
  - `js/app/hono-remix-v3-cloudflare-example/app/ui/todo.client.tsx:1-177`
- 依存 workspace パッケージ
  - `js/package/hono-remix-middleware/package.json:1-22`
  - `js/package/hono-remix-middleware/src/index.tsx:1-5`
  - `js/package/hono-remix-middleware/src/renderer.tsx:1-75`
  - `js/package/vite-plugin-remix/package.json:1-22`
  - `js/package/vite-plugin-remix/src/plugin.ts:1-65`
  - `js/package/fp/src/tsconfig/vite.json:1-26`
- workspace catalog
  - `pnpm-workspace.yaml` (catalog `effect` / `hono` / `remix` / `cloudflare` 等)

## Implications for design

### I1. ms-01 で 2 プロジェクト (`feed-platform-web` / `identity-provider`) が **そのまま踏襲すべき** 8 項目

以下は本例にすでに完成形があり、ms-01 雛形でも改造の必要がほぼない:

1. **`package.json` の構造** — `private: true` / `type: module` / `imports.#@/*` / 4 scripts (`dev`/`start`/`deploy`/`typecheck`) / catalog 完全採用 / `hono-remix-middleware` + `vite-plugin-remix` への workspace 依存。**ファイル名以外は `name` 値を差し替えるだけ**で再利用可
2. **`tsconfig.json` の構造** — 2 行 (`extends` + `jsxImportSource`)。**完全コピー可**
3. **`vite.config.ts` の plugin 順序とオプション** — `remix({ clientEntry: 'app/assets/entry.ts' })` → `cloudflare()` の順序、`run.tasks.build` の `input` パターン (`[{ auto: true }, '!.wrangler/**', '!dist/**']`)
4. **`wrangler.jsonc` の主要キー** — `compatibility_date`, `compatibility_flags: ["nodejs_compat"]`, `main: "./app/entry.worker.ts"`, `assets` ブロック (`./dist/client` + binding `ASSETS` + `not_found_handling: "none"` + `run_worker_first: false`), `observability.enabled: true`, `placement.mode: "smart"` をそのまま採用 (`name` のみプロジェクト名に差し替え)
5. **`app/entry.worker.ts` の 3 行パターン** — `import app from './app.tsx'; export default app`。Worker handler とのアダプタ不要を明示
6. **`app/app.tsx` の middleware スタック順序** — `logger()` → `contextStorage()` → `remixRenderer({ fetcher: self-fetch })` → ルート定義。**この順序を変えると Frame 機能が動かない**ため、定型として固定する
7. **`app/assets/entry.ts` の `boot({ components: import.meta.glob('/app/**/\*.client.tsx') })`\*\* — Vite の compile-time glob 制約上、consumer 側の同等記述が必須 (パッケージ側に隠蔽不可)
8. **`*.client.tsx` ファイル命名規約** — ハイドレーション対象を suffix で識別

### I2. ms-01 で **再考 / 簡素化すべき** 5 項目

1. **ホームページの中身** — 例では Counter + TODO の 2 ページ。intent-spec L71 は `feed-platform-web` で「Hello World 1 ページ + `loader` 経由の JSON 例 1 件」、L72 は `identity-provider` で「Hello, IdP ページ等」と明示。**Counter / TODO の `*.client.tsx` ハイドレーションサンプルはコピー不要**で、最小ハンドラ 1 つから始めるべき
2. **`app/routes.ts` の Frame レジストリ** — Frame 機能は SPA 風ナビゲーション最適化のためのもので、Hello World 段階では不要。**ms-01 の雛形では `routes.ts` 自体を作らず、Frame 機能が必要になった時点で本例から逆移植**するのが最小スコープに沿う。ただし intent-spec SC-9 が `app/routes.ts` の存在自体を求めていない (求めているのは `app/`, `app/entry.worker.ts`, `wrangler.jsonc`, `vite.config.ts` の 4 つ) ため、**`routes.ts` を省略しても SC-9 は満たす**
3. **`app/ui/*` の HOC レイヤー (`page-or-frame.tsx` / `frame-link.tsx` / `content-layout.tsx`)** — 上記と同じ理由で初期不要。`document.tsx` だけは SSR 出力の `<html>` 雛形として残すべき (Hello World でも `<Script>` injection が必要)
4. **`README.md` 内の "controllers / utils" 言及** (`js/app/hono-remix-v3-cloudflare-example/CLAUDE.md:30-41` vs `README.md:50` の **内部矛盾**) — ms-01 の新規雛形 README は `controllers/` `utils/` に言及しない (実装と整合させる) **typo / ガイダンス取りこぼしとして本例の CLAUDE.md にも報告**するのが望ましい (ユーザー global ガイドラインに「Typo Detection」項あり)
5. **`setup` task の有無** — 本例は未定義。intent-spec L69 が `setup` 含む `vite.config.ts` 内 task 定義に言及しているが、生成すべきものがない場合は省略可。`feed-platform-web` / `identity-provider` でも生成物 (DB schema 等) がない段階では `setup` 不要。ms-02 以降で必要になった時点で追加

### I3. ms-01 雛形で **追加が必要** な 3 項目

本例にはなく、ms-01 の SC-3 / SC-6 を満たすには新規追加が必要:

1. **smoke test 1 件** (SC-3) — 本例には `tests/` も `*.test.ts` も存在しない。ms-01 では `vp test` 通過が条件のため、各プロジェクトに最低 1 件のテストファイルが必要 (Vitest)
2. **`effect-layer` / `effect-runtime` パターンの最小 Service 例 1 件** (SC-6) — 本例の `effect` 利用は `todo.client.tsx` の `Array` / `Predicate` / `String` モジュール参照に留まり、`Layer` / `ServiceMap` / `ManagedRuntime` を使った Service 定義は **存在しない**。ms-01 で各プロジェクトに 1 件追加が必要
3. **`feed-platform-web` の loader 経由 JSON 例** (intent-spec L71) — 本例にはない。Hono の `app.get('/api/...', c => c.json(...))` 1 件追加で対応可能

### I4. `identity-provider` 固有の留意点

intent-spec L72 が「Web フロントと同じ Cloudflare Workers + Hono + Remix v3 パターン + DB 設定」と言うが、**ms-01 では Hello World 相当のみ + DB 設定は ms-02 以降の責務**。本例に DB binding は皆無 (`wrangler.jsonc` に `vars` / `bindings` なし) のため、`identity-provider` も ms-01 では同等の最小構成で十分。Better Auth / OAuth 2.1 関連の設定追加は全て ms-02 以降で対応する旨が L72 に明示されている。

### I5. ビルド成果物 (SC-4) の確認方法

`vp run -r build` 後、`feed-platform-web` / `identity-provider` 各プロジェクトに `dist/client/` (静的アセット) と `dist/<workerName>/` (Worker バンドル) が生成されることを確認すれば SC-4 達成 (本例の挙動と同等) 。`.gitignore` に `dist/` `.wrangler/` を含めることも忘れず。

### I6. 既存 ADR 候補化の余地

本例の構造は **ADR-01 (Roadmap mode)** の根拠資料となる:

- 「Cloudflare Workers + Hono + Remix v3 パターン」の具体形 = 本例
- ADR-01 から `js/app/hono-remix-v3-cloudflare-example` への参照を貼り、ms-02 以降のサイクルが「踏襲対象」を一意に特定できるようにすると、後続作業が安定する

## Remaining unknowns

1. **`vp run -r build` の実成果物ディレクトリ構造の実測** — `dist/client/` の存在は確定だが、Worker バンドル側 (`dist/<name>/` か `dist/server/` か) は `@cloudflare/vite-plugin` のデフォルトに依存し、本リサーチ範囲では実ビルドを行っていないため未確認。Step 3 の architect が `vite build` を実走させるか、`@cloudflare/vite-plugin` の README を別途確認する必要あり。**ただし SC-4 は「ビルド成果物が出力される」のみを問うので Design 段階では「`dist/` 配下に出力される」抽象度で十分**
2. **CLAUDE.md / README.md の内部矛盾** (前述 I2-4) は本サイクルで例 app 側を修正するのか別作業に切るのか、Main 判断要。ms-01 のスコープ内 (本例の README が雛形コピー元として参照される) と捉えるなら本サイクルで修正対象
3. **`identity-provider` の D1 / KV binding の設計タイミング** — ms-01 では Hello World のみのため不要だが、`wrangler.jsonc` に空の `bindings` ブロックをコメントアウトで置くか、ms-02 で追加するかは設計選択。本リサーチ範囲外 (ms-02 委譲)
4. **`vite.config.ts` の `run.tasks` に `setup` を 追加すべきか** — 例には未定義、ms-01 では生成物なし、しかし intent-spec L69 が言及。Step 3 で `setup` task の必要性を再確認する必要あり (現状判断としては「ms-01 では未定義のままで OK」が示唆されるが、project-wide 規約と齟齬がないか架構の架空者が判断)
