# Task List: feed-platform-ms-01-workspace-foundation

- **Source:** `task-plan.md`
- **Active Steps:** Step 6-7 (Implementation / External Review)
- **Created at:** 2026-05-06T10:25:00Z
- **Last updated:** 2026-05-06T11:21:30Z

本ファイルは Step 6-7 中の **persisted task state**。Main の `TaskCreate` task list と同期するが、**こちらが source of truth**。状態変更時は TODO.md → commit → `TaskUpdate` の順で更新する。

## Tasks added later (after `task-plan.md` was finalized)

- None (default)

## Tasks

- [x] **T-A** — feed-platform-backend プロジェクト初期化
  - status: completed
  - dependencies: なし (root)
  - started_at: 2026-05-06T10:36:00Z
  - completed_at: 2026-05-06T10:50:00Z
  - commit: 2881bfa
  - implementer: implementer-A (Phase 1 backend chain)
  - re_activations: 0
  - notes: Wave 1 root。`vite.config.ts` の setup task は wrangler.jsonc 配置 (T-C/T-D) を前提とするため、本タスク段階で `vp run setup` 単体は通らない (T-C/T-D 完了後に通る設計)。`pnpm install` は repo root で成功

- [x] **T-B** — feed-platform-backend Effect skeleton 5 ファイル
  - status: completed
  - dependencies: T-A
  - started_at: 2026-05-06T10:51:00Z
  - completed_at: 2026-05-06T10:58:00Z
  - commit: 49784f2
  - implementer: implementer-A (Phase 1 backend chain)
  - re_activations: 0
  - notes: refinement #1 (Logger Env Service 経由) + #2 (await using) を反映。design.md の `ServiceMap.Service` は `effect@4.0.0-beta.60` 非対応のため `Context.Service` に置換 (saas-example 整合)。dynamicLoggerLayer の Env 依存解決のために Env Layer を `Layer.provide(envLayer)` で内部に重ねる形式に微調整

- [x] **T-C** — feed-platform-backend health entry
  - status: completed
  - dependencies: T-A, T-B
  - started_at: 2026-05-06T10:58:00Z
  - completed_at: 2026-05-06T11:02:00Z
  - commit: 7812ba6
  - implementer: implementer-A (Phase 1 backend chain)
  - re_activations: 0
  - notes: `vp run setup:cloudflare:health` で worker-configuration.d.ts 生成確認済

- [x] **T-D** — feed-platform-backend bff entry
  - status: completed
  - dependencies: T-A, T-B
  - started_at: 2026-05-06T11:02:00Z
  - completed_at: 2026-05-06T11:06:00Z
  - commit: 2460fe9
  - implementer: implementer-A (Phase 1 backend chain)
  - re_activations: 0
  - notes: SC-5 (≥ 2 entry) の構造的担保完成。`find src -name worker.ts | wc -l = 2`

- [x] **T-E** — feed-platform-backend smoke test
  - status: completed
  - dependencies: T-B
  - started_at: 2026-05-06T11:06:00Z
  - completed_at: 2026-05-06T11:10:00Z
  - commit: 12cab81
  - implementer: implementer-A (Phase 1 backend chain)
  - re_activations: 0
  - notes: `vp test run src/smoke.test.ts` PASS 確認。vite-plus/test 暗黙 config 利用、vitest.config 新設なし

- [x] **T-F** — feed-platform-web プロジェクト初期化
  - status: completed
  - dependencies: なし (Wave 2 ルート)
  - started_at: 2026-05-06T10:59:00Z
  - completed_at: 2026-05-06T11:11:30Z
  - commit: 8fa4df2
  - implementer: implementer-B (Phase 2a web chain)
  - re_activations: 0
  - notes: |
    hono-remix-v3-cloudflare-example 1:1 コピーベースで package.json /
    tsconfig.json / vite.config.ts / wrangler.jsonc / .gitignore を配置。
    vite.config.ts には setup:cloudflare task (wrangler types) を追加。
    Counter / TODO / Frame サンプルや routes.ts は採用しない (PageOrFrame
    未採用、TC-022)。`pnpm install --no-frozen-lockfile` で依存解決成功。

    **Cross-implementer concern (要 Main 確認)**: 私の最初の T-F commit
    作成時、implementer-C が同時並行で T-J 用に編集中だった
    `js/app/identity-provider/{app/app.tsx, wrangler.jsonc}` の unstaged 変更
    が、私の `git add js/app/feed-platform-web/` の影響範囲外であったにも
    関わらず最初の commit (a089283) に巻き込まれて作成された (原因不明、
    git の通常動作では起こり得ない)。私はその commit を `git update-ref`
    で巻き戻し `8fa4df2` を再 commit した結果、orphan となった a089283 を
    implementer-C は **T-J commit として TODO.md L111 に記録済み**。
    a089283 自体は reflog に残っており、内容は T-J の正しい変更。
    最終的な対処は Main 判断に委ねる (implementer-C による T-J 再 commit
    が必要)。

- [x] **T-G** — feed-platform-web app/ ディレクトリ + Hello World 1 ページ
  - status: completed
  - dependencies: T-F
  - started_at: 2026-05-06T11:13:00Z
  - completed_at: 2026-05-06T11:18:00Z
  - commit: ee21531
  - implementer: implementer-B (Phase 2a web chain)
  - re_activations: 0
  - notes: |
    `app/{entry.worker.ts, app.tsx, routes.ts, assets/entry.ts, ui/document.tsx}` を配置。
    middleware order = `logger → contextStorage → runtimeMiddleware → remixRenderer`
    (design.md L268-271)。`/` で素朴な `c.render(<Document>...)` の Hello World、
    `/api/v1/hello` で `c.var.runtime.runPromise` 経由 Greeting Service を呼ぶ JSON loader 実装。
    `routes.ts` の `frames` は空 + `isFrameRequest` のみ最小 export (将来 PageOrFrame 採用時の足場)。
    `Hono<AppEnv>` の自己参照 TS7022/7023 を `const app: Hono<AppEnv>` 注釈 +
    `fetcher` 戻り値型明示で解消 (identity-provider 同形)。
    Effect skeleton 未配置のため本 commit 単独では型エラーを含む状態 (T-H で解消予定、
    task-plan.md "Per-task CI failures acceptable mid-chain" 方針)。

- [x] **T-H** — feed-platform-web Effect skeleton + smoke test
  - status: completed
  - dependencies: T-F, T-G
  - started_at: 2026-05-06T11:19:00Z
  - completed_at: 2026-05-06T11:21:00Z
  - commit: b5d0bba
  - implementer: implementer-B (Phase 2a web chain)
  - re_activations: 0
  - notes: |
    `app/feature/{env, greeting, health, runtime/server, runtime/hono}.ts` の 5 ファイルと
    `app/smoke.test.ts` を配置。Phase 1 deviation を踏襲:
    Context.Service (NOT ServiceMap.Service) + dynamicLoggerLayer は
    `Layer.provide(envLayer)` で Env を内包させる形式。
    Service tag namespace は `@app/feed-platform-web/feature/<name>/Service` (CC-6)。
    `vp test run js/app/feed-platform-web/app/smoke.test.ts` は 1 件 PASS。
    `vp check` は feed-platform-web 内では識別子エラー 0 件。
    rss-graphql の既存 86 errors は本サイクル責任外で継続。

- [x] **T-I** — identity-provider プロジェクト全体 (T-F〜T-H 同形コピー)
  - status: completed
  - dependencies: なし (Wave 2 ルート、T-F と完全並列可)
  - started_at: 2026-05-06T10:59:28Z
  - completed_at: 2026-05-06T11:07:11Z
  - commit: da5dfaf
  - implementer: implementer-C (Phase 2b identity-provider chain)
  - re_activations: 0
  - notes: hono-remix-v3-cloudflare-example 構成踏襲、Counter / TODO / Frame サンプル削除、PageOrFrame 不採用 (TC-022)。Phase 1 deviation (Context.Service + dynamicLoggerLayer の Env closure) を踏襲。`Hono<AppEnv>` chain 中 `app` 自己参照の TS7022/TS7023 を `const app: Hono<AppEnv>` 明示 + `fetcher` 戻り値型明示で解消。`vp test run js/app/identity-provider/app/smoke.test.ts` は 2 件 PASS。`vp check` は識別子のエラー 0 件 (rss-graphql の既存 86 件は既存問題で本タスク責任外)。OAuth 2.1 / Better Auth は ms-02 委譲

- [x] **T-J** — identity-provider DB binding コメント予約
  - status: completed
  - dependencies: T-I
  - started_at: 2026-05-06T11:07:50Z
  - completed_at: 2026-05-06T11:13:30Z
  - commit: 80f3ca8
  - implementer: implementer-C (Phase 2b identity-provider chain)
  - re_activations: 0
  - notes: |
    TC-023 観測仕様達成: `wrangler.jsonc` に `BETTER_AUTH_URL` / `BETTER_AUTH_SECRET` /
    `d1_databases` / `kv_namespaces` の 4 種類のコメント予約を追加。
    副次変更で `app/app.tsx` のコメントから "PageOrFrame" 文字列を削除し、
    TC-022 観測仕様 (`grep -E 'PageOrFrame|createPageOrFrame'` 0 hit) を
    コメントレベルでも完全に満たす状態に整理。

    **Cross-implementer concern (記録 / Main 確認推奨)**:
    当初 T-J 用に staged していた `identity-provider/wrangler.jsonc` /
    `app/app.tsx` の編集が、implementer-B の並列 T-F commit に巻き込まれて
    orphan commit (a089283) として作成され、その後 reflog で巻き戻されて
    実体は worktree 上にのみ残存 → 改めて私が `80f3ca8` として T-J commit を
    作成した経緯がある (詳細は最終報告)。最終的なリポジトリ状態は task-plan.md
    の意図通り (T-F = 8fa4df2 / T-I = da5dfaf / T-J = 80f3ca8 が独立 commit)
    で完成しており、機能的な乖離はなし。implementer-B 側 (T-F notes) の
    cross-implementer concern 記述と合わせて Main 側で判断を確認することを
    推奨する。

- [ ] **T-K** — ADR-01 起票 (Roadmap mode)
  - status: pending
  - dependencies: T-A〜T-J
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: share-adr Roadmap mode 経由

- [ ] **T-L** — ADR-02 起票 (General mode)
  - status: pending
  - dependencies: T-A〜T-J
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: share-adr General mode 経由

## State transition guide

- `pending`: 未着手。`[ ]` 表示
- `in_progress`: implementer 実行中。`[ ]` 表示、`started_at` + `implementer` を記録
- `completed`: 完了。`[x]` 表示、`completed_at` + `commit` SHA を記録
- External Review Blocker による戻し: `completed` → `in_progress` に戻し、`re_activations` を +1

## Commit conventions

- 1 タスク状態変更 = 1 commit (頻繁に commit する)
- Example commit messages:
  - `docs(dev-workflow/feed-platform-ms-01-workspace-foundation): start task T-A`
  - `feat(dev-workflow/feed-platform-ms-01-workspace-foundation/T-A): create feed-platform-backend project skeleton`
  - `docs(dev-workflow/feed-platform-ms-01-workspace-foundation): complete task T-A`
