# Research Note: existing-js-package-isolation-check

- **Identifier:** feed-platform-ms-01-shared-libraries
- **Topic:** existing-js-package-isolation-check
- **Researcher:** specialist-researcher (instance: existing-js-package-isolation-check)
- **Created at:** 2026-05-07T21:35:00Z
- **Scope:** Phase 2 で新設する 2 ライブラリ (`js/package/effect-hono` / `js/package/remix-helper`) と、既存 `js/package/` 配下 5 packages (`@totto2727/fp` / `hono-remix-middleware` / `vite-plugin-remix` / `@package/ui` / `@package/oxlint-plugin`) の責務 / export / 依存の重複 / 隔離可能性チェック。Q6 (既存 js/package との isolation 維持) の事実裏取り。

## Subject of investigation

本 Research Note は、Intent Spec (`docs/workflow/feed-platform-ms-01-shared-libraries/intent-spec.md`) Q6 の確定事項「既存 `js/package/*` との完全分離維持」が事実として成立するか、また Phase 2 で新規 2 ライブラリを追加したときに導入する追加の構造影響 (catalog / vite.config.ts task 命名 / scope 命名) があるかを、既存 5 packages の package.json と src の実コードを直接参照して検証する。スコープ:

1. 既存 5 packages の責務 / 公開 export / dependencies (Effect / Hono / Remix / React 等の生態系コミット度) の事実確認
2. C-1〜C-5 候補 identifier (`Logger.consoleJson` / `ManagedRuntime` / `Env.Service` / `isFrameRequest` / `createPageOrFrame` 等) の存在有無の grep ベース裏取り
3. 新規 2 ライブラリと既存 packages の export 重複可能性の判定
4. `pnpm-workspace.yaml` の packages glob 設定影響 (新規 packages の配置のみで catalog 設定変更が不要であることの確認)
5. 既存 `js/package/*` で Vite+ task 命名 / `vite.config.ts` パターンを定義しているのは誰か (= 新規 library で参考にできる reference 実装の特定)
6. naming policy: `effect-hono` (scope なし) と既存 `@totto2727/fp` (scope 付き) / `@package/ui` / `hono-remix-middleware` (scope なし) の混在可否

スコープ外: 新規 library の具体 file 構成 (Step 3 Design 責務) / catalog mechanism 理論 (Phase 1 で既に確認済) / consumer 側の依存追加方法 (Step 3/Step 6 責務)。

## Findings

### F1. `js/package/` 配下 5 packages の存在と責務分担 (各 1 行サマリ)

| Package                            | name                     | scope                                      | 責務                                                                                                                                                                                            | 主要 dependency 圏                                                                                                                      |
| ---------------------------------- | ------------------------ | ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `js/package/fp`                    | `@totto2727/fp`          | scope 付き (totto2727 個人 OSS / JSR 公開) | プリミティブ FP / Effect Schema CUID / option-t / temporal / change-case / micro-memoize / type-fest / **Vite+ task helper (`defineTaskInputFromOutput`)** の薄い再 export 集合                 | `effect` (peer) / `option-t` / `bignumber.js` / `@noble/hashes` / `@formatjs/intl-durationformat` / `temporal-polyfill` / `velona` (DI) |
| `js/package/hono-remix-middleware` | `hono-remix-middleware`  | scope なし flat                            | Hono の `c.render()` を Remix v3 `remix/ui/server#renderToStream` に橋渡しする middleware (`remixRenderer`) + Remix v3 `createAssetServer` を Hono middleware に wrap する (`remixAssetServer`) | `effect` (dep) / `hono` (peer) / `remix` (peer)                                                                                         |
| `js/package/vite-plugin-remix`     | `vite-plugin-remix`      | scope なし flat                            | Remix v3 client bundle を Vite environment + rollup options で構成する Vite plugin (`remix`) + client entry boot helper (`boot`) + dev/prod 切替 `<Script>` コンポーネント                      | `effect` (dep) / `remix` (peer) / `vite` (peer)                                                                                         |
| `js/package/ui`                    | `@package/ui`            | `@package` scope (workspace 限定 private)  | Shadcn/UI ベースの React UI primitives (`button` のみ現状) + tailwind-merge `cn()` utility + Tailwind CSS v4 style.css                                                                          | `react` (peer) / `react-dom` (peer) / `@base-ui/react` / `class-variance-authority` / `tailwind-merge` / `lucide-react`                 |
| `js/package/oxlint-plugin`         | `@package/oxlint-plugin` | `@package` scope (workspace 限定 private)  | Oxlint JS plugin: 11 件の rule (force-array-empty / no-let / force-ts-extension / no-eslint-disable-comments 等) + preset entry                                                                 | `effect` (dep) / `@oxlint/plugins`                                                                                                      |

### F2. `@totto2727/fp` の 14 件 export と Effect 関連の正確な含み度

`js/package/fp/package.json:18-33` の `exports` 全件:

- `./case` — `change-case` の barrel re-export (`src/case.ts:1`)
- `./di` — `velona` の barrel re-export (`src/di.ts:1`、Effect 非依存の DI library)
- `./duration` — Effect Schema + Effect Service (`DurationFormatterCache`) を使った `Effect<string, never, DurationFormatterCache>` を返す `format()` (`src/duration.ts:1-87`)。**Effect の Service / Layer / Ref / HashMap / DateTime / Duration を内部使用するが、Hono / Remix への依存はゼロ**
- `./effect/cuid` — Effect Schema branded CUID + `Generator` Service + `make` / `init` / `createFingerprint` 等 (`src/effect/cuid.ts:1-237`)。**Effect 専門、Hono / Remix 非関与**
- `./effect/option-t` — `Result` → `Exit` 変換 (`src/effect/option-t.ts:1-23`)
- `./effect/util` — `constVoidEffect` / `asVoidEffect` / `EffectFnSuccess`/`Error`/`Services` 型 / `nonEmptyArrayOrNone` / `tap` (`src/effect/util.ts:1-50`)
- `./memo` — `micro-memoize` の barrel re-export (`src/memo.ts:1`)
- `./option-t` — `option-t` 4 namespace (`Nullable` / `Maybe` / `Undefinable` / `Result`) の re-export (`src/option-t.ts:12-15`)
- `./option-t/effect` — `Exit` → `Result` 変換 (`src/option-t/effect.ts:31-39`)
- `./option-t/safe-try` — `safeTry` / `safeUnwrap` (neverthrow port) (`src/option-t/safe-try.ts`)
- `./temporal` — `temporal-polyfill` の barrel re-export (`src/temporal.ts:1`)
- `./tsconfig/vite` — `tsconfig.json` JSON file (project 全体で継承、Phase 1 で `target: esnext` 等を集約)
- `./type` — `type-fest` の barrel re-export (`src/type.ts:1`)
- `./vite` — Vite+ task `input` array 構築 helper `defineTaskInputFromOutput()` (`src/vite.ts:47-62`、`Record.map` を Effect から使うが Hono / Remix 非依存)

→ **`@totto2727/fp` は Effect / Effect Schema / DI / Vite+ helper を含むが、Hono への依存ゼロ、Remix への依存ゼロ**。`peerDependencies` は `effect` のみ (`package.json:54-56`)。

### F3. `@totto2727/fp` の Logger / Runtime / Env / Frame helper の不在

以下 grep の結果、`@totto2727/fp` 配下に C-1〜C-5 候補 identifier はいずれも存在しない:

- `Logger.consoleJson` / `Logger.consolePretty` / `Logger.console` — `js/package/` 全体で 0 hit
- `ManagedRuntime` / `asyncDispose` / `DisposableRuntime` / `makeDisposableRuntime` — `js/package/` 全体で 0 hit
- `Env.Service` / `process.env.NODE_ENV` — `js/package/` 全体で 0 hit
- `isFrameRequest` / `createPageOrFrame` / `FrameName` — `js/package/` 全体で 0 hit (※`from 'remix'` の単純 import を除く)

→ **C-1 dynamicLoggerLayer / C-2 makeDisposableRuntime / C-3 feature/env.ts / C-4 isFrameRequest / C-5 createPageOrFrame の 5 候補すべてについて、既存 `js/package/*` 内に同名 / 同責務の export は存在しない**。

### F4. `hono-remix-middleware` の 4 件 export と `remix-helper` との完全分離

`js/package/hono-remix-middleware/src/index.tsx:1-5` の全 export:

- `remixRenderer` (function) — `RemixRendererOptions { fetcher: typeof fetch; resolveClientEntry?: ... }` を受け、Hono の `MiddlewareHandler` を返す (`src/renderer.tsx:46-75`)。`c.setRenderer((content) => ...)` で `remix/ui/server#renderToStream` を呼び出す
- `RemixRendererOptions` (type)
- `ResolveClientEntry` (type)
- `ResolvedClientEntry` (type)
- `remixAssetServer` (function) — Remix v3 の `createAssetServer` の構造的 interface (`AssetServer { fetch(req): Promise<Response | null> }`) を受け Hono `MiddlewareHandler` を返す (`src/asset-server.ts:37-46`)
- `AssetServer` (type)

→ **`hono-remix-middleware` は完全に Hono runtime + Remix server 統合 middleware** (= サーバ側 middleware factory)。Frame routing / Page-or-Frame 判定 / `isFrameRequest` 相当は一切なし。新規 `remix-helper` (= Frame UI helper / `createFrameHelpers` factory) と export / 責務とも完全 disjoint。

### F5. `vite-plugin-remix` の 4 件 export と `remix-helper` との完全分離

`js/package/vite-plugin-remix/src/plugin.ts` + `src/client/index.tsx`:

- `remix(options)` (function) — Vite Plugin (`src/plugin.ts:37-65`)。`environments.client.build.rollupOptions.input` を構成
- `RemixPluginOptions` (type)
- `boot({ components })` (function) — `import.meta.glob` の Record を受け `remix/ui#run()` を起動 (`src/client/boot.ts:32-59`)。`loadModule` / `resolveFrame` 実装
- `BootOptions` (type)
- `Script({ devSrc, prodSrc })` (component) — dev/prod 切替の `<script type="module">` (`src/client/script.tsx:30-32`)
- `ScriptProps` (type)

→ **`vite-plugin-remix` は build-time Vite plugin + client-side runtime boot 関連** (= ビルド / 起動 layer)。Frame 判定 / Frame name registry / Page-or-Frame Layout helper は含まない。新規 `remix-helper` の `createFrameHelpers` (Server-side request 判定 + Layout 切替 helper) と責務 disjoint。

### F6. `@package/ui` / `@package/oxlint-plugin` は `effect-hono` / `remix-helper` と完全に無関係

- `@package/ui` (`js/package/ui/`): React UI primitives + Tailwind / cn helper (`src/lib/utils.ts:5`)。Effect / Hono / Remix への依存ゼロ。`remix-helper` は **純粋に Remix v3 の Frame helper** であり、UI primitives レイヤとは抽象階層が異なる
- `@package/oxlint-plugin` (`js/package/oxlint-plugin/`): Oxlint rule plugin (内部で `effect` を utility として使用)。Hono / Remix 非依存。Phase 2 ライブラリと無関係

### F7. `pnpm-workspace.yaml` の packages glob で新規 2 packages は自動取り込み

`pnpm-workspace.yaml:1-5`:

```yaml
packages:
  - 'js'
  - 'js/app/*'
  - 'js/package/*'
  - 'mbt/package/*'
  - 'go/app/*'
  - 'nix'
```

→ `js/package/effect-hono/` と `js/package/remix-helper/` を新規ディレクトリとして配置すれば `js/package/*` glob で自動取り込みされる。**catalog 定義 (`pnpm-workspace.yaml:13-` の `catalog:` / `catalogs:`) の変更不要** — 新規 2 packages は既存の `effect` / `hono` / `remix` / `types` / `react` catalog をそのまま consume する形で済む (Intent Spec Constraints に沿い devDependencies に集約)。

### F8. `js/package/*` で Vite+ task を定義しているのは `@totto2727/fp` のみ

`find js -name "vite.config.ts"` の結果、`js/package/` 配下では `js/package/fp/vite.config.ts` のみが存在 (他 4 packages は `vite.config.ts` を持たない)。

`js/package/fp/vite.config.ts:1-19` の task 構造:

```ts
import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      check: { command: '', dependsOn: ['check:doc', 'check:slowtype'] },
      'check:doc': { command: "deno doc --lint 'src/**/*.ts'" },
      'check:slowtype': { command: 'vpx jsr publish --dry-run --allow-dirty' },
    },
  },
})
```

→ **fp は JSR 公開 (`jsr.json` 存在) を前提とした check タスク群を持つが、新規 effect-hono / remix-helper は workspace 限定 private (`@package/ui` / `hono-remix-middleware` / `vite-plugin-remix` と同じ慣行) になる見込みのため、fp 構造をそのまま参考にはしない**。新規 library の `setup` / `build` task 定義は Intent Spec Constraints の `@totto2727/fp/vite#defineTaskInputFromOutput` を呼び出すだけで成立する (= **既存 reference 実装は js/app/\* 側に多く存在、`js/package/` 側には参考事例ほぼなし**)。

### F9. naming policy: scope 混在は既存形態として許容済み

`js/package/` 配下の 5 packages は scope 形態が既に混在している:

- scope 付き個人 OSS: `@totto2727/fp` (`package.json:2`)
- scope なし flat (publishable 性): `hono-remix-middleware` (`package.json:2`、`"private": true` だが name は flat)
- scope なし flat (publishable 性): `vite-plugin-remix` (`package.json:2`、同上)
- workspace 限定 `@package` scope: `@package/ui` (`package.json:2`)
- workspace 限定 `@package` scope: `@package/oxlint-plugin` (`package.json:2`)

→ **Phase 2 の `effect-hono` / `remix-helper` (scope なし flat) は `hono-remix-middleware` / `vite-plugin-remix` と同じ慣行**。混在は既存形態として許容済みであり、ルール変更不要。

## Sources

### Code citations

- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/fp/package.json:18-33` (exports 全件)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/fp/package.json:54-56` (peerDependencies = effect のみ)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/fp/jsr.json:9-23` (JSR 公開向け exports)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/fp/src/case.ts:1` (`change-case` re-export)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/fp/src/di.ts:1` (`velona` re-export)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/fp/src/duration.ts:1-87` (Effect Service `DurationFormatterCache`)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/fp/src/effect/cuid.ts:1-237` (Effect Service `Generator`)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/fp/src/effect/util.ts:1-50` (`constVoidEffect` / `asVoidEffect` / Effect 型ヘルパ)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/fp/src/option-t.ts:12-15` (option-t 4 namespace re-export)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/fp/src/option-t/safe-try.ts` (neverthrow port)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/fp/src/vite.ts:47-62` (`defineTaskInputFromOutput`)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/fp/vite.config.ts:1-19` (`run.tasks` 定義)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/hono-remix-middleware/package.json:6-22` (exports + dependencies)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/hono-remix-middleware/src/index.tsx:1-5` (全 5 export)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/hono-remix-middleware/src/renderer.tsx:7-11` (Hono `ContextRenderer` declare module)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/hono-remix-middleware/src/renderer.tsx:46-75` (`remixRenderer` 実装)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/hono-remix-middleware/src/asset-server.ts:9-11` (`AssetServer` 構造型)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/hono-remix-middleware/src/asset-server.ts:37-46` (`remixAssetServer` 実装)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/vite-plugin-remix/package.json:6-22` (exports + dependencies)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/vite-plugin-remix/src/plugin.ts:37-65` (Vite plugin `remix`)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/vite-plugin-remix/src/client/boot.ts:32-59` (client `boot`)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/vite-plugin-remix/src/client/script.tsx:30-32` (`Script` コンポーネント)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/ui/package.json:2-32` (scope `@package/ui` + Tailwind / Shadcn 系 deps)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/ui/src/lib/utils.ts:5` (`cn` のみ)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/js/package/oxlint-plugin/package.json:2-13` (scope `@package/oxlint-plugin` + Oxlint plugin deps)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/pnpm-workspace.yaml:1-5` (packages glob)
- `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/pnpm-workspace.yaml:13-` (catalog 定義)

### Grep evidence (existence check)

- `grep -rn "Logger\.\(consoleJson\|consolePretty\|console\)" js/package/ --include='*.ts' --include='*.tsx'` → 0 hit
- `grep -rn "ManagedRuntime\|asyncDispose\|DisposableRuntime\|makeDisposableRuntime" js/package/ --include='*.ts' --include='*.tsx'` → 0 hit
- `grep -rn "Env\.Service\|process\.env\.NODE_ENV" js/package/ --include='*.ts' --include='*.tsx'` → 0 hit
- `grep -rn "isFrameRequest\|createPageOrFrame\|FrameName\|frames" js/package/ --include='*.ts' --include='*.tsx'` → 0 hit

### Document citations

- Intent Spec Q6 確定事項: `/Users/totto2727/.warp/worktrees/monorepo/roadrunner-pinyon/docs/workflow/feed-platform-ms-01-shared-libraries/intent-spec.md:105-115`
- Intent Spec Constraints (devDependencies 集約 / `defineTaskInputFromOutput` 利用): `intent-spec.md:178-184`

## Implications for design

### I1. Step 3 Design 前提: 5 candidates すべて新規実装で確定 (既存 export を import / 再 export する選択肢は存在しない)

Findings F3 のとおり、C-1〜C-5 の identifier はいずれも `js/package/*` に存在しないため、新規 library の Step 3 Design ではすべての factory を **ゼロから設計** する。「既存 `@totto2727/fp` の関数を effect-hono が re-export して薄く wrap する」のような design option は **検討対象外** (= Q6 isolation 維持原則と整合)。

### I2. `effect-hono` の dependency 設計

- **`effect`**: `peerDependencies` (Phase 1 ADR-01 + 既存 fp の慣行に従う)
- **`hono`**: 新規 library が Hono を直接 import するか否かは Step 3 Design 責務だが、現 Phase 2 cycle の C-1〜C-3 (dynamicLoggerLayer / makeDisposableRuntime / Env) はいずれも **Hono に直接依存しない** (Effect Layer / Effect Service / Effect Logger のみ)。**`effect-hono` という名前にもかかわらず本 cycle の初期実装では Hono への直接依存はゼロで成立する可能性が高い** (将来 Hono middleware factory が増えたときに依存追加)
- **`@totto2727/fp` への依存**: `dependencies` ではなく **`devDependencies`** で型解決のみ (= `defineTaskInputFromOutput` を `vite.config.ts` で使う想定だが、ランタイム依存ではない)。Phase 1 Constraints の「全依存を devDependencies に集約」と整合
- **既存 `hono-remix-middleware` との関係**: F4 のとおり完全に責務 disjoint (sub middleware 領域 vs Logger/Runtime/Env 領域)。**`effect-hono` から `hono-remix-middleware` を import することはない**

### I3. `remix-helper` の dependency 設計

- **`effect`**: 不要可能性が高い (Frame name registry + `isFrameRequest` 関数 + `createPageOrFrame` Layout factory はすべて Effect 抽象を使わずに plain TypeScript で書ける)。Step 3 Design でユース確認後決定
- **`remix`**: `peerDependencies` (`hono-remix-middleware` / `vite-plugin-remix` と同じ慣行)
- **`hono` への依存ゼロ**: Intent Spec Q6 + Q3 の「`remix-helper` は Hono 非依存、純粋な Remix v3 Frame UI helper」と整合
- **既存 `vite-plugin-remix` / `hono-remix-middleware` との関係**: F4-F5 のとおり完全に責務 disjoint。**`remix-helper` から既存 2 packages を import する必要なし**

### I4. naming / scope policy: `effect-hono` / `remix-helper` は既存 flat 慣行と整合

F9 のとおり `hono-remix-middleware` / `vite-plugin-remix` (scope なし flat、private 設定) と同じ形態。Step 3 Design / Step 6 Implementation で `package.json.name` を `"effect-hono"` / `"remix-helper"` (両方 `"private": true`) と設定すれば既存形態と整合する。**naming policy ルールの新設不要**。

### I5. Phase 1 で確立済みの pattern を Step 6 で踏襲

- **`pnpm-workspace.yaml` の packages glob**: F7 のとおり変更不要 (`js/package/*` で自動取り込み)
- **`vite.config.ts` の `run.tasks` 構造**: 既存の `js/package/fp/vite.config.ts` は JSR 公開系 task のみ持つ特殊形 (F8) なので、新規 2 library の `setup` / `build` task は **`js/app/*` の構造 (= `defineTaskInputFromOutput` を使った setup/build chain)** を参考にする方が良い → **Step 3 Design で 1 つの app (例: `feed-platform-backend` または `hono-remix-v3-cloudflare-example`) を reference として選定推奨**
- **catalog**: 新規 catalog 追加不要、既存 `effect` / `remix` / `types` catalog をそのまま consume

### I6. Q6 isolation 原則の根拠は事実裏取り完了

User Q6 の主張「`@totto2727/fp` は primitive / framework なし、`hono-remix-middleware` は既存 hono-only middleware で、新規 `effect-hono` (Effect+Hono runtime) と `remix-helper` (純 Remix UI helper) のいずれとも責務が被らない」は、F2 / F3 / F4 / F5 の grep + コード読み込みベースで **完全に裏取り完了**:

- `@totto2727/fp` は Effect の Service / Layer / Schema を含むが Hono / Remix 依存ゼロ → `effect-hono` の Logger/Runtime/Env factory とは明確に異なる抽象層 (primitive level vs application-runtime level)
- `hono-remix-middleware` は `c.setRenderer` を Remix `renderToStream` に橋渡しする middleware で、`remix-helper` の Frame name registry + Page/Frame Layout helper とは disjoint
- `vite-plugin-remix` は build-time + client boot で、Server-side `isFrameRequest` 判定とは layer 違い

→ **Step 3 Design では Q6 を確定済み前提として進めて問題ない**。

### I7. ADR-03 (D-6) の根拠材料として本 Research Note を引用可能

Intent Spec Q7 で確定済の ADR-03 (`docs/roadmap/feed-platform/adr/2026-05-07-shared-libraries-extraction.md`) の D-6 (= 既存 js/package との分離維持) について、本 Research Note の F2-F5 + I6 を **「事実証拠」として ADR の References に直接引用可能**。Step 6 Implementation の ADR 起票時に `docs/workflow/feed-platform-ms-01-shared-libraries/research/existing-js-package-isolation-check.md` を引用すれば D-6 の根拠が完結する。

## Remaining unknowns

- **Q-Open-1**: 新規 2 library の `vite.config.ts` で具体に参考にすべき app side reference (= `feed-platform-backend` / `hono-remix-v3-cloudflare-example` のどちらが Effect + Hono + Remix 三層を含む構造として最も近いか) は本 Research Note のスコープ外。Step 3 Design (architect specialist) で 1 つの reference app を選定するか、または `@totto2727/fp/vite.config.ts` を最小起点として独立構成するか判断が必要。
- **Q-Open-2**: `effect-hono` の package.json で `hono` を peerDependency に **書くか否か** (本 cycle の C-1〜C-3 はいずれも Hono に直接依存しないため optional / 不要の可能性あり) は Step 3 Design 責務。本 Research Note では「将来 Hono middleware factory が増えたときに自然に absorb できる名前」(Intent Spec Q3) と整合する design として `peerDependencies` 登録を推奨するが、確定は Step 3 で。
- **Q-Open-3**: `@totto2727/fp` の `./vite` export (`defineTaskInputFromOutput`) は `Record.map` を Effect から import している (`src/vite.ts:25`) ため、純粋に build-time helper でも Effect への依存があることが判明。新規 library の `vite.config.ts` で `defineTaskInputFromOutput` を import するなら Effect が build-time にも要るが、`devDependencies` で十分 (Phase 1 慣行)。本問は Step 3 で Vite+ task 設計を確定する際に improbable issue として再確認のみ。
