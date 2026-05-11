# Task List: feed-platform-ms-01-shared-libraries

- **Source:** `task-plan.md`
- **Active Steps:** Step 6-7 (Implementation / External Review)
- **Created at:** 2026-05-10T10:30:00Z
- **Last updated:** 2026-05-10T10:30:00Z

本ファイルは Step 6-7 中の **persisted task state**。Main の `TaskCreate` task list と同期するが、**こちらが source of truth**。状態変更時は TODO.md → commit → `TaskUpdate` の順で更新する。

## Tasks added later (after `task-plan.md` was finalized)

- None (default)

## Tasks

- [ ] **T-A** — effect-hono library skeleton + TC-001 smoke test
  - dependencies: なし (Wave 1 root、T-B と完全並列)
  - status: pending
  - estimated size: M (30min〜2h)
  - sub-tasks:
    - [ ] T-A.1: `js/package/effect-hono/package.json` 作成 (name: `effect-hono` / private: true / exports: `{ ".": "./src/index.ts" }` / peerDeps: `effect: catalog:effect`)
    - [ ] T-A.2: `js/package/effect-hono/tsconfig.json` 作成 (`extends: ["@totto2727/fp/tsconfig/vite"]`)
    - [ ] T-A.3: `src/env.ts` 実装 (R-1: `Type = 'production' | 'development'` 直接 union + `Service` Context.Service tag + `layer` (Layer.sync from `process.env.NODE_ENV`) + `makeLayer` test 用)
    - [ ] T-A.4: `src/logger.ts` 実装 (R-2: `dynamicLoggerLayer: Layer.Layer<never, never, Env.Type>` Env-open。具体 Effect 4.x API は `effect/dist/dts/Logger.d.ts` / `Layer.d.ts` を参照して確定)
    - [ ] T-A.5: `src/runtime.ts` 実装 (`makeDisposableRuntime<Args, R, ER>` wrapper class factory、U-other-A)
    - [ ] T-A.6: `src/index.ts` barrel 作成 (`Env` namespace + `runtime` / `logger` re-export)
    - [ ] T-A.7: `src/runtime.test.ts` 実装 (TC-001 P0、`Layer.empty` smoke + `expectTypeOf` 型レベル)
    - [ ] T-A.8: `pnpm install` で workspace 取り込み確認
    - [ ] T-A.9: `vp run --filter effect-hono check` exit 0 確認
    - [ ] T-A.10: `vp run --filter effect-hono test` exit 0 確認 (TC-001 PASS)
    - [ ] T-A.11: atomic commit `feat(dev-workflow/feed-platform-ms-01-shared-libraries/T-A): effect-hono skeleton + TC-001`

- [ ] **T-B** — remix-helper library skeleton + TC-002 smoke test
  - dependencies: なし (Wave 1 root、T-A と完全並列)
  - status: pending
  - estimated size: M (30min〜2h)
  - sub-tasks:
    - [ ] T-B.1: `js/package/remix-helper/package.json` 作成 (name: `remix-helper` / private: true / exports: `{ ".": "./src/index.ts" }` / peerDeps: `remix: catalog:remix`、**`hono` を peerDeps に書かない**)
    - [ ] T-B.2: `js/package/remix-helper/tsconfig.json` 作成 (`extends: ["@totto2727/fp/tsconfig/vite"]` + `jsxImportSource: "remix/ui"`)
    - [ ] T-B.3: `src/frame-helpers.ts` 実装 (R-5 / R-6: `createFrameHelpers<T extends string>()` factory + `FrameHelpers<T>` interface (`isFrameRequest` / `createPageOrFrame` / `FrameLink`))
    - [ ] T-B.4: `src/index.ts` barrel 作成 (`export * from './frame-helpers.ts'`)
    - [ ] T-B.5: `src/frame-helpers.test.ts` 実装 (TC-002 P0、`createFrameHelpers<'a' | 'b'>()` smoke + `expectTypeOf` + `// @ts-expect-error`)
    - [ ] T-B.6: `pnpm install` で workspace 取り込み確認
    - [ ] T-B.7: `grep -n 'hono' js/package/remix-helper/package.json` で 0 hit 確認 (U-3 Hono フリー化担保)
    - [ ] T-B.8: `vp run --filter remix-helper check` exit 0 確認
    - [ ] T-B.9: `vp run --filter remix-helper test` exit 0 確認 (TC-002 PASS)
    - [ ] T-B.10: atomic commit `feat(dev-workflow/feed-platform-ms-01-shared-libraries/T-B): remix-helper skeleton + TC-002`

- [ ] **T-C** — feed-platform-backend を effect-hono に migrate
  - dependencies: T-A 完了。T-D / T-E / T-F と完全並列実行可能
  - status: pending
  - estimated size: S (≤30min、機械的 import 切替)
  - sub-tasks:
    - [ ] T-C.1: `src/feature/env.ts` を `import { Env } from 'effect-hono'` に切替 + 旧 `Env.*` 定義削除
    - [ ] T-C.2: `src/feature/runtime/server.ts` を `import { dynamicLoggerLayer, makeDisposableRuntime } from 'effect-hono'` に切替 + 旧 `dynamicLoggerLayer` / 旧 HOF / 旧 `DisposableRuntime` interface 削除
    - [ ] T-C.3: `src/feature/runtime/hono.ts` の `Variables.runtime` 型源を `ReturnType<typeof makeRuntime>` に変更
    - [ ] T-C.4: `package.json.devDependencies` に `effect-hono: workspace:*` 追加 + `pnpm install`
    - [ ] T-C.5: `vp run --filter feed-platform-backend check` exit 0 確認
    - [ ] T-C.6: `vp run --filter feed-platform-backend test` exit 0 確認 (regression check)
    - [ ] T-C.7: TC-006 観測 — `grep -rE 'dynamicLoggerLayer|DisposableRuntime' --include='*.ts' --include='*.tsx' js/app/feed-platform-backend/` で 0 hit 確認
    - [ ] T-C.8: atomic commit `refactor(dev-workflow/feed-platform-ms-01-shared-libraries/T-C): migrate feed-platform-backend to effect-hono`

- [ ] **T-D** — feed-platform-web を effect-hono + remix-helper に migrate
  - dependencies: T-A 完了 + T-B 完了。T-C / T-E / T-F と完全並列実行可能
  - status: pending
  - estimated size: M (30min〜2h、`routes.ts` adapter 構築 + 2 library 同時 migration)
  - sub-tasks:
    - [ ] T-D.1: `app/feature/env.ts` を effect-hono import に切替 + 旧コード削除
    - [ ] T-D.2: `app/feature/runtime/server.ts` を effect-hono import に切替 + 旧コード削除
    - [ ] T-D.3: `app/feature/runtime/hono.ts` の `Variables.runtime` 型源変更 (T-C 同形)
    - [ ] T-D.4: `app/routes.ts` を `type FrameName = never` + `const helpers = createFrameHelpers<FrameName>()` + `getContext().req.raw` adapter pattern に置換 (空相当、option A)
    - [ ] T-D.5: `package.json.devDependencies` に `effect-hono: workspace:*` + `remix-helper: workspace:*` 追加 + `pnpm install`
    - [ ] T-D.6: `vp run --filter feed-platform-web check` exit 0 確認
    - [ ] T-D.7: `vp run --filter feed-platform-web test` exit 0 確認 (regression check)
    - [ ] T-D.8: TC-006 観測 — `grep -rE 'dynamicLoggerLayer|DisposableRuntime' js/app/feed-platform-web/` で 0 hit 確認
    - [ ] T-D.9: TC-008 観測 — `grep -rn 'createFrameHelpers' js/app/feed-platform-web/` で ≥ 1 hit 確認
    - [ ] T-D.10: atomic commit `refactor(dev-workflow/feed-platform-ms-01-shared-libraries/T-D): migrate feed-platform-web to effect-hono + remix-helper`

- [ ] **T-E** — identity-provider を effect-hono + remix-helper に migrate (T-D 同形)
  - dependencies: T-A 完了 + T-B 完了。T-C / T-D / T-F と完全並列実行可能
  - status: pending
  - estimated size: M (30min〜2h、T-D とほぼコピー作業)
  - sub-tasks:
    - [ ] T-E.1: `app/feature/env.ts` を effect-hono import に切替 (T-D 同形)
    - [ ] T-E.2: `app/feature/runtime/server.ts` を effect-hono import に切替 (T-D 同形)
    - [ ] T-E.3: `app/feature/runtime/hono.ts` の `Variables.runtime` 型源変更 (T-D 同形)
    - [ ] T-E.4: `app/routes.ts` を `type FrameName = never` + `createFrameHelpers<FrameName>()` + adapter に置換
    - [ ] T-E.5: `package.json.devDependencies` に effect-hono + remix-helper 追加 + `pnpm install`
    - [ ] T-E.6: `vp run --filter identity-provider check` exit 0 確認
    - [ ] T-E.7: `vp run --filter identity-provider test` exit 0 確認 (regression check)
    - [ ] T-E.8: TC-006 観測 — `grep -rE 'dynamicLoggerLayer|DisposableRuntime' js/app/identity-provider/` で 0 hit
    - [ ] T-E.9: TC-008 観測 — `grep -rn 'createFrameHelpers' js/app/identity-provider/` で ≥ 1 hit
    - [ ] T-E.10: atomic commit `refactor(dev-workflow/feed-platform-ms-01-shared-libraries/T-E): migrate identity-provider to effect-hono + remix-helper`

- [ ] **T-F** — hono-remix-v3-cloudflare-example を remix-helper に migrate
  - dependencies: T-B 完了 (T-A 不要、effect-hono は本 project 対象外)。T-C / T-D / T-E と完全並列実行可能
  - status: pending
  - estimated size: M (30min〜2h、`routes.ts` 置換 + 2 ファイル削除 + `content-layout.tsx` adapter 経由化)
  - 前提 (CO-4): `vp run --filter hono-remix-v3-cloudflare-example test` は test 不在の場合でも 0 件 PASS で exit 0 を返す Vite+ 仕様
  - sub-tasks:
    - [ ] T-F.1: `app/routes.ts` を `type FrameName = 'content'` + `createFrameHelpers<FrameName>()` + `getContext().req.raw` adapter + `FrameLink` re-export に置換
    - [ ] T-F.2: `app/ui/page-or-frame.tsx` を `git rm` で削除
    - [ ] T-F.3: `app/ui/frame-link.tsx` を `git rm` で削除
    - [ ] T-F.4: `app/ui/content-layout.tsx` を修正 — `createPageOrFrame(frame, Layout)(request)` の `request` bind を adapter 経由に変更
    - [ ] T-F.5: `package.json.devDependencies` に `remix-helper: workspace:*` 追加 + `pnpm install`
    - [ ] T-F.6: `vp run --filter hono-remix-v3-cloudflare-example check` exit 0 確認
    - [ ] T-F.7: `vp run --filter hono-remix-v3-cloudflare-example test` exit 0 確認 (TC-009、CO-4 前提)
    - [ ] T-F.8: TC-007 観測 — `[ ! -f js/app/hono-remix-v3-cloudflare-example/app/ui/page-or-frame.tsx ]` + `[ ! -f .../frame-link.tsx ]` 両成立
    - [ ] T-F.9: TC-008 観測 — `grep -rn 'createFrameHelpers' js/app/hono-remix-v3-cloudflare-example/` で ≥ 1 hit
    - [ ] T-F.10: atomic commit `refactor(dev-workflow/feed-platform-ms-01-shared-libraries/T-F): migrate hono-remix-v3-cloudflare-example to remix-helper`

- [ ] **T-G** — ADR-03 を `confirmed: true` に promote + roadmap-progress.yaml ms-01 completed 化
  - dependencies: T-A〜T-F すべて完了
  - status: pending
  - estimated size: S (≤30min、ADR フラグ切替 + roadmap-progress 更新 + 検証)
  - sub-tasks:
    - [ ] T-G.1: `docs/roadmap/feed-platform/adr/2026-05-08-shared-libraries-extraction.md` の frontmatter `confirmed` を `false → true` に変更、必要に応じて 5 セクション (Status / Context / Decision / Consequences / References) + D-1〜D-5 参照を最終確認
    - [ ] T-G.2: TC-010 観測 — `[ -f ${ADR_PATH} ]` + `grep -cE '^## (Status|Context|Decision|Consequences|References)' = 5` + D-1〜D-5 各 ≥ 1 hit
    - [ ] T-G.3: `docs/roadmap/feed-platform/roadmap-progress.yaml` の `milestones[ms-01-workspace-foundation]` を Phase 2 完了状態として `completed` に再遷移、`blockers` 空を確認、Phase 2 完了 note を追記
    - [ ] T-G.4: TC-005 観測 — `vp run -r build` exit 0 + 3 web projects (`feed-platform-web` / `identity-provider` / `hono-remix-v3-cloudflare-example`) の `find dist/client -type f | wc -l` ≥ 1
    - [ ] T-G.5: TC-014 観測 — `yq '.milestones[] | select(.id == "ms-01-workspace-foundation")' docs/roadmap/feed-platform/roadmap-progress.yaml` で `blockers` が空 or 未定義
    - [ ] T-G.6: atomic commit `docs(dev-workflow/feed-platform-ms-01-shared-libraries/T-G): promote ADR-03 to confirmed + ms-01 Phase 2 completed`
    - [ ] T-G.7: push 後 TC-011 観測 — share-ci-monitoring 二重チェックで GitHub Actions CI PASS 確認 (Main agent が実施、最大 2 回リトライ後失敗時は Blocker)

## State transition guide

- `pending`: 未着手。`[ ]` 表示
- `in_progress`: implementer 実行中。`[ ]` 表示、`started_at` + `implementer` を記録
- `completed`: 完了。`[x]` 表示、`completed_at` + `commit` SHA を記録
- External Review Blocker による戻し: `completed` → `in_progress` に戻し、`re_activations` を +1

## Commit conventions

- 1 タスク状態変更 = 1 commit (頻繁に commit する)
- 1 タスク = 1 atomic implementation commit (= 中間状態許容なし、Phase 1 ADR-01 D-6 慣行継承)
- Example commit messages:
  - `docs(dev-workflow/feed-platform-ms-01-shared-libraries): start task T-A`
  - `feat(dev-workflow/feed-platform-ms-01-shared-libraries/T-A): effect-hono skeleton + TC-001`
  - `refactor(dev-workflow/feed-platform-ms-01-shared-libraries/T-D): migrate feed-platform-web to effect-hono + remix-helper`
  - `docs(dev-workflow/feed-platform-ms-01-shared-libraries): complete task T-A`
