# Intent Spec: feed-platform Shared Libraries (ms-01 Phase 2)

- **Identifier:** feed-platform-ms-01-shared-libraries
- **Author:** totto2727 (Main 起草)
- **Created at:** 2026-05-07T03:55:00Z
- **Last updated:** 2026-05-07T03:55:00Z
- **Roadmap:** `feed-platform` / milestone `ms-01-workspace-foundation` (Phase 2)
- **Phase 1 (= 前 cycle):** `feed-platform-ms-01-workspace-foundation` (completed 2026-05-07、retrospective: `docs/retrospective/feed-platform-ms-01-workspace-foundation.md`)

## Background

Phase 1 cycle (`feed-platform-ms-01-workspace-foundation`) で 3 プロジェクト (`feed-platform-backend` / `feed-platform-web` / `identity-provider`) の Hello World レベル雛形を整備した結果、各プロジェクトに **完全同形コピーされた共通ロジック** が存在する状態となった (Phase 1 review reports / retrospective で言及済の DRY 違反候補)。

User 戦略指示 (2026-05-06): 「ms-02 (認証) 着手前に新規共通化マイルストーンをロードマップに挿入する。対象は dynamicLoggerLayer / makeDisposableRuntime / feature/env.ts / isFrameRequest / PageOrFrame / 他 Remix・Effect 横断ユーティリティ。」

本 cycle は ms-01 マイルストーンの Phase 2 として、上記同形コピーを `js/package/` 配下のライブラリに抽出し、3 プロジェクトすべてが共通ライブラリを参照する形に refactor する。

## Purpose

(Step 1 対話で確定 — TBD)

## Scope

Step 1 対話で 1 つずつ確定し追記する (会話駆動・漸増方式、`feedback_conversational_workflow.md` 準拠)。

### 確定済み

(なし、これから Step 1 対話で確定)

### 抽出候補 (Step 1 対話で具体合意する一次入力)

User 戦略指示で挙げられた候補:

- **Effect runtime 系** (現在 3 プロジェクトの `feature/runtime/server.ts` に同形配置):
  - `dynamicLoggerLayer` (`Layer.unwrap` + `Env.Service` 経由 Logger 形式判定 + `Logger.consoleJson` / `Logger.consolePretty()` 切替)
  - `makeDisposableRuntime` HOF (TC39 `await using` + `DisposableRuntime` クラス + `Symbol.asyncDispose` 実装)
- **Effect Service 系** (現在 3 プロジェクトの `feature/env.ts` に同形配置):
  - `feature/env.ts` (`process.env.NODE_ENV` 経由 ENV 派生 + `Env.Service` + `makeLayer` (test 用))
- **Remix UI 系** (現在 web/IdP の `app/routes.ts` / `app/ui/` 系に同形配置 or 不在):
  - `isFrameRequest` (`hono-remix-v3-cloudflare-example/app/routes.ts` ベース)
  - `createPageOrFrame` (`hono-remix-v3-cloudflare-example/app/ui/page-or-frame.tsx` ベース、ms-01 雛形では未採用、ms-04 / ms-07 で本格採用前提)
- **その他 Remix / Effect 横断ユーティリティ** (Step 1 対話で具体特定):
  - 候補例: `feature/runtime/hono.ts` の Hono middleware (`await using runtime = ...`)、`feature/greeting.ts` (もしくは Greeting Service の汎用化判断)、`feature/health.ts`、各プロジェクトの `tsconfig.json` 共通設定 等
  - 既存 `js/package/` (e.g., `@totto2727/fp` / `hono-remix-middleware` / `vite-plugin-remix`) との責務切り分けも論点

### 未確定 (後続ターンで追記)

- 抽出範囲の確定 (どの候補を本 cycle で扱うか、ms-02 以降に委譲する候補があるか)
- 共通ライブラリの配置先 (`js/package/<新規パッケージ名>` の構造、1 パッケージ集約 vs 複数パッケージ分割)
- 命名規約 (`@totto2727/...` / `@app/...` / `@<scope>/...` / scope なし flat name のいずれか)
- API surface (re-export 形式 / namespace / barrel export)
- 移行戦略 (3 プロジェクトの既存 import を一括書き換えするか / 段階的か)
- ADR 起票範囲 (Phase 1 ADR-01 を補足する形で本 cycle 用 ADR を起票するか / Phase 1 ADR-01 を Superseded して新 ADR を起票するか / 起票不要か)
- 既存 `@totto2727/fp` / `hono-remix-middleware` / `vite-plugin-remix` との責務切り分け方針

## Out of scope

(Step 1 対話で確定 — TBD)

## Success criteria

Step 1 対話で 1 つずつ確定し追記する (会話駆動・漸増方式)。観測可能な形で記述する。

- (TBD)

## Constraints

(Step 1 対話で確定 — TBD)

## Related links

- ロードマップ: `docs/roadmap/feed-platform/roadmap.md`
- マイルストーン: `docs/roadmap/feed-platform/milestones/ms-01-workspace-foundation.md` (Phase 2 セクション)
- Phase 1 retrospective: `docs/retrospective/feed-platform-ms-01-workspace-foundation.md` (改善候補 + DRY 違反指摘)
- Phase 1 design: `docs/workflow/feed-platform-ms-01-workspace-foundation/design.md` (Anticipated extension points 表 + 3 プロジェクト共通 Effect skeleton snippet)
- Phase 1 ADR-01: `docs/roadmap/feed-platform/adr/2026-05-05-project-structure-and-runtime.md`
- Phase 1 ADR-02: `docs/adr/2026-05-05-identity-provider-and-authn-authz-architecture.md`
- ロードマップ進捗: `docs/roadmap/feed-platform/roadmap-progress.yaml`

## Open questions

Step 1 対話の進行に伴って追記。

- (TBD)
