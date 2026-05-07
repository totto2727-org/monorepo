# Research Note: Vite+ task system の現状規約 + 既存 `js/app/*` および `js/package/*` パッケージ構成事例の整理

- **Identifier:** feed-platform-ms-01-workspace-foundation
- **Topic:** vite-plus-task-system-and-existing-packages
- **Researcher:** researcher (Step 2 並列起動 1 / N、視点: Vite+ task 規約 + 既存パッケージ事例)
- **Created at:** 2026-05-04
- **Scope:** Vite+ (`vp`) のタスク定義規約 / 既存 `js/app/*` と `js/package/*` のディレクトリ・`package.json` / `tsconfig.json` / `vite.config.ts` 事例の比較整理 / ms-01 で立ち上げる 3 プロジェクト (`feed-platform-backend` / `feed-platform-web` / `identity-provider`) の雛形ベース推奨

## Subject of investigation

本 Research Note は Intent Spec の以下の制約・確定事項に応答する:

- Q2.10 / Q2.12: 「3 プロジェクト共通で `vite.config.ts` 内 Vite+ task 定義 (`check` / `fix` / `test` / `build` / `setup` 等) を既存規約に踏襲する」
- Q2.12: 「既存 monorepo の Vite+ task 規約を全プロジェクトで踏襲」
- 制約節「採用ワークスペース `js/`」「pnpm workspace + catalog」「Ultracite (Oxlint + Oxfmt)」「`vp` コマンド優先」
- SC-2 / SC-3 / SC-4: 各プロジェクトで `vp run check` / `vp run test` / `vp run -r build` が exit 0 で完走

スコープ境界:

- **対象**: Vite+ の `defineConfig` / `run.tasks` / `defineTaskInputFromOutput` の使い方、既存パッケージの構造比較、ms-01 の 3 プロジェクトに対する雛形ベース推奨
- **対象外** (他 researcher 担当または後続 step):
  - `hono-remix-v3-cloudflare-example` の Hono/Remix v3 内部実装の深堀り (別 researcher)
  - wrangler の multi-entry / 複数 worker.ts 配置パターン (別 researcher)
  - Effect の Layer / Service の細かい設計判断 (Step 3 architect)
  - DB schema (Kysely / atlas) の選定 (本サイクルでは ms-01 範囲外)

## Findings

### A. 全体規約 (root レベル)

- **monorepo パッケージ管理**: `pnpm-workspace.yaml:1-7` の `packages` に `js`, `js/app/*`, `js/package/*`, `mbt/package/*`, `go/app/*`, `nix` が登録されている
- **catalog の構成**: `pnpm-workspace.yaml:15-99` に `auth` / `build` / `cloudflare` / `database` / `dev` / `effect` / `graphql` / `hono` / `i18n` / `lint` / `pulumi` / `react` / `remix` / `storybook` / `types` / `ui` / `vite` の 17 グループが定義されている。`feed-platform` で必要な依存はおおむね揃っており、特に重要なものは:
  - `cloudflare`: `@cloudflare/vite-plugin: ^1.26.1` / `wrangler: ^4.45.0` (`pnpm-workspace.yaml:27-29`)
  - `effect`: `effect: beta` / `@effect/platform-node: beta` (`pnpm-workspace.yaml:36-38`)
  - `hono`: `hono: ^4.12.6` / `@hono/node-server` / `@hono/graphql-server` (`pnpm-workspace.yaml:44-47`)
  - `remix`: `remix: ^3.0.0-beta.0` (`pnpm-workspace.yaml:57-58`)
  - `auth`: `better-auth: ^1.5.3` / `casbin: ^5.39.0` (`pnpm-workspace.yaml:21-23`) — ms-02/03 で利用候補
  - `database`: `@libsql/kysely-libsql: ^0.4.1` / `kysely: ^0.28.11` / `kysely-codegen: ^0.19.0` (`pnpm-workspace.yaml:30-33`) — `identity-provider` の DB binding に再利用可
  - `vite-plus`: top-level catalog に `^0.1.19` (`pnpm-workspace.yaml:17`)
- **catalog 直接ピン留めしないトップレベル overrides**: `vite` / `vitest` は `overrides` で `catalog:` に強制 (`pnpm-workspace.yaml:101-103`)
- **root `package.json`**: `"type": "module"` / `wrangler: latest` / `vite-plus: catalog:` / `ultracite: catalog:lint` (`package.json:1-13`)
- **root `vite.config.ts` の役割**: ワークスペース全体の lint / fmt 設定 (`extends: [core, react, remix, oxlintPluginPreset]`, `vite.config.ts:30-44`) と、root レベルの `run.tasks` (`workspace:check` / `workspace:test` / `workspace:build` / `workspace:fix` / `ci`) を定義 (`vite.config.ts:46-74`)。`ci` は `workspace:check` + `workspace:test` + `workspace:build` を `dependsOn` で連結する (`vite.config.ts:51-54`)
- **CLAUDE.md `Standard Tasks` 節の規約** (`CLAUDE.md:17-31`):
  - `vp run <task>` がカレントパッケージ、`-r` でワークスペース全体に fan-out
  - `--cache` flag は不要 (常時ON、`CLAUDE.md:15`)
  - root の `vp run --parallel ci` は `setup` を warmup した上でタスク順序無視で `check` / `test` / `build` を実行
  - `vp run -r setup` がワークスペース全体のセットアップ (wrangler types / paraglide-js compile / tsr generate / atlas-to-kysely 等)
- **CI ワークフロー**: `.github/workflows/ci.yaml:25-30` で `vp run -r setup` → `vp run --parallel ci` の順
- **Ultracite / Oxlint / Oxfmt の設定箇所**: root `vite.config.ts` (`vite.config.ts:8-45`) のみ。各パッケージは個別に lint/fmt 設定を持たない (= ワークスペース統一)
- **追加 lint プラグイン**: `js/package/oxlint-plugin/src/preset.ts` をワークスペース固有プリセットとして root が import (`vite.config.ts:6, 31`)。preset は `force-ts-extension` / `no-let` / `force-array-empty` 等 11 規則を `error` または `warn`、test ファイルは override で緩和 (`js/package/oxlint-plugin/src/preset.ts:15-41`)

### B. Vite+ `defineConfig` / `run.tasks` の API (型定義から確認)

- **`defineConfig` 入力型**: `vite-plus` パッケージの `UserConfig` に `lint?: OxlintConfig` / `fmt?: OxfmtConfig` / `pack?: PackUserConfig | PackUserConfig[]` / `run?: RunConfig` / `staged?: StagedConfig` が拡張で追加されている (`node_modules/vite-plus/dist/define-config-hLuWEqIf.d.ts:128-139`)
- **`Task` 型** (`node_modules/vite-plus/dist/define-config-hLuWEqIf.d.ts:25-67`):
  - `command: string` (空文字列許容、グループタスクの場合)
  - `cwd?: string` (パッケージ root からの相対)
  - `dependsOn?: Array<string>` (`package-name#task-name` で他パッケージ参照可)
  - `cache?: true` / `cache: false` のユニオン
  - `input?: Array<string | GlobWithBase | AutoInput>` (省略時は自動 / `[]` で完全無効 / `'src/**'` 等の glob / `{ auto: true }` / `'!dist/**'` 否定)
  - `env?: Array<string>` / `untrackedEnv?: Array<string>` (環境変数のフィンガープリント)
- **タスク命名規約**: コロン区切りで階層化 (`setup:cloudflare` / `setup:kysely` 等) — `dependsOn` で複合タスクを束ねるのが一般的 (`js/app/saas-example/vite.config.ts:46-65`)
- **`vp run <task>`** はカレントパッケージのタスクを実行、`-r` でワークスペース全体に展開、`--filter <pkg>` で単一パッケージターゲット (`CLAUDE.md:17-40`)
- **package.json scripts と `run.tasks` 名衝突禁止**: `CLAUDE.md:71-74` および AGENTS.md 規約で「タスクと同名の package.json script は同時に存在不可。スクリプトをタスクに昇格させる際は script 側を削除する」と明記

### C. `defineTaskInputFromOutput` の使い方 (`@totto2727/fp/vite`)

- **実装場所**: `js/package/fp/src/vite.ts:24-62`
- **役割**: 「setup タスクごとに生成される output ファイル群の glob リスト」を中心化し、setup 各タスクの `input` (= 自分の output を除外) と `build` の `input` (= 全 setup の output を除外) を一括算出する
- **形式** (`js/package/fp/src/vite.ts:47-62`):
  ```ts
  const taskInput = defineTaskInputFromOutput({
    setup: {
      cloudflare: ['.wrangler/**', 'worker-configuration.d.ts'],
      kysely: ['src/feature/db/generated.ts'],
    },
  })
  // taskInput.setup.cloudflare === [{ auto: true }, '!.wrangler/**', '!worker-configuration.d.ts']
  // taskInput.build === [{ auto: true }, '!.wrangler/**', '!worker-configuration.d.ts', '!src/feature/db/generated.ts']
  ```
- **import 元**: `from '@totto2727/fp/vite'` (= JSR 公開非対象だが workspace dep 経由で import 可)。`@totto2727/fp` の package.json `exports` に `./vite: ./src/vite.ts` (`js/package/fp/package.json:32`)
- **採用箇所**: 現状 `js/app/saas-example/vite.config.ts:6, 10-17, 42-65` のみ。他パッケージは setup タスクが空のため未使用

### D. `vp run -r setup` → `vp run --parallel ci` パターン

- **CI ワークフロー** (`.github/workflows/ci.yaml:25-30`):
  ```bash
  eval "$(devbox shellenv)"
  vp run -r setup
  vp run --parallel ci
  ```
  setup を先に走らせて生成物を確実にディスクに置き、`ci` 並列実行時のキャッシュを温める意図
- **root の `ci` タスク** (`vite.config.ts:51-54`): `dependsOn: ['workspace:check', 'workspace:test', 'workspace:build']` の集約タスク (command 空)
- **`workspace:*` 系**: `command: 'vp run -r <task>'` でワークスペース全体に fan-out (`vite.config.ts:62-72`)

### E. `--cache` flag が不要となった現状仕様

- **CLAUDE.md:15**: 「The `--cache` flag is no longer required — caching is on by default」
- **`--no-cache <task>`** で個別呼び出しのキャッシュ無効化のみ可能 (`CLAUDE.md:44-48`)
- **root レベルの `cache` 設定**: `RunConfig.cache: boolean | { scripts?: boolean; tasks?: boolean }` でグローバル制御可能 (`node_modules/vite-plus/dist/define-config-hLuWEqIf.d.ts:68-88, 90-96`)。現状 root `vite.config.ts` には未設定 (= デフォルトの true)

### F. 既存 `js/app/*` 各パッケージの構造比較

#### F-1. `js/app/bw` (CLI ツール / @totto2727/bw)

| 項目         | 値 / 出典                                                                                                                                     |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| name         | `@totto2727/bw` (`js/app/bw/package.json:2`)                                                                                                  |
| type         | `module` (`js/app/bw/package.json:16`)                                                                                                        |
| 公開形態     | `bin: ./dist/bin.mjs` + `files: ['dist/']` (`js/app/bw/package.json:10-15`) — npm 公開対象                                                    |
| imports      | `#@/*: ./src/*` (`js/app/bw/package.json:17-19`)                                                                                              |
| dependencies | `effect` / `@effect/platform-node` (catalog) (`js/app/bw/package.json:23-26`)                                                                 |
| devDeps      | `@totto2727/fp: workspace:*` / `vite-plus: catalog:` (`js/app/bw/package.json:27-30`)                                                         |
| tsconfig     | `extends: ['@totto2727/fp/tsconfig/vite']` のみ (`js/app/bw/tsconfig.json:1-4`)                                                               |
| vite.config  | `pack.entry: ['src/bin.ts']` + `run.tasks.build: { command: 'vp pack', input: [{auto: true}, '!dist/**'] }` (`js/app/bw/vite.config.ts:1-15`) |
| テスト       | `src/**/*.test.ts` 形式 (vite-plus/test 利用)、`src/lib/config.test.ts:6` で `import from 'vite-plus/test'`                                   |

#### F-2. `js/app/c-plugin` (CLI ツール / @totto2727/c-plugin)

- `bw` とほぼ同一構造 (`js/app/c-plugin/package.json` と `vite.config.ts` を `bw` と diff すると、依存に `@hono/*` 系の追加なし、ほぼ完全に同形)
- 差分は `bin` 名 (`bw` → `c-plugin`)、`src/cli/` の階層、テスト数だけ
- effect の `Command.make` ベース CLI (`js/app/c-plugin/src/bin.ts:1-42`)
- 雛形ベースとしての適合: **ms-01 の 3 プロジェクトには不適合** (CLI bin 用、Cloudflare Workers ではない)

#### F-3. `js/app/hono-remix-v3-cloudflare-example` (Hono + Remix v3 + Cloudflare Workers)

| 項目           | 値 / 出典                                                                                                                                                                                                                                                                                                                                             |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| name           | `hono-remix-v3-cloudflare-example` (`js/app/hono-remix-v3-cloudflare-example/package.json:2`)                                                                                                                                                                                                                                                         |
| private        | `true` (`package.json:3`)                                                                                                                                                                                                                                                                                                                             |
| imports        | `#@/*: ./app/*` (`package.json:5-7`) — **`src` ではなく `app`** が import root                                                                                                                                                                                                                                                                        |
| scripts        | `deploy: wrangler deploy` / `dev: vp dev` / `start: wrangler dev` / `typecheck: tsgo --noEmit` (`package.json:8-13`)                                                                                                                                                                                                                                  |
| dependencies   | `effect` / `hono` / `remix: catalog:remix` / `hono-remix-middleware: workspace:*` / `vite-plugin-remix: workspace:*` (`package.json:14-20`)                                                                                                                                                                                                           |
| devDeps        | `@cloudflare/vite-plugin: catalog:cloudflare` / `@totto2727/fp: workspace:*` / `wrangler: catalog:cloudflare` (`package.json:21-25`)                                                                                                                                                                                                                  |
| tsconfig       | extends `@totto2727/fp/tsconfig/vite` + `compilerOptions.jsxImportSource: 'remix/ui'` (`tsconfig.json:1-7`)                                                                                                                                                                                                                                           |
| vite.config    | `plugins: [remix({ clientEntry: 'app/assets/entry.ts' }), cloudflare()]` + `run.tasks.build: { command: 'vp build', input: [{ auto: true }, '!.wrangler/**', '!dist/**'] }` (`vite.config.ts:1-15`)                                                                                                                                                   |
| wrangler.jsonc | `compatibility_date: 2026-02-01` / `compatibility_flags: ['nodejs_compat']` / `main: ./app/entry.worker.ts` / `assets.directory: ./dist/client` / `placement.mode: smart` (`wrangler.jsonc:1-20`)                                                                                                                                                     |
| `app/` 構成    | `entry.worker.ts` (`app.ts` を re-export) / `app.tsx` (Hono アプリ + remixRenderer middleware) / `routes.ts` (Hono context-storage frame ヘルパー) / `assets/entry.ts` (vite-plugin-remix の boot + import.meta.glob) / `ui/document.tsx` (HTML shell) / `ui/content-layout.tsx` / `ui/*.client.tsx` (`js/app/hono-remix-v3-cloudflare-example/app/`) |
| ビルド成果物   | `dist/client/` (assets binding) + Worker 本体 (`wrangler.jsonc:7-12`)                                                                                                                                                                                                                                                                                 |
| Effect 利用    | `effect` を `dependencies` に持つが、本パッケージ内の `app/` には Layer / Service / ManagedRuntime 利用箇所なし (smoke test レベル) — Effect の利用は将来の拡張前提                                                                                                                                                                                   |
| テスト         | 現状なし (`gfind ... -name '*.test.*'` 結果空)                                                                                                                                                                                                                                                                                                        |
| CLAUDE.md      | パッケージ内 CLAUDE.md (`js/app/hono-remix-v3-cloudflare-example/CLAUDE.md`) で `app/entry.worker.ts` / `app/app.ts` / `app/controllers/*.tsx` / `app/ui/*` / `app/utils/render.tsx` の責務分担と build/dev/start/deploy/typecheck コマンドを明記                                                                                                     |

#### F-4. `js/app/rss-graphql` (Hono + GraphQL + Cloudflare Workers、Remix なし)

| 項目           | 値 / 出典                                                                                                                                                                                |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| name           | `@app/rss-graphql` (`js/app/rss-graphql/package.json:2`)                                                                                                                                 |
| imports        | `#@/*: ./app/*` (`package.json:5-7`)                                                                                                                                                     |
| scripts        | `deploy: wrangler deploy` / `dev: vp dev` / `start: wrangler dev` (`package.json:8-12`)                                                                                                  |
| 依存           | `@hono/graphql-server` / `@mikaelporttila/rss` / `@pothos/core` / `@pothos/plugin-validation` / `effect` / `graphql` / `graphql-scalars` / `hono` (devDeps として、`package.json:13-24`) |
| tsconfig       | `extends: ['@totto2727/fp/tsconfig/vite']` のみ (`tsconfig.json:1-4`)                                                                                                                    |
| vite.config    | `plugins: [cloudflare()]` のみ、`run.tasks` は **未定義** (`vite.config.ts:1-6`) — root の `vp check`/`vp test`/`vp build` 標準実装に依存                                                |
| wrangler.jsonc | `main: ./app/entry.worker.ts` / `placement.mode: smart` / `vars.BUN_VERSION: 1.3.3` (`wrangler.jsonc:1-17`)                                                                              |
| `app/` 構成    | `entry.worker.ts` (re-export `./app.ts`) / `app.ts` (Hono + ManagedRuntime + graphqlServer) / `feature/graphql.ts` (Pothos schema) / `feature/hono/context.ts`                           |
| Effect 利用    | `app/app.ts:11` で `ManagedRuntime.make(FetchHttpClient.layer)`、`feature/hono/context.ts` で `Layer` 用例あり                                                                           |

#### F-5. `js/app/saas-example` (TanStack Start + Hono + Remix BFF + Cloudflare Workers + Tailwind + Storybook)

| 項目           | 値 / 出典                                                                                                                                                                                                                                                                                                                     |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| name           | `saas-example` (`js/app/saas-example/package.json:2`)                                                                                                                                                                                                                                                                         |
| imports        | `#@/*: ./src/*` (`package.json:5-7`)                                                                                                                                                                                                                                                                                          |
| scripts        | `start: wrangler dev` / `storybook:dev` / `storybook:build` (`package.json:8-12`)                                                                                                                                                                                                                                             |
| 依存           | `@cloudflare/vite-plugin` / `@inlang/paraglide-js` / `@libsql/kysely-libsql` / `@package/ui: workspace:*` / `@tailwindcss/vite` / `@tanstack/*` 一式 / `@totto2727/fp: workspace:*` / `better-auth` / `effect` / `hono` / `kysely` / `kysely-codegen` / `react` / `react-dom` / `tailwindcss` (devDeps、`package.json:14-53`) |
| tsconfig       | `extends: ['@totto2727/fp/tsconfig/vite']` + `types: ['vite-plus/client']` + `include: ['**/*', '.storybook/**/*']` (`tsconfig.json:1-8`)                                                                                                                                                                                     |
| vite.config    | 7 plugins (cloudflare / devtools / paraglideVitePlugin / tailwindcss / tanstackStart / viteReact) + `defineTaskInputFromOutput` で setup 4 タスクの input/output 中心化 (`vite.config.ts:1-68`)                                                                                                                               |
| `run.tasks`    | `build` (depends on `setup`) + `setup` (depends on `setup:cloudflare` / `setup:kysely` / `setup:paraglide` / `setup:tsr`) + 各個別 setup (`vite.config.ts:38-67`)                                                                                                                                                             |
| wrangler.jsonc | `main: ./src/entry.worker.ts` / `placement.mode: smart` (`wrangler.jsonc:1-17`)                                                                                                                                                                                                                                               |
| Effect Runtime | `src/feature/runtime/server.ts:7-58` で `ManagedRuntime.make(BetterAuth.layer.pipe(Layer.provideMerge(DB.remoteLayer), Layer.provideMerge(Env.makeLayer(env))))` + `DisposableRuntime` クラス実装 (PROD/DEV/TEST 用 3 種)                                                                                                     |
| Hono 統合      | `src/entry.hono.ts:1-22` の `makeHono(makeRuntime)` + `src/feature/runtime/hono.ts:5-11` の `makeMiddleware` で request scoped runtime                                                                                                                                                                                        |
| 認証           | `src/feature/auth/better-auth.ts:1-67` で `betterAuth({...})` + `Context.Service` + `Layer.effect` パターン                                                                                                                                                                                                                   |
| テスト         | `src/**/*.test.*` 形式は確認できず (storybook あり)                                                                                                                                                                                                                                                                           |

### G. 既存 `js/package/*` 各パッケージの構造比較

#### G-1. `js/package/fp` (`@totto2727/fp`、ライブラリ + JSR 公開)

- name: `@totto2727/fp` / version: `3.0.3` / `private: false` / license MIT (`js/package/fp/package.json:2-5`)
- 公開形態: `files: ['src/']` (= ソースのまま公開) / `exports` に 14 entry (`./case` `./di` `./effect/cuid` `./tsconfig/vite` `./vite` 等、`package.json:18-33`)
- imports: `#@/*: ./src/*` (`package.json:15-17`)
- tsconfig: `extends: ['./src/tsconfig/vite.json']` + `types: ['node']` (`tsconfig.json:1-6`) — つまり自分自身が共有 tsconfig (`src/tsconfig/vite.json`) を提供
- 共有 tsconfig 中身 (`src/tsconfig/vite.json:1-26`): `extends: '@tsconfig/strictest'` ベース + `lib: ['ESNext', 'DOM', 'DOM.Iterable', 'ESNext.Array', 'ESNext.Collection', 'ESNext.Iterator', 'ESNext.Promise']` / `types: ['vite-plus/client']` / `target: esnext` / `module: esnext` / `moduleResolution: bundler` / `jsx: react-jsx` / `allowImportingTsExtensions: true` / `noEmit: true` / `verbatimModuleSyntax: true` 他 strictest プリセット
- vite.config: `run.tasks` に `check` (depends on `check:doc` + `check:slowtype`) / `check:doc: deno doc --lint 'src/**/*.ts'` / `check:slowtype: vpx jsr publish --dry-run --allow-dirty` (`vite.config.ts:1-19`) — JSR 公開向けの追加 lint
- jsr.json (`js/package/fp/jsr.json:1-25`): JSR 公開用メタデータ (npm の package.json と二重管理だが必要部分のみ)
- 注: `vite.config.ts` 内に `defineTaskInputFromOutput` の **実装本体**を持ち、ここから他パッケージへ提供 (`src/vite.ts:24-62`)

#### G-2. `js/package/hono-remix-middleware` (Remix UI を Hono 上で動かす middleware)

- name: `hono-remix-middleware` / `private: true` (`package.json:2-4`)
- exports: `./` → `./src/index.tsx` / `./asset-server` → `./src/asset-server.ts` (`package.json:5-9`)
- 依存: `effect` (catalog) / peerDeps `hono` + `remix` (`package.json:10-21`)
- tsconfig: `extends: ['@totto2727/fp/tsconfig/vite']` + `jsxImportSource: 'remix/ui'` (`tsconfig.json:1-7`)
- vite.config: なし (= root のみで管理)

#### G-3. `js/package/oxlint-plugin` (workspace 固有 oxlint プラグイン preset)

- name: `@package/oxlint-plugin` / `private: true` (`package.json:2-3`)
- exports: `./` + `./preset` (`package.json:4-7`)
- 依存: `@oxlint/plugins` / `effect` (`package.json:9-12`)
- tsconfig: なし (= 親または root から推論)
- vite.config: なし
- 役割: root `vite.config.ts:6, 31` から import される lint 拡張専用

#### G-4. `js/package/ui` (`@package/ui`、shadcn ベースの UI コンポーネント)

- name: `@package/ui` (`package.json:2`)
- exports: `./style.css` / `./utils` (lib/utils/_.ts) / `./components/_`/`./hooks/_`/`./lib/_` (`package.json:4-11`)
- 依存: `@base-ui/react` / `clsx` / `tailwind-merge` / `lucide-react` 等 (`package.json:12-17`) + devDeps に react / tailwindcss / @totto2727/fp / @types/react (`package.json:19-26`)
- tsconfig: `extends: ['@totto2727/fp/tsconfig/vite']` + `paths: { '@package/ui/*': ['./src/*'] }` (`tsconfig.json:1-9`)
- vite.config: なし

#### G-5. `js/package/vite-plugin-remix` (Vite plugin + client boot helper)

- name: `vite-plugin-remix` / `private: true` (`package.json:2-4`)
- exports: `./` → `./src/plugin.ts` / `./client` → `./src/client/index.tsx` (`package.json:5-9`)
- 依存: `effect` / peerDeps `remix` + `vite` (`package.json:10-22`)
- tsconfig: `extends: ['@totto2727/fp/tsconfig/vite']` + `jsxImportSource: 'remix/ui'` (`tsconfig.json:1-7`)

### H. 共通慣習 (横断観察)

- **`#@/*` import alias**: 全 `js/app/*` 全 `js/package/*` (`fp` / `hono-remix-middleware` / `vite-plugin-remix` / `ui` ※`paths` 形式) で採用 (各 package.json の `imports` フィールド)
- **tsconfig は `@totto2727/fp/tsconfig/vite` extends を共有**: `js/app/bw` / `js/app/c-plugin` / `js/app/hono-remix-v3-cloudflare-example` / `js/app/rss-graphql` / `js/app/saas-example` / `js/package/hono-remix-middleware` / `js/package/ui` / `js/package/vite-plugin-remix` 全部で採用 (本リポジトリ標準)。strictest + ESNext target + bundler resolution + react-jsx + verbatimModuleSyntax の構成
- **JSX を使うパッケージは `jsxImportSource: 'remix/ui'`** を上書き: `hono-remix-v3-cloudflare-example` / `hono-remix-middleware` / `vite-plugin-remix`
- **TanStack Start ベースのパッケージは `types: ['vite-plus/client']`** を追加: `saas-example` のみ
- **catalog 依存パターン**: 既存パッケージは ほぼ全て `catalog:` 形式の依存を使用 (`hono: catalog:hono` / `effect: catalog:effect` 等)。**catalog 名と依存名のミスマッチ無し**
- **build タスクの input glob 規約**: `'!.wrangler/**'`, `'!dist/**'` は Cloudflare 構成の標準除外。`hono-remix-v3-cloudflare-example/vite.config.ts:11`、`bw/c-plugin` は `'!dist/**'` のみ
- **テストは `vite-plus/test` から import**: `import { describe, expect, test } from 'vite-plus/test'` (`js/app/bw/src/lib/config.test.ts:6`、`js/package/fp/src/effect/cuid.test.ts:2`、`js/package/oxlint-plugin/src/index.test.ts`、`js/app/c-plugin/src/**/*.test.ts`)。Vitest API と互換
- **vitest.config.\* は存在しない**: `gfind js -name 'vitest.config*'` 結果空。テスト設定は root + `vite-plus/test` の暗黙設定のみで完結 (= ms-01 の SC-3 では各プロジェクトのテストは `vp run test` 単体で動く)

### I. CLAUDE.md スキルとの整合 (effect-layer / effect-runtime / effect-hono)

- **`saas-example/src/feature/runtime/server.ts:7-58`** が `effect-runtime` パターンの参照実装: `ManagedRuntime.make(layer.pipe(Layer.provideMerge(...), Layer.provide(Logger.layer(...))))` + `Symbol.asyncDispose` 経由の `DisposableRuntime` クラスを `import.meta.env.PROD` 切替
- **`saas-example/src/feature/auth/better-auth.ts:58-67`** が `effect-layer` パターンの参照実装: `Context.Service<Instance>('@app/saas-example/feature/auth/better-auth/Service')` + `Layer.effect(Service, Effect.gen(...))`
- **`saas-example/src/feature/runtime/hono.ts:5-11`** + **`src/feature/auth/middleware.ts`** が `effect-hono` パターンの参照実装: `factory.createMiddleware` + request scoped `await using runtime`
- **`rss-graphql/app/app.ts:12-26`** はもっと簡素な `ManagedRuntime` 利用例 (Layer 1 個 + Hono context への注入のみ) — Effect 最小例として引用しやすい

## Sources

- `pnpm-workspace.yaml:1-112` (workspace + catalog 定義)
- `vite.config.ts:1-78` (root の Vite+ 設定 + run.tasks)
- `package.json:1-13` (root の deps)
- `CLAUDE.md:11-86` (Vite+ 規約 + Standard Tasks)
- `.github/workflows/ci.yaml:1-30`
- `node_modules/vite-plus/dist/define-config-hLuWEqIf.d.ts:7-152` (`Task` / `RunConfig` / `defineConfig` 型定義)
- `node_modules/vite-plus/package.json:1-391` (vite-plus exports)
- `js/app/bw/{package.json,tsconfig.json,vite.config.ts}` (CLI bin 構成)
- `js/app/c-plugin/{package.json,tsconfig.json,vite.config.ts,src/bin.ts}` (CLI bin 構成 + effect Command CLI)
- `js/app/hono-remix-v3-cloudflare-example/{package.json,tsconfig.json,vite.config.ts,wrangler.jsonc,CLAUDE.md,app/*}` (**Web フロント雛形候補本命**)
- `js/app/rss-graphql/{package.json,tsconfig.json,vite.config.ts,wrangler.jsonc,app/{entry.worker.ts,app.ts}}` (Hono + Cloudflare Workers のみの簡素構成)
- `js/app/saas-example/{package.json,tsconfig.json,vite.config.ts,wrangler.jsonc,src/{entry.worker.ts,entry.hono.ts,feature/{runtime,auth}/*}}` (Effect Layer/Runtime + Hono BFF + DB 統合の最大密度参照)
- `js/package/fp/{package.json,tsconfig.json,vite.config.ts,jsr.json,src/{vite.ts,tsconfig/vite.json}}` (`defineTaskInputFromOutput` 実装 + 共有 tsconfig 提供)
- `js/package/hono-remix-middleware/{package.json,tsconfig.json}` (peerDeps 形式の workspace package)
- `js/package/oxlint-plugin/{package.json,src/preset.ts}` (workspace 固有 lint preset)
- `js/package/ui/{package.json,tsconfig.json}` (UI コンポーネントパッケージ)
- `js/package/vite-plugin-remix/{package.json,tsconfig.json}` (Vite plugin パッケージ)
- `docs/workflow/feed-platform-ms-01-workspace-foundation/intent-spec.md` (本研究の前提制約)

## Implications for design

### 1. ms-01 雛形作成時の推奨ベース (3 プロジェクト個別)

| プロジェクト                | コピー元の本命                                                                                | 理由                                                                                                                                                                                                                                                                                                                                                                                                                              |
| --------------------------- | --------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`feed-platform-web`**     | `js/app/hono-remix-v3-cloudflare-example/` 全体                                               | Q2.10 / Q2.12 / SC-9 が「`hono-remix-v3-cloudflare-example` 最新構成踏襲」を明示。`app/entry.worker.ts` / `app/app.tsx` / `app/routes.ts` / `app/assets/entry.ts` / `wrangler.jsonc` / `vite.config.ts` の構成を 1:1 で写し、name と controller 内容のみ差し替えれば SC-9 に最短で到達                                                                                                                                            |
| **`identity-provider`**     | `js/app/hono-remix-v3-cloudflare-example/` ベース + `saas-example` の DB binding パターン参照 | Q2.10 で「Web フロントと同じ Cloudflare Workers + Hono + Remix v3 + DB 設定」と明記。SC-9 が `hono-remix-v3-cloudflare-example` 構成準拠を要求するため、まず `hono-remix-v3-cloudflare-example` を雛形として採用し、ms-02 で `saas-example` の `feature/db/kysely.ts` パターンに沿って DB layer (`@libsql/kysely-libsql`) を増設する方針が後続コスト最小                                                                          |
| **`feed-platform-backend`** | `js/app/rss-graphql/` をベースに entry を multi 化                                            | SC-5 が「`worker.ts` + `wrangler.jsonc` のペアが entry ごとに ≥ 2」を要求。`rss-graphql` は `app/entry.worker.ts` + `app/app.ts` の最も素朴な Hono + Cloudflare Workers 構成で、Remix UI 依存もなく、wrangler 直接実行に最も近い。これを「`src/<entry>/worker.ts` + `src/<entry>/wrangler.jsonc`」のペア形式に展開すれば SC-5 を満たせる。なお `rss-graphql` 配下の `app/` を `src/<entry>/` 形式に移し替えるのは Step 3 設計事項 |

### 2. 3 プロジェクト共通の規約 (uniformly apply)

設計フェーズ (Step 3) で以下を「全プロジェクト一律に必ず採用」と明記すること:

- **`package.json`**:
  - `"type": "module"` 必須
  - `"private": true`
  - `"imports": { "#@/*": "./<root-dir>/*" }` 必須 (`feed-platform-backend` は `src/`、Remix 系 2 つは `app/`)
  - 依存はすべて `catalog:` 形式 (`effect: catalog:effect` / `hono: catalog:hono` / `remix: catalog:remix` / `@cloudflare/vite-plugin: catalog:cloudflare` / `wrangler: catalog:cloudflare` / `@totto2727/fp: workspace:*`)
  - script は最小 (`deploy: wrangler deploy` / `dev: vp dev` / `start: wrangler dev` 程度)。`build` / `check` / `test` は `vite.config.ts` の `run.tasks` で定義 (script との同名衝突禁止)
- **`tsconfig.json`**: `extends: ['@totto2727/fp/tsconfig/vite']` 必須。Remix 系 2 つはさらに `compilerOptions.jsxImportSource: 'remix/ui'` 追加
- **`vite.config.ts`**:
  - `import { defineConfig } from 'vite-plus'` を採用
  - Cloudflare の `@cloudflare/vite-plugin` を `plugins` に必ず含める
  - `run.tasks.build` を最低限定義 (`command: 'vp build'` または `'vp pack'` + `input: [{ auto: true }, '!.wrangler/**', '!dist/**']`)
  - 将来 setup タスクが増えた時は `defineTaskInputFromOutput` を `@totto2727/fp/vite` から import して中心化 (現在は `setup:cloudflare` (= `wrangler types`) など 1〜2 個から開始予定)
- **`wrangler.jsonc`** (Web フロント / 認証基幹サーバ):
  - `compatibility_date: 2026-02-01` (既存 3 例と一致)
  - `compatibility_flags: ['nodejs_compat']`
  - `placement.mode: smart`
  - `observability.enabled: true`
  - Web フロント / IdP は assets binding (`assets.directory: ./dist/client`) 必要、`feed-platform-backend` の各 entry は assets binding 不要 (BFF / Worker のみ)
- **テスト**: `vite-plus/test` から `describe` / `expect` / `test` を import する `*.test.ts` 形式。設定ファイル (`vitest.config.*`) は新設しない (既存パッケージ全例で不採用)。SC-3 の「smoke test 1 件」は `test('smoke', () => { expect(1).toBe(1) })` 等で十分
- **Effect Layer / Runtime smoke 例 (SC-6)**:
  - 最小: `rss-graphql/app/app.ts:12` の `ManagedRuntime.make(<Layer>)` パターン (1 行 + Layer 定義 1 個)
  - 推奨: `Context.Service` + `Layer.effect` で 1 サービス定義 + ManagedRuntime で実行する Hello World Service (saas-example の `auth/better-auth.ts` を最小化したもの)
- **catalog の追加**: `pnpm-workspace.yaml` の既存 catalog で ms-01 段階の必要分は揃う (`auth` `cloudflare` `database` `effect` `hono` `remix` `types`)。**新規追加不要**

### 3. `feed-platform-backend` の multi-entry 構造 (SC-5 への解)

`rss-graphql` ベースから派生する具体形 (Step 3 設計事項だが本 research での観察上の推奨):

```
js/app/feed-platform-backend/
├── package.json
├── tsconfig.json
├── vite.config.ts                       (run.tasks: build のみ最小)
└── src/
    ├── bff/
    │   ├── worker.ts                    ← entry 1: BFF
    │   └── wrangler.jsonc               ← name: feed-platform-backend-bff
    └── worker-input/
        ├── worker.ts                    ← entry 2: input adapter (sample)
        └── wrangler.jsonc               ← name: feed-platform-backend-worker-input
```

- 各 `worker.ts` は Hono アプリの最小実装 (`/health` で 200 OK 返却)
- 各 `wrangler.jsonc` は独立 (= `wrangler deploy --config src/bff/wrangler.jsonc` と `wrangler deploy --config src/worker-input/wrangler.jsonc` で個別デプロイ可能)
- Vite ビルドは現状不要。`wrangler deploy` 直接実行で十分 (Q2.12 の「バックエンド = wrangler 直接実行」)。ただし `vp run -r build` で SC-4 を満たすため、`vite.config.ts` の `build` タスクは「全 worker.ts を esbuild bundle するか、または `wrangler deploy --dry-run` を CI 時に実行する」設計が必要 (Step 3 で詰める)

### 4. setup タスクの初期化方針

ms-01 段階では `setup` タスクは **Web フロント** と **`identity-provider`** で `setup:cloudflare: wrangler types` を 1 つ定義するだけで十分。`saas-example` の `setup:kysely` / `setup:paraglide` / `setup:tsr` 相当は本サイクル非スコープ (DB / i18n / TanStack Router は ms-02 以降)。

```ts
const taskInput = defineTaskInputFromOutput({
  setup: { cloudflare: ['.wrangler/**', 'worker-configuration.d.ts'] },
})
// ... run.tasks
build: { command: 'vp build', dependsOn: ['setup'], input: taskInput.build },
setup: { command: '', dependsOn: ['setup:cloudflare'] },
'setup:cloudflare': { command: 'wrangler types', input: taskInput.setup.cloudflare },
```

`feed-platform-backend` は `wrangler types` を multi-entry 各 `wrangler.jsonc` ごとに走らせる必要があり (= `setup:cloudflare:bff` / `setup:cloudflare:worker-input` 等)、これは Step 3 設計事項。

### 5. CI (SC-10) の通過は既存 `.github/workflows/ci.yaml` でそのまま動く

`.github/workflows/ci.yaml:25-30` の `vp run -r setup` → `vp run --parallel ci` は既存規約に基づくため、新 3 プロジェクトが `vite.config.ts` で `setup` / `build` / `check` / `test` を正しく定義していれば追加 CI 設定不要。SC-10 は雛形が規約に乗っていることだけで自動的に達成される。

### 6. `identity-provider` の汎用化を踏まえた package name

Q2.11 で `identity-provider` は「`feed-platform-*` 名前空間外、汎用認証基幹サーバとして他システムからの再利用を視野」とされる。`package.json.name` は `identity-provider` (privateスコープなしで OK) または `@app/identity-provider` (= `rss-graphql` と整合) のどちらにするかは Step 3 で決定。既存例:

- `bw` / `c-plugin` は `@totto2727/<name>` 形式 (npm 公開予定)
- `rss-graphql` は `@app/rss-graphql` 形式 (private)
- `hono-remix-v3-cloudflare-example` / `saas-example` は scope なしの flat 名 (private)

**推奨**: ms-01 段階では 3 プロジェクト全部 scope なしの flat 名 (`feed-platform-backend` / `feed-platform-web` / `identity-provider`) で揃え、`pnpm` workspace 解決を `--filter <name>` で直接利用できるようにする。これは `hono-remix-v3-cloudflare-example` (= 雛形本命) と一致する。

### 7. `pack.entry` vs `vp build` の使い分け

- `bw` / `c-plugin` は `pack.entry: ['src/bin.ts']` + `command: 'vp pack'` (= npm 公開向け bundle、tsdown 等で stand-alone 化)
- `hono-remix-v3-cloudflare-example` は `command: 'vp build'` (= Vite が `dist/client/` + Worker bundle を出力)
- `rss-graphql` は `run.tasks` 自体を持たない (= root の `vp build` 既定動作に依存)
- ms-01 の **Web フロント** と **identity-provider** は `vp build` パターン (Cloudflare + Remix + Vite) を採用、**`feed-platform-backend`** は `wrangler deploy` 直接運用前提だが SC-4 のため何らかの `build` タスク (Vite なし or 軽量 bundling) を持つ必要がある — これは Step 3 で詰める

## Remaining unknowns

1. **`feed-platform-backend` の `vp run -r build` 完走方針**: SC-4 が「ワークスペース全体の build が exit 0」を要求する。wrangler 直接実行構成下で `build` タスクは何を実行するか (`wrangler deploy --dry-run` 並走 / esbuild bundle のみ / `command: ''` の no-op タスク許容) は Step 3 architect が決定する必要がある。`rss-graphql` のように `run.tasks.build` を未定義にすると root の `vp build` が走り、Vite + Cloudflare plugin で 1 つの Worker としてビルドされるが、multi-entry にすると entry 選択方法が課題
2. **`tsconfig.json` の `include` 範囲**: `saas-example/tsconfig.json:7` のみ `include: ['**/*', '.storybook/**/*']` を持つ。他 4 例 (`bw` / `c-plugin` / `hono-remix-v3-cloudflare-example` / `rss-graphql`) は `include` 未指定。3 プロジェクトで `include` を指定する必要があるかは Step 3 の検証事項 (デフォルト挙動で十分か未確認)
3. **Effect Service の命名規約**: `saas-example` は `Context.Service<Instance>('@app/saas-example/feature/auth/better-auth/Service')` の形式。新 3 プロジェクトでは `@<scope>/<name>/feature/<feature>/Service` 形式を踏襲するべきか、scope を `@feed-platform/*` で揃えるかは Step 3 で決定
4. **`identity-provider` の DB binding 雛形**: ms-01 では「DB 設定の追加」と Intent Spec に明記 (Q2.10) されつつも実装は ms-02 委譲。`wrangler.jsonc` に `d1_databases` 等の binding 定義を ms-01 で書く / 書かないは Step 3 で詰める (現状の `saas-example/wrangler.jsonc:1-17` は DB binding を含まない、libsql/Turso 想定で外部 URL を env で注入)
5. **catalog 追加 vs 既存 catalog 利用**: `feed-platform` 関連で必要そうな依存はおおむね既存 catalog で揃うが、ms-01 で新規 catalog グループ (例: `feed-platform` 専用) を切るかは将来の拡張性次第 — 現時点では既存 catalog のまま運用で問題なさそう (Step 3 で確認)
6. **`vite-plus/test` のテストランナー設定**: 既存例にテスト config が無い背景は本 research 範囲では未確認。`vite-plus/test` の internal default + root `vite.config.ts` の lint/fmt のみで Vitest 互換が動く前提が成立しているが、特定の coverage / globals / environment 設定が必要になった場合の足し方は別途確認が必要 (将来の研究課題)
