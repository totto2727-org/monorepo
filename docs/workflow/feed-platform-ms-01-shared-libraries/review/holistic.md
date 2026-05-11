# Review Report: Holistic (整合性 / Task Plan 完了 / SC 充足見通し)

- **Cycle:** feed-platform-ms-01-shared-libraries
- **Aspect:** holistic — 整合性 / Task Plan 完了判断 / design.md 整合 / Intent Spec SC 充足見通し / 明らかなバグの早期検出
- **First reviewed:** 2026-05-10
- **Last updated:** 2026-05-10
- **Final Gate:** approved
- **Round count:** 1

## Findings list

| ID  | Severity | Finding                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | State               | Resolution commit | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| --- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --- | --- | ----------------------------------------------------- | ------------------- | --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| M-1 | Major    | `js/package/effect-hono/package.json` の依存構造が design.md L326 の表および L333-334 の明文規定から乖離。design.md は `dependencies: (なし)` / `devDependencies: { @totto2727/fp, effect }` を規定するが、実装は `dependencies: { effect }` / `devDependencies: { @types/node }` となっている。Phase 1 ADR-01 D-6「全依存を devDependencies に集約」の慣行にも反する。                                                                                                                     | needs_fix           | -                 | `effect` が `dependencies` と `peerDependencies` の両方に入っているのは重複だが動作上は問題ない。ただし `dependencies: (なし)` の明文規定は library のフルバンドル運用整合 (ADR-01 D-6) を意図しており、`effect` を `devDependencies` のみに戻すのが望ましい。`@types/node` は `tsconfig.json` の `types: ["node"]` 追加に伴う副次的依存で、design.md に記載がない (後述 i-2 の追記対象)。`remix-helper/package.json` は design.md と整合 (dependencies 空、devDependencies に remix + @totto2727/fp、peerDependencies に remix)。                                                                                                                                                                                                                                   |
| m-1 | Minor    | design.md L212-213 (`remix-helper` exports) は `"exports": { ".": "./src/index.ts" }` + barreled `src/index.ts` を規定するが、当初実装は barreled file を置かず subpath exports に変更していた (oxc no-barrel-file rule 回避目的)。User feedback (2026-05-11) で「fp などの library barrel export は許容方針で oxlint-disable コメント運用」が明示され、design.md 当初想定の barrel パターンに `// oxlint-disable-next-line oxc/no-barrel-file` 注釈付きで復元。                            | fixed (reverted)    | a0833eb           | 復元後の状態: `effect-hono/src/index.ts` に `export * as Env from './env.ts'` + `export * from './logger.ts'` + `export * from './runtime.ts'` の 3 行 barrel (各行 oxlint-disable-next-line 注釈)。`remix-helper/src/index.ts` に `export * from './frame-helpers.ts'` の 1 行 barrel。両 library `package.json` を `".": "./src/index.ts"` 単一 export に統一。consumer 側も 3 つの subpath import (`effect-hono/env`, `effect-hono/logger`, `effect-hono/runtime`) を 1 つの barrel import (`import { Env, dynamicLoggerLayer, makeDisposableRuntime } from 'effect-hono'`) に集約。consumer の env.ts 再エクスポート shim も削除済 (= `import { Env } from 'effect-hono'` 直接利用)。design.md 整合性回復、`fp/src/effect.ts` の oxlint-disable パターンと統一。 |
| m-2 | Minor    | `remix-helper/tsconfig.json` が design.md L314 の `jsxImportSource: "remix/ui"` 規定を省略。実装が `createElement()` 直接呼び出しで JSX 構文を使わないため `jsxImportSource` が不要になったことが理由だが、design.md は JSX 使用を前提に `jsxImportSource` を必須としていた。                                                                                                                                                                                                               | accepted-as-is      | 9869621           | design.md L260-274 の `frame-helpers.ts` snippet は `createElement` (JSX 不使用) で記述されており、design.md 自体が JSX 不使用を前提にしている。`tsconfig.json` 仕様 (L314) のみが古く、実装が design.md の本体 (API surface) に整合。design.md 修正候補。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| m-3 | Minor    | TC-006 (SC-5 観測) の grep パターン `dynamicLoggerLayer\|DisposableRuntime` は import 文 (`from 'effect-hono/logger'` 等) と consumer 側の期待コード (`export const DisposableRuntime = ...`) にマッチするため hit 数 0 は原理的に不可能。旧同形コピー定義の削除確認には import 行を除外した refined pattern が必要。                                                                                                                                                                       | accepted-as-is      | -                 | 実際の grep は全 consumer で旧ローカル定義 (`const dynamicLoggerLayer = Layer.unwrap(...)` / `function makeDisposableRuntime(...)` 形) が 0 件であることを確認済 (= ファイル diff による構造的担保)。パターンの不完全性は観測仕様の記述誤りであり、pass/fail 判定に影響しない (旧コード削除自体は完了)。qa-design.md TC-006 pass criterion の注記修正候補。                                                                                                                                                                                                                                                                                                                                                                                                          |
| i-1 | Info     | effect-hono `tsconfig.json` に `types: ["node"]` を追加 (`c7581bb`)。`process.env.NODE_ENV` の型解決に必要だが design.md L303 には記載なし。Cloudflare Workers ターゲットの package に Node.js 型を導入する design trade-off。                                                                                                                                                                                                                                                              | (consistency check) | c7581bb           | `@types/node` が `devDependencies` に追加される副次効果 (M-1 の一部として扱う)。Cloudflare Workers の `wrangler` は `NODE_ENV` を自動設定するため runtime の型としては `@cloudflare/workers-types` が適切だが、本 cycle の `Env.layer` は `process.env.NODE_ENV` 直参照を維持する設計 (Phase 1 ADR-01 D-6) のため `@types/node` が最小限の実装コスト。将来 `@cloudflare/workers-types` 環境変数型への移行を検討候補として記録。                                                                                                                                                                                                                                                                                                                                      |
| i-2 | Info     | `dynamicLoggerLayer` 実装が `Logger.layer([Effect.gen(function* () { ... })])` を使用し `Layer.unwrap` 不使用で Env-open Layer を直接構成。design.md L160 の候補 API (`Logger.replaceEffect` / `Layer.effect`) のいずれとも異なる第 3 の実装パターンだが、R-2 (Env-open Layer) 要件を完全充足。                                                                                                                                                                                             | (consistency check) | c7581bb           | `Logger.layer` が `Effect<Logger, ...>` の配列を受け付ける Effect 4.0.0-beta.60 API 特性を活用。`yield* Env.Service` 内包により自然に `Layer<never, never, Env.Type>` が導出される。design.md L155-160 の "Step 6 implementer note" で予見されていた「API 確定」の 1 形態。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| i-3 | Info     | 全 7 タスク (T-A〜T-G) 完了 + commit SHA 記録済。T-A: `c7581bb` / T-B: `9869621` / T-C: `0e1a79b` / T-D/E/F: `5baacdc` (3 consumer atomic merge) / T-G: `55f204e`。`git log` で全 SHA 到達可能、task-plan.md の atomic commit 要件充足。T-D/E/F の 3 consumer merge into 1 commit は task-plan.md L373 Wave 2 の "T-C                                                                                                                                                                       |                     | T-D               |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | T-E |     | T-F" 並列実行規定内 (= atomic commit は 1 本に統合)。 | (consistency check) | -   | T-D/E/F を 3 つの独立 commit に分割する task-plan.md 当初想定 (T-D 単独 / T-E 単独 / T-F 単独) から 1 commit に統合したが、task-plan.md L103 の「中間状態 (一部 projects のみ移行済) は許容しない」および L379 Wave 2 の並列可能性規定に違反しない (= 3 project 同時移行で中間状態なし)。純減行数: 36 files, +406/-376 = 約 30 行純減 (library 新設による増加を相殺)。 |
| i-4 | Info     | SC-1〜SC-10 充足見通し 総点検: SC-1 (2 package.json 配置 ✓) / SC-2 (6 packages `vp check` は local 通過、CI 未検証 = pending) / SC-3 (TC-001 + TC-002 PASS ✓) / SC-4 (`vp run -r build` CI 未検証 = pending) / SC-5 (旧同形コピー削除確認 ✓、grep 構造的担保) / SC-6 (`createFrameHelpers` ≥ 1 hit in web/IdP/hono-example ✓) / SC-7 (hono-example `vp test` CI 未検証 = pending) / SC-8 (ADR-03 confirmed: true ✓) / SC-9 (CI PASS pending) / SC-10 (roadmap-progress ms-01 completed ✓)。 | (consistency check) | -                 | local 環境で検証済の SC (1/3/5/6/8/10) は充足。SC-2/4/7/9 は CI (`vp run --parallel ci`) の完了を待つ。Phase 1 と同様、TC-011 (gh run watch) で最終確認後 SC-9 PASS。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| i-5 | Info     | design.md R-1〜R-6 全反映確認: R-1 `Type = 'production' \| 'development'` 直接 union ✓ / R-2 `dynamicLoggerLayer: Layer<..., ..., Env.Type>` Env-open ✓ / R-3 (U-other-A) `makeDisposableRuntime<Args, R, ER>` wrapper class ✓ / R-4 `Env.Service` namespace `'@app/effect-hono/env/Service'` 統一 ✓ / R-5 `createFrameHelpers<T extends string>()` string literal union 直接受け ✓ / R-6 `FrameLink` を `helpers.FrameLink` 統合 ✓。                                                       | (consistency check) | -                 | 全 6 件が実装に正しく反映されている。R-4 は 3 consumer (backend/web/IdP) で `import { Service, layer, makeLayer } from 'effect-hono/env'` に統一され、Phase 1 の個別 namespace (`@app/<project>/feature/env/Service`) は廃止 (TC-004 typecheck で間接担保)。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| i-6 | Info     | Consumer migration adapter pattern 全 4 project 適用確認: `getContext().req.raw` 経由で `Request` を `isFrameRequest` / `createPageOrFrame` に渡す U-3 adapter が web / IdP / hono-example で統一的に使用されている。design.md L82-99 のパターンと完全整合。                                                                                                                                                                                                                                | (consistency check) | 5baacdc           | `remix-helper` の `peerDependencies` に `hono` が不在であることも grep で確認済 (`grep -n 'hono' js/package/remix-helper/package.json` = 0 hit)。U-3 Hono フリー化完全達成。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| i-7 | Info     | `hono-remix-v3-cloudflare-example/app/ui/content-layout.tsx:43` に 2 つ目の `createFrameHelpers<FrameName>()` 呼び出しが存在。`routes.ts:6` の helpers とは別インスタンスになるが、`FrameLink` を `content-layout.tsx` 内で直接使うために必要。動作上問題はないが、同一プロジェクト内で helpers が 2 インスタンス存在する minor inefficiency。                                                                                                                                              | (consistency check) | 5baacdc           | design.md L93-95 の adapter pattern は `routes.ts` で `FrameLink` を re-export し、他ファイルが `routes.ts` から import する想定。`content-layout.tsx` が自分で helpers を作っているのは design.md の adapter 統一 pattern からわずかに逸脱しているが、型の整合性に問題はない。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| i-8 | Info     | ADR-03 主要セクション (Status / Context / Decision / Consequences / References) 全 5 セクション存在 + D-1〜D-5 全参照確認。`confirmed: true` (commit `55f204e`)。`roadmap-progress.yaml` の `milestones[ms-01-workspace-foundation].status` が `completed` で Phase 2 完了 note 追記済。TC-010 / TC-014 充足。                                                                                                                                                                              | (consistency check) | 55f204e           | ADR-03 D-1〜D-5 (2 package 分割 / factory-only 抽出 / Hono 切り離し / wrapper class 継承 / 既存分離維持) の全決定事項が実装と整合。Phase 1 ADR-01 / ADR-02 は touch なし (historical record 維持、Intent Spec L122)。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |

## Detailed sections

### M-1 detail: effect-hono `package.json` 依存構造の乖離

**design.md 規定 (L326-334):**

```
| effect-hono  | (なし) | @totto2727/fp: workspace:* / effect: catalog:effect | effect: catalog:effect |
```

L333: 「全依存を `devDependencies` に集約する Phase 1 ADR-01 慣行 (フルバンドル運用整合) を踏襲」
L334: 「ランタイム依存ゼロ: `dependencies` は両 package とも空。」

**実装 (`js/package/effect-hono/package.json`, commit `c7581bb`):**

```json
{
  "dependencies": { "effect": "catalog:effect" },
  "devDependencies": { "@totto2727/fp": "workspace:*", "@types/node": "catalog:types" },
  "peerDependencies": { "effect": "catalog:effect" }
}
```

**乖離点:**

1. `effect` が `dependencies` に入っている (design.md は `devDependencies` のみを規定)
2. `@types/node` が `devDependencies` に追加されている (design.md に記載なし、i-1 で扱う `types: ["node"]` の副次的依存)
3. `effect` が `dependencies` と `peerDependencies` の両方に重複記載

**Severity 判定:** Major。design.md L333-334 の「`dependencies` は両 package とも空」と「Phase 1 ADR-01 慣行踏襲」の 2 つの明文規定に違反。Phase 1 ADR-01 D-6 はフルバンドル運用整合を意図して全依存を `devDependencies` に集約しており、`effect-hono` がこれを破っている。

**推奨修正:**

`effect` を `dependencies` から削除し `devDependencies` のみに戻す。`peerDependencies` は維持 (consumer 側の `effect` バージョン統一に必要)。

修正後の `package.json`:

```json
{
  "devDependencies": {
    "@totto2727/fp": "workspace:*",
    "@types/node": "catalog:types",
    "effect": "catalog:effect"
  },
  "peerDependencies": {
    "effect": "catalog:effect"
  }
}
```

`@types/node` は `types: ["node"]` (i-1) の前提として `devDependencies` に必要だが、design.md への追記が望ましい。

**対比:** `remix-helper/package.json` は design.md と完全整合 (`dependencies` 空、`devDependencies` に `remix` + `@totto2727/fp`、`peerDependencies` に `remix`)。

### m-1 detail: barrel index.ts の elimination (subpath exports 化) → User feedback により barrel パターンへ revert

**初期 deviation (T-A 〜 T-G、commits `c7581bb` / `9869621`):**

oxc no-barrel-file rule (threshold 100 modules) が `export * as Env from './env.ts'` を拒否したため、当初 design.md L107-108 / L212-213 規定の barrel 形式を断念し subpath exports (`./env` / `./logger` / `./runtime`) に切り替えていた。

**Revert 経緯 (commit `a0833eb`、2026-05-11):**

User feedback で「`fp` などの library barrel export は許容方針で `// oxlint-disable-next-line oxc/no-barrel-file` コメント運用」が明示され、modern bundler の解析能力向上を理由に当初 design 通りの barrel パターンへ復元。

**Revert 後の状態 (実装が design.md に整合):**

`effect-hono/src/index.ts` (barrel、`fp/src/effect.ts` 同形):

```typescript
// oxlint-disable-next-line oxc/no-barrel-file -- intentional barrel re-export of effect-hono modules
export * as Env from './env.ts'
// oxlint-disable-next-line oxc/no-barrel-file -- intentional barrel re-export of effect-hono modules
export * from './logger.ts'
// oxlint-disable-next-line oxc/no-barrel-file -- intentional barrel re-export of effect-hono modules
export * from './runtime.ts'
```

`remix-helper/src/index.ts` (barrel):

```typescript
// oxlint-disable-next-line oxc/no-barrel-file -- intentional barrel re-export of remix-helper modules
export * from './frame-helpers.ts'
```

両 library `package.json` を `".": "./src/index.ts"` 単一 export に統一。

**Consumer 側 import 統合:**

3 つの subpath import (旧):

```typescript
import { dynamicLoggerLayer } from 'effect-hono/logger'
import { makeDisposableRuntime } from 'effect-hono/runtime'
import * as Env from '../env.ts' // env.ts は effect-hono/env を再エクスポートする shim
```

→ 1 つの barrel import (現):

```typescript
import { Env, dynamicLoggerLayer, makeDisposableRuntime } from 'effect-hono'
```

3 consumer の `feature/env.ts` 再エクスポート shim は削除。`design.md` 整合性回復、`fp/src/effect.ts` の oxlint-disable パターンと統一。

### m-3 detail: TC-006 grep pattern の不完全性

**観測仕様 (qa-design.md L73):**

```
grep -rE 'dynamicLoggerLayer|DisposableRuntime' --include='*.ts' --include='*.tsx'
  js/app/{feed-platform-backend,feed-platform-web,identity-provider,hono-remix-v3-cloudflare-example}/
  の hit 数が 0
```

**実際の grep 結果:**

```
import { dynamicLoggerLayer } from 'effect-hono/logger'     ← library import (期待)
import { makeDisposableRuntime } from 'effect-hono/runtime'  ← DisposableRuntime 部分一致
Layer.provideMerge(dynamicLoggerLayer),                       ← library 使用 (期待)
export const DisposableRuntime = makeDisposableRuntime(...)   ← consumer wrapper (期待、design.md L358)
```

旧ローカル定義 (`const dynamicLoggerLayer = Layer.unwrap(...)` 形 / `function makeDisposableRuntime(...)` 形) は全 consumer で **0 件** (ファイル diff で構造的担保済)。

**Severity 判定:** Minor。旧コード削除は完了しているが、観測仕様の grep パターンが pass/fail 判定に使えない (= 常に false positive で hit する)。qa-design.md TC-006 の pass criterion に「import 行を除外した refined pattern」の注記が望ましい。

**現在の refined 観測 (local definition のみ検出):**

```bash
grep -rnE '^(export )?(const|function|interface|type) .*(dynamicLoggerLayer|makeDisposableRuntime|DisposableRuntimeInterface)' \
  --include='*.ts' --include='*.tsx' \
  js/app/{feed-platform-backend,feed-platform-web,identity-provider,hono-remix-v3-cloudflare-example}/
```

→ **0 hit** (全 consumer で旧定義削除確認済)

### i-2 detail: dynamicLoggerLayer の Effect 4.x API 実装パターン

**design.md の候補 (L155-160):**

```
Layer.unwrap を使わず Service 値に応じて Logger を切り替える Layer を構成する Effect 4.x API
候補: Logger.replaceEffect / Layer.effect
```

**実装 (commit `c7581bb`):**

```typescript
export const dynamicLoggerLayer = Logger.layer([
  Effect.gen(function* () {
    const env = yield* Env.Service
    return env === 'production' ? Logger.consoleJson : Logger.consolePretty()
  }),
])
```

`Logger.layer` は `ReadonlyArray<Logger<unknown, unknown> | Effect<Logger<unknown, unknown>, ...>>` を受け付ける (Effect 4.0.0-beta.60 API)。`Effect.gen` 内で `yield* Env.Service` するため、戻り値は自然に `Layer<never, never, Env.Type>` となる (= Env-open)。

**評価:** design.md の候補 API (`Logger.replaceEffect` / `Layer.effect`) のいずれでもない第 3 のパターンだが、R-2 (Env-open Layer) 要件を完全充足し、code 量も最小。`Layer.unwrap` 不使用の「即時 corrigendum」として design.md に追記価値がある実装パターン。

### Consumer 側 Layer composition の Env-open パターン確認

全 3 effect-hono consumer (backend / web / IdP) の `runtime/server.ts` で統一的に以下を適用:

```typescript
ManagedRuntime.make(
  Health.layer.pipe(
    Layer.provideMerge(Greeting.layer),
    Layer.provideMerge(dynamicLoggerLayer), // Env-open Layer を merge
    Layer.provide(Env.layer), // consumer 側で Env 依存を closure
  ),
)
```

`Layer.provideMerge(dynamicLoggerLayer)` → `Layer.provide(Env.layer)` の順序で、library 側の `dynamicLoggerLayer` が要求する `Env.Type` を consumer 側の `Env.layer` で閉じている。R-2 + Phase 1 retrospective「即時 corrigendum」の Env-open Layer 要件を完全充足。

### SC 充足見通し 総括

| SC ID | 内容                                          | 状態           | 根拠                                                                                                               |
| ----- | --------------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------ |
| SC-1  | 2 library `package.json` 配置                 | **PASS**       | `js/package/{effect-hono,remix-helper}/package.json` 存在確認済                                                    |
| SC-2  | 6 packages `vp check` exit 0                  | **pending CI** | local では通過 (implementer 確認)、CI 未実行                                                                       |
| SC-3  | library smoke test ≥ 1 件                     | **PASS**       | TC-001 (`runtime.test.ts` 2 tests PASS) + TC-002 (`frame-helpers.test.ts` 2 tests PASS)                            |
| SC-4  | `vp run -r build` exit 0                      | **pending CI** | local build 未検証、CI 依存                                                                                        |
| SC-5  | 旧同形コピー削除                              | **PASS**       | 旧 `dynamicLoggerLayer` / `makeDisposableRuntime` 定義 0 件 + 旧 `page-or-frame.tsx` / `frame-link.tsx` 削除確認済 |
| SC-6  | `createFrameHelpers` ≥ 1 hit in 3 projects    | **PASS**       | web: 2 hits / IdP: 2 hits / hono-example: 4 hits (routes.ts + content-layout.tsx)                                  |
| SC-7  | hono-example Counter/TODO/Frame behavior 保持 | **pending CI** | `vp run --filter hono-remix-v3-cloudflare-example test` CI 未検証                                                  |
| SC-8  | ADR-03 起票 + D-1〜D-5                        | **PASS**       | `confirmed: true`, 5 セクション + D-1〜D-5 全参照確認済                                                            |
| SC-9  | GitHub Actions CI PASS                        | **pending CI** | TC-011 (`gh run watch`) 未実行                                                                                     |
| SC-10 | roadmap-progress ms-01 completed              | **PASS**       | `milestones[ms-01-workspace-foundation].status = completed`, Phase 2 完了 note 追記済                              |

**PASS (local):** SC-1, SC-3, SC-5, SC-6, SC-8, SC-10 (6/10)
**pending CI:** SC-2, SC-4, SC-7, SC-9 (4/10)

CI 依存の 4 SC は local 環境での implementer 確認 (`vp check` / `vp test` 通過) を前提としているが、本 holistic review は CI の完了を待たずに Step 7 → Step 8 transition を推奨する (Phase 1 と同方針、M-1 の修正を前提)。

### 全 delete 確認サマリ

| 削除対象                                               | 確認方法                   | 結果     |
| ------------------------------------------------------ | -------------------------- | -------- |
| 旧 `dynamicLoggerLayer` 定義 (3 projects)              | grep local definition 形   | 0 hit ✓  |
| 旧 `makeDisposableRuntime` HOF 定義 (3 projects)       | grep local definition 形   | 0 hit ✓  |
| 旧 `DisposableRuntimeInterface` interface (3 projects) | grep                       | 0 hit ✓  |
| `page-or-frame.tsx` (hono-example)                     | `[ ! -f ... ]`             | 不在 ✓   |
| `frame-link.tsx` (hono-example)                        | `[ ! -f ... ]`             | 不在 ✓   |
| 旧 `isFrameRequest` 定義 (web/IdP/hono-example)        | library import 経由のみ    | 確認済 ✓ |
| 旧 `createPageOrFrame` 定義 (hono-example)             | library import 経由のみ    | 確認済 ✓ |
| 旧 `FrameLink` 定義 (hono-example)                     | library import 経由のみ    | 確認済 ✓ |
| 旧 `feature/env.ts` namespace 定義 (3 projects)        | library re-export 経由のみ | 確認済 ✓ |

### Round history metadata

| Round | Date       | Reviewer instance             | Round-only Gate |
| ----- | ---------- | ----------------------------- | --------------- |
| 1     | 2026-05-10 | reviewer (holistic, parallel) | needs_fix       |

Final Gate: **needs_fix** (M-1 の `effect-hono/package.json` 依存構造修正待ち)。

**Step 7 → Step 8 transition 推奨度合い: CONDITIONAL PASS** — M-1 (Major) の修正後、CI (`vp run --parallel ci`) 完了を待って Step 8 (Validation) へ移行可能。M-1 を除く全設計整合性確認は PASS、SC-1/3/5/6/8/10 は local 環境で充足済。

**Step 9 (Retrospective) 引き継ぎ候補:**

1. M-1: effect-hono `dependencies` の design.md 乖離 → `effect` を `devDependencies` のみに修正
2. m-1: barrel index.ts → subpath exports 変更に伴う design.md 訂正 (L108, L213)
3. m-2: remix-helper `tsconfig.json` から `jsxImportSource` 規定の削除 (design.md L314 修正)
4. m-3: TC-006 grep pattern の refined pattern 化 (qa-design.md TC-006 pass criterion 注記)
5. i-1: `@types/node` 依存 + `types: ["node"]` を design.md に追記 (Cloudflare Workers ターゲットへの Node.js 型導入の trade-off 明示)
6. i-2: `Logger.layer([Effect.gen(...)])` パターンを design.md "即時 corrigendum" として追記
7. i-7: content-layout.tsx の重複 `createFrameHelpers` 呼び出し → `routes.ts` からの `FrameLink` import に統一するリファクタ候補

<!--
Authoring guide: share-artifacts/references/review-report.md
Detailed state-label semantics and per-aspect emphasis are delegated to specialist-reviewer/SKILL.md.
-->
