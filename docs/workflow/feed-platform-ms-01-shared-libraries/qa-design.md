# QA Design: feed-platform Shared Libraries (ms-01 Phase 2)

- **Identifier:** feed-platform-ms-01-shared-libraries
- **Author:** qa-analyst (single instance)
- **Source:** `docs/workflow/feed-platform-ms-01-shared-libraries/intent-spec.md`, `docs/workflow/feed-platform-ms-01-shared-libraries/design.md`
- **Created at:** 2026-05-10T09:00:00Z
- **Last updated:** 2026-05-10T09:00:00Z
- **Status:** draft

本ドキュメントは Step 4 で確定する **essential test design**。Step 6 (Implementation) で implementer が「実装中に発見されたテスト」(TC-IMPL-NNN) を追記する余地を残す。詳細な記法ルールは `share-artifacts/references/qa-design.md` 参照。

## Overview

ms-01 Phase 2 は **factory のみ抽出 + 4 consumer 一括 migration** の refactor only サイクルであり、Intent Spec の SC-1〜SC-10 (intent-spec.md L146-168) は次の 5 カテゴリに分類される:

1. **Library structural verification** — `js/package/{effect-hono,remix-helper}/` の `package.json` / `tsconfig.json` / `src/` 配置 (SC-1)
2. **Lifecycle command verification** — 6 packages (2 library + 4 consumer) で `vp run --filter <pkg> check` / `vp run -r build` の exit code 0 (SC-2, SC-4)
3. **Library smoke test** — `effect-hono` の `makeDisposableRuntime` factory + `remix-helper` の `createFrameHelpers` factory の最小動作検証 (SC-3、`vp run --filter <pkg> test` exit 0)
4. **Consumer migration verification** — 4 consumer projects で旧 `dynamicLoggerLayer` / `DisposableRuntime` / 旧 `frame-link.tsx` / 旧 `page-or-frame.tsx` 不在 + library import 切替 (SC-5, SC-6, SC-7)
5. **ADR / CI / roadmap progression** — ADR-03 起票 + GitHub Actions CI PASS + `roadmap-progress.yaml` の `completed` 化可能性 (SC-8, SC-9, SC-10)

design.md "Test boundary" (L411-421) で確定済の test 方針:

- **library smoke test は 2 件必須** (SC-3 達成の最小ライン): `effect-hono/src/runtime.test.ts` (makeDisposableRuntime wrapper class)、`remix-helper/src/frame-helpers.test.ts` (createFrameHelpers + helpers.FrameLink)
- **library smoke test は 2 件任意** (品質向上、QA-analyst 判断): `effect-hono/src/env.test.ts`、`effect-hono/src/logger.test.ts`
- **SC-7 (hono-remix-v3-cloudflare-example) の既存 behavior 保持**: 既存 test 群があれば PASS 維持、なければ smoke (`vp run --filter hono-remix-v3-cloudflare-example test` exit 0) で OK。本 cycle は refactor only + `createPageOrFrame` semantic 完全継承のため、構造的に behavior 保持が担保される (design.md L444 / Research B F-2 / I-3)

design.md "Public API surface" の R-1〜R-6 反映 (R-5 で `createFrameHelpers<T extends string>()` の string literal union 直接受けに最終確定、`InferFrameName<T>` 型関数は廃止) を踏まえ、TC は以下の制約を満たす:

- `createFrameHelpers<'a' | 'b'>()` を直接 generics で specialize する形 (Record / tuple 経由なし)
- `expectTypeOf(helpers.isFrameRequest).parameter(1).toEqualTypeOf<'a' | 'b'>()` 等の type-level assertion を runtime test 内に併記 (Vitest `expectTypeOf` 利用)
- `helpers.FrameLink` の `rmx-target` prop が `T` で specialize されることも type-level 検証
- `// @ts-expect-error` で union 外の string 受入拒否を assert

## Rationale for automated vs. manual

ms-01 Phase 2 の検証対象は **library factory の input/output 型整合性 + コマンド成功 + 構造存在 + grep ベースの migration 完了確認** に集約され、人間の主観的判断 (UX / 視覚的一貫性) を要する観測点は存在しない。よって既定方針は Phase 1 同様 **`automated × assertion` 一択**。例外を以下にまとめる。

**`automated × scenario` (Effect Service test + AsyncDisposable scope test)**: TC-001 (`makeDisposableRuntime` smoke) は **factory による class 生成 → `await using` scope 構築 → `Symbol.asyncDispose` 自動呼び出し** の連続ステップを検証するため `scenario`。TC-002 (`createFrameHelpers` smoke) は **factory specialize → `Request` 構築 → `isFrameRequest` 評価 → type-level 引数制約検証** の連続ステップを伴うため `scenario`。

**`automated × observation` (grep カウント / ls カウント / dist 出力件数)**: TC-005 (`dist/client/` ファイル数 ≥ 1)、TC-006 (旧 `dynamicLoggerLayer` / `DisposableRuntime` 0 hit)、TC-008 (`createFrameHelpers` ≥ 1 hit) は **数値閾値 / パターンマッチ件数の閾値判定**を行うため `observation`。

**`automated × inspection` は禁止組合せ**のため不採用。ADR-03 の本文質的妥当性は本サイクルの検証範囲外 (Phase 1 と同方針)。主要セクション存在 + D-1〜D-5 参照は grep の `automated × assertion` で扱える。

**`manual` / `ai-driven` は採用しない**: refactor only サイクル + 個人開発という性格上、人間判断を要する観測点を残すと CI / Step 8 validator の自動検証経路が不完全になる。SC-7 の Counter / TODO / Frame ナビゲーション既存 behavior 保持は `vp run --filter hono-remix-v3-cloudflare-example test` exit 0 (= test 群が PASS、test 不在なら 0 件 PASS で exit 0) で観測する (intent-spec.md L162 / design.md L419)。

## Test file placement policy

ms-01 Phase 2 では以下の **配置方針のみ** を確定する。具体ファイルパスは Step 5 (Task Decomposition) / Step 6 (Implementer) の責務。

- **`automated × scenario` (library smoke test)**: 各 library の `src/` 配下に **検証対象 module ごとに `<name>.test.ts` を colocation 配置** (Phase 1 CC-5 継承、`vite-plus/test` 経由、Vitest 設定ファイルは新設しない)
  - `js/package/effect-hono/src/runtime.test.ts` (P0、TC-001)
  - `js/package/remix-helper/src/frame-helpers.test.ts` (P0、TC-002)
  - `js/package/effect-hono/src/env.test.ts` (P2、TC-012、任意)
  - `js/package/effect-hono/src/logger.test.ts` (P2、TC-013、任意)
- **`automated × assertion` / `automated × observation` (構造検証 / コマンド成功検証 / migration 完了検証)**: Step 8 の validator が **コマンド実行ベース**で再現する。コードとしてのテストファイルは作成しない (= validator の `validation-evidence/` に実行ログとして残す、Phase 1 同方針)
  - 配置先 (= 観測ログ): `docs/workflow/feed-platform-ms-01-shared-libraries/validation-evidence/<TC-ID>.log` (Step 8 で生成、Step 4 では空)
- **CI 検証 (SC-9)**: GitHub Actions の `vp run --parallel ci` ジョブ結果を `share-ci-monitoring` 二重チェックで観測。テストコード自体は新設不要 (Phase 1 CC-9 継承)

## Essential test cases (TC-NNN)

design.md の Mapping to Success Criteria 表 (L436-447) と Test boundary 節 (L411-421) を観測単位に落とした test case 群。優先度は **P0 (必須、SC-3 達成の最小ライン)** / **P1 (推奨、SC-1〜SC-9 構造 / lifecycle / migration / ADR / CI)** / **P2 (任意、品質向上)** の 3 段階。

### TC 一覧

| ID     | Target SC   | Priority | Expected behavior                                                                                                                                                                                                                                                                                    | Actor     | Style       | Pass criterion                                                                                                                                                                                                                                                                                                                                                          | Notes                                                                                                                                                                                                                             |
| ------ | ----------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| TC-001 | SC-3        | P0       | `effect-hono/src/runtime.test.ts` で `makeDisposableRuntime(make)` が返す class を `await using rt = new Klass()` で構築し、scope 離脱で `Symbol.asyncDispose` が自動呼び出しされる。`rt.instance` が `ManagedRuntime` interface (`runPromise` / `runFork`) を持つことを runtime + type-level で検証 | automated | scenario    | `vp run --filter effect-hono test` exit 0、Vitest 出力に `runtime.test.ts` の `1 passed` 以上 / `0 failed`。runtime 内部で `Layer.empty` + `ManagedRuntime.make(empty)` 経由生成、`expectTypeOf(rt.instance).toMatchTypeOf<ManagedRuntime.ManagedRuntime<never, never>>()` が型レベルで通過、`typeof rt[Symbol.asyncDispose]` が `'function'` に等しい                  | design.md L415 / L183-194 (wrapper class シグネチャ)。`make` 関数を `() => ManagedRuntime.make(Layer.empty)` で minimal 化、副作用ゼロの factory 検証。U-other-A (wrapper class 必須) の構造的担保                                |
| TC-002 | SC-3        | P0       | `remix-helper/src/frame-helpers.test.ts` で `createFrameHelpers<'a' \| 'b'>()` が返す helpers の `isFrameRequest` が `request.headers.get('x-remix-target')` 比較を行い、`FrameLink` の `rmx-target` prop 型が `'a' \| 'b'` に拘束される (型レベル)                                                  | automated | scenario    | `vp run --filter remix-helper test` exit 0。runtime: `new Request('http://x', { headers: { 'x-remix-target': 'a' } })` を渡して `helpers.isFrameRequest(req, 'a')` が `true`、`helpers.isFrameRequest(req, 'b')` が `false`。type-level: `expectTypeOf(helpers.isFrameRequest).parameter(1).toEqualTypeOf<'a' \| 'b'>()`、`// @ts-expect-error` で `'unknown'` 受入拒否 | design.md L418 / L221-275 (createFrameHelpers シグネチャ + FrameLink 統合)。R-5 / R-6 反映 (string literal union 直接受け、`InferFrameName<T>` 廃止)。Hono フリー化 (U-3) 担保のため `getContext()` 等の context primitive 不使用 |
| TC-003 | SC-1        | P1       | `js/package/effect-hono/{package.json,tsconfig.json,src/index.ts}` と `js/package/remix-helper/{package.json,tsconfig.json,src/index.ts}` が配置され、各 `package.json` の `name` が `effect-hono` / `remix-helper` (scope なし flat name)                                                           | automated | assertion   | 6 ファイルすべてが `[ -f ... ]` で検出。`node -p "require('./js/package/effect-hono/package.json').name"` が `effect-hono`、同 remix-helper も一致。`require(...).private === true`                                                                                                                                                                                     | design.md L301-320 / L326-329 (依存関係表)。flat name 慣行は既存 `hono-remix-middleware` / `vite-plugin-remix` と整合 (Intent Spec L58-L61)                                                                                       |
| TC-004 | SC-2        | P1       | 6 packages (`effect-hono` / `remix-helper` / `feed-platform-backend` / `feed-platform-web` / `identity-provider` / `hono-remix-v3-cloudflare-example`) すべてで `vp run --filter <pkg> check` が exit 0 で終了                                                                                       | automated | assertion   | 6 件すべての `vp run --filter <pkg> check; echo $?` が `0`                                                                                                                                                                                                                                                                                                              | intent-spec.md L151-152 / design.md SC-2 行。catalog 解決失敗 / `@tsconfig/strictest` 違反 / Ultracite 違反は exit ≠ 0 で発覚                                                                                                     |
| TC-005 | SC-4        | P1       | `vp run -r build` がワークスペース全体で exit 0、3 web projects (`feed-platform-web` / `identity-provider` / `hono-remix-v3-cloudflare-example`) の `dist/client/` がビルド成果物を含む                                                                                                              | automated | observation | `vp run -r build; echo $?` が `0`、`find js/app/feed-platform-web/dist/client -type f \| wc -l` ≥ 1、同 `identity-provider` / `hono-remix-v3-cloudflare-example` も ≥ 1                                                                                                                                                                                                 | intent-spec.md L155-156 / design.md SC-4 行。2 library (`effect-hono` / `remix-helper`) は `vite.config.ts` 不要 (build task 未定義 = Vite+ auto-skip、Phase 1 ADR-01 D-6 慣行継承)                                               |
| TC-006 | SC-5        | P1       | 4 consumer projects で旧 `dynamicLoggerLayer` / `DisposableRuntime` / 旧 HOF `makeDisposableRuntime` 定義が削除済 (= library import 経由のみ)                                                                                                                                                        | automated | observation | `grep -rE 'dynamicLoggerLayer\|DisposableRuntime' --include='*.ts' --include='*.tsx' js/app/{feed-platform-backend,feed-platform-web,identity-provider,hono-remix-v3-cloudflare-example}/` の hit 数が **0** (= consumer 側に旧コード残存なし)                                                                                                                          | intent-spec.md L157-158 / design.md L350 (SC-5 観測仕様字面通り)。consumer の `Variables.runtime: Runtime.Runtime` 型源を `ReturnType<typeof makeRuntime>` に変更後、library import 切替の機械的 migration 完了                   |
| TC-007 | SC-5 / SC-6 | P1       | `hono-remix-v3-cloudflare-example` の旧 `app/ui/page-or-frame.tsx` (PageOrFrame) と `app/ui/frame-link.tsx` (FrameLink) が **両方削除** され、library helpers 経由に置換済                                                                                                                           | automated | assertion   | `[ ! -f js/app/hono-remix-v3-cloudflare-example/app/ui/page-or-frame.tsx ]` かつ `[ ! -f js/app/hono-remix-v3-cloudflare-example/app/ui/frame-link.tsx ]` がいずれも成立 (両ファイル不在)                                                                                                                                                                               | design.md L348 / L352 (削除確認字面通り)。R-6 で C-6 FrameLink を本 cycle 正式抽出対象に追加した結果、両ファイル削除 + library 経由 import 切替で migration 完了                                                                  |
| TC-008 | SC-6        | P1       | 3 projects (`feed-platform-web` / `identity-provider` / `hono-remix-v3-cloudflare-example`) で `createFrameHelpers` factory が利用されている                                                                                                                                                         | automated | observation | `grep -rn 'createFrameHelpers' --include='*.ts' --include='*.tsx' js/app/feed-platform-web/` / 同 `identity-provider` / 同 `hono-remix-v3-cloudflare-example` がそれぞれ ≥ 1 hit                                                                                                                                                                                        | intent-spec.md L159-160 / design.md SC-6 行。option A (refactor only、`type FrameName = never` で web/IdP / `type FrameName = 'content'` で hono-remix-example) で達成                                                            |
| TC-009 | SC-7        | P1       | `hono-remix-v3-cloudflare-example` の Counter / TODO / Frame ナビゲーション既存 behavior が refactor 後も保持される (test 群があれば PASS、なければ smoke level で `vp test` exit 0)                                                                                                                 | automated | assertion   | `vp run --filter hono-remix-v3-cloudflare-example test; echo $?` が `0` (test 不在の場合は 0 件 PASS で exit 0、既存 test がある場合は全 PASS)                                                                                                                                                                                                                          | intent-spec.md L161-162 / design.md L419 / L444 (SC-7 行)。`createPageOrFrame` semantic 完全継承 + `FrameLink` API 互換維持で構造的に behavior 保持 (Research B F-2 / I-3)                                                        |
| TC-010 | SC-8        | P1       | ADR-03 (`docs/roadmap/feed-platform/adr/2026-05-08-shared-libraries-extraction.md`) が存在し、主要セクション (Status / Context / Decision / Consequences / References) を含み、Decision に D-1〜D-5 の 5 確定事項参照を含む                                                                          | automated | assertion   | `[ -f docs/roadmap/feed-platform/adr/2026-05-08-shared-libraries-extraction.md ]` 成立、`grep -E '^## (Status\|Context\|Decision\|Consequences\|References)'` 検出件数 = 5、`D-1` 〜 `D-5` の 5 トークンすべてが ADR 内で grep ≥ 1 hit                                                                                                                                  | intent-spec.md L163-164 / design.md L401-409 (ADR-03 outline)。Roadmap mode (`docs/roadmap/feed-platform/adr/`) 起票、`share-adr` 規約準拠                                                                                        |
| TC-011 | SC-9        | P1       | ms-01 Phase 2 最終コミットで GitHub Actions CI (`vp run --parallel ci`) が PASS                                                                                                                                                                                                                      | automated | assertion   | `gh run list --branch <branch> --workflow ci.yaml --json conclusion,headSha --limit 1` の `conclusion` が `"success"`、`gh run watch --exit-status <run-id>` 終了コード `0` (share-ci-monitoring 二重チェック、最大 2 回リトライ後も失敗時は Blocker)                                                                                                                   | intent-spec.md L165-166 / design.md SC-9 行 / `share-ci-monitoring` 規約。Phase 1 既存 CI ワークフロー流用 (CC-9)                                                                                                                 |
| TC-012 | SC-3        | P2       | `effect-hono/src/env.test.ts` で `Env.makeLayer('production')` 経由 `Env.Service` が `'production'` 文字列直接を返すこと (R-1 反映: struct `{ ENV: ... }` 廃止、string literal union 直接)                                                                                                           | automated | scenario    | `vp run --filter effect-hono test` exit 0、Vitest 出力に `env.test.ts` の `1 passed` 以上 / `0 failed`。`Effect.runPromise` で `yield* Env.Service` が `'production'` 文字列に等しい                                                                                                                                                                                    | design.md L416 / R-1 (`Env.Type` 直接 string literal union)。任意だが Phase 1 既存 test 同形で検証コスト最小、SC-3 達成は P0 のみで成立するため省略可                                                                             |
| TC-013 | SC-3        | P2       | `effect-hono/src/logger.test.ts` で `dynamicLoggerLayer` を `Layer.provide(Env.makeLayer('production'))` で合成し、依存閉じた Layer が Effect 実行時 error なく解決                                                                                                                                  | automated | scenario    | `vp run --filter effect-hono test` exit 0、Vitest 出力に `logger.test.ts` の `1 passed` 以上 / `0 failed`。具体的 Logger output (consoleJson vs consolePretty) の stdout 内容比較は **行わない** (smoke level、Logger 内部状態検証は重いため省略、design.md L417 字面通り)                                                                                              | design.md L417 / R-2 (Env-open Layer)。Step 6 implementer が Effect 4.x API (`Logger.replaceEffect` / `Layer.effect`) 確定後に書く前提、書式は implementer 判断 OK                                                                |
| TC-014 | SC-10       | P2       | SC-1〜SC-9 全 PASS の前提下で、`docs/roadmap/feed-platform/roadmap-progress.yaml` の `milestones[ms-01-workspace-foundation]` を Phase 1 + Phase 2 完了状態として `completed` に再遷移可能                                                                                                           | automated | assertion   | `yq '.milestones[] \| select(.id == "ms-01-workspace-foundation")' docs/roadmap/feed-platform/roadmap-progress.yaml` で `blockers` が空 or 未定義、TC-001〜TC-011 がすべて PASS、本 cycle Phase 2 retrospective で `phase 2 completed` 記録                                                                                                                             | intent-spec.md L167-168 / design.md SC-10 行。Phase 1 + Phase 2 全 SC 充足の論理的帰結 (= 独立観測点を持たないため、前段 TC 全 PASS で自動成立)                                                                                   |

### TC で網羅していない design 確定事項 (意図的)

以下の design 確定事項は **観測対象として独立 TC を立てない** 判断:

- **`package.json` 依存関係の型** (`@totto2727/fp: workspace:*` / `effect: catalog:effect` / `remix: catalog:remix`、`peerDependencies`): TC-004 (`vp run --filter <pkg> check` 通過) に内包 (catalog 解決失敗 / peer 不整合は `vp install` / typecheck で発覚)
- **`tsconfig.json` extends 規約** (`@totto2727/fp/tsconfig/vite`): TC-004 に内包 (strictest 適用が外れると typecheck エラー範囲が変動)
- **R-1 (Env.Type 直接 union)** / **R-2 (dynamicLoggerLayer Env-open)** の構造的内含: TC-004 (typecheck) + TC-001 / TC-012 / TC-013 (実機実行) で間接担保。専用 grep TC は冗長
- **adapter pattern 適用** (consumer 側 `getContext().req.raw` 1 行 helper、design.md L82-99): TC-004 (typecheck) + TC-009 (hono-example smoke) で間接担保。adapter は機械的 boilerplate (4 project 各 1 箇所のみ) のため独立 TC 不要
- **C-1 dynamicLoggerLayer の condition / Logger 関数ハードコード**: 内部実装詳細、TC-013 smoke で間接担保。Logger output 形式比較は QA-analyst 判断で smoke level 省略 (design.md L417)
- **library 内部の specific Layer kind 配分** (`Layer.sync` / `Layer.succeed`): TC-001 / TC-012 / TC-013 で構造的に担保。Layer kind 区別の TC 分離は後続マイルストーンの軽微な変更で偽陽性となるため不採用 (Phase 1 同方針)
- **C-3 `Env.Service` namespace** (`'@app/effect-hono/env/Service'` 統一): TC-004 (typecheck) で間接担保。consumer 側 `Variables.runtime` 型源は `ReturnType<typeof makeRuntime>` で typecheck 通過すれば semantic 整合 (Phase 1 既存 pattern 継承、design.md L345-347)

### Enum value quick reference

- **Actor (`Actor` 列):** `automated` のみ採用 (`ai-driven` / `manual` は本サイクル不採用、refactor only + 個人開発)
- **Style (`Style` 列):** `assertion` (中心) / `scenario` (TC-001 / TC-002 / TC-012 / TC-013 の 4 件 = library smoke test) / `observation` (TC-005 / TC-006 / TC-008 の 3 件 = 件数閾値 / grep カウント)
- **Priority (`Priority` 列):** `P0` (TC-001 / TC-002、SC-3 達成必須) / `P1` (TC-003 〜 TC-011、SC-1〜SC-9 達成推奨) / `P2` (TC-012 〜 TC-014、品質向上 / SC-10 自動成立)
- **禁止組合せ:** `automated × inspection` (採用なし、Phase 1 同方針)
- **△ 組合せ:** 採用なし

## Implementation-driven test cases (TC-IMPL-NNN)

ライブラリ / フレームワーク / OS の振る舞いに固有の防御分岐は **Step 6 (implementer) が発見次第追記**する。Step 4 段階では空。

| ID                                         | Target SC | Priority | Expected behavior | Actor | Style | Pass criterion | Why required (mandatory) | Notes                                                                                                                                                                                                                                                        |
| ------------------------------------------ | --------- | -------- | ----------------- | ----- | ----- | -------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| (未使用 — Step 4 段階では本セクションは空) | -         | -        | -                 | -     | -     | -              | -                        | implementer が `effect@4.0.0-beta.60` の `Logger.replaceEffect` / `Layer.effect` 等の固有挙動、Vitest `expectTypeOf` の `T extends string` 推論、`vite-plus/test` の library package 振る舞いに起因する追加 TC を発見した場合のみ TC-IMPL-001 から連番で追記 |

## Coverage table

intent-spec.md の SC-1〜SC-10 が essential test cases (TC-001〜TC-014) で **すべてカバー** されていることを逆引きで確認する。

| SC ID | Corresponding TC-IDs | Notes                                                                                                                                             |
| ----- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| SC-1  | TC-003               | 2 library の `package.json` / `tsconfig.json` / `src/index.ts` 配置 + `name` flat name 規約の単一 assertion で完結                                |
| SC-2  | TC-004               | 6 packages の `vp run --filter <pkg> check` 通過は単一観測点で完結 (catalog 解決 / strictest / Ultracite を内包)                                  |
| SC-3  | TC-001, TC-002       | library smoke test 2 件必須 (P0)。+ TC-012 / TC-013 (P2 任意) で env / logger を補完                                                              |
| SC-4  | TC-005               | `vp run -r build` 通過 + 3 web projects `dist/client/` 出力の単一 observation で完結 (2 library は build task 未定義 auto-skip)                   |
| SC-5  | TC-006, TC-007       | 4 consumer の旧 `dynamicLoggerLayer` / `DisposableRuntime` 0 hit + hono-remix-example の旧 `page-or-frame.tsx` / `frame-link.tsx` 不在の 2 段検証 |
| SC-6  | TC-007, TC-008       | 旧 frame helper 削除 + 3 projects `createFrameHelpers` ≥ 1 hit の 2 段検証                                                                        |
| SC-7  | TC-009               | hono-remix-v3-cloudflare-example の `vp test` exit 0 単一観測 (refactor only + factory semantic 完全継承で behavior 構造的担保)                   |
| SC-8  | TC-010               | ADR-03 ファイル存在 + 主要セクション + D-1〜D-5 参照の単一 assertion で完結                                                                       |
| SC-9  | TC-011               | GitHub Actions CI PASS は share-ci-monitoring 二重チェックで完結                                                                                  |
| SC-10 | TC-014               | TC-001〜TC-011 全 PASS の前提下で `roadmap-progress.yaml` の `completed` 化可能性を検証 (論理的帰結)                                              |

### 検証アクター × 検証スタイル分布

| Actor \ Style | assertion                                   | scenario                     | observation             | inspection        |
| ------------- | ------------------------------------------- | ---------------------------- | ----------------------- | ----------------- |
| automated     | 7 件 (TC-003, 004, 007, 009, 010, 011, 014) | 4 件 (TC-001, 002, 012, 013) | 3 件 (TC-005, 006, 008) | 0 件 (禁止組合せ) |
| ai-driven     | 0 件                                        | 0 件                         | 0 件                    | 0 件              |
| manual        | 0 件                                        | 0 件                         | 0 件                    | 0 件              |

合計 14 TC、すべて `automated`。`assertion` 中心 (7 件 = 50%)、`scenario` 4 件 (library smoke test、`vite-plus/test` 経由)、`observation` 3 件 (件数閾値 / grep カウント)。本サイクルが factory-only 抽出 + 4 consumer migration という性格上、Phase 1 (26 TC) より絞り込まれ、`ai-driven` / `manual` の組合せは不要 (= 「Rationale for automated vs. manual」節の方針通り)。

## Summary

Step 4 で TC-001 〜 TC-014 の **14 件** を定義、SC-1〜SC-10 のうち **10 件すべて** が観測手段確定 (P0: 2 件 / P1: 9 件 / P2: 3 件)、carry-over to Step 5 (Task Decomposition) は **4 件** (CO-1: TC-001 / TC-002 を T-A / T-B と同 atomic commit にする方針 / CO-2: TC-006 / TC-007 / TC-008 を consumer migration commit と同 atomic にする方針 / CO-3: TC-013 logger.test.ts の Effect 4.x API 確定タイミングを T-A subtask に予約 / CO-4: TC-009 hono-example smoke で test 不在時の Vite+ exit 0 振る舞いを T-F 前提として記録)。
