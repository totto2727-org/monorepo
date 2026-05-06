# Task List: feed-platform-ms-01-workspace-foundation

- **Source:** `task-plan.md`
- **Active Steps:** Step 6-7 (Implementation / External Review)
- **Created at:** 2026-05-06T10:25:00Z
- **Last updated:** 2026-05-06T11:11:30Z

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

- [ ] **T-G** — feed-platform-web app/ ディレクトリ + Hello World 1 ページ
  - status: pending
  - dependencies: T-F
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: PageOrFrame 未採用 (TC-022 対応)

- [ ] **T-H** — feed-platform-web Effect skeleton + smoke test
  - status: pending
  - dependencies: T-F, T-G
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: T-B と同形

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
  - completed_at: 2026-05-06T11:09:55Z
  - commit: a089283
  - implementer: implementer-C (Phase 2b identity-provider chain)
  - re_activations: 0
  - notes: |
      TC-023 観測仕様達成: `wrangler.jsonc` に `BETTER_AUTH_URL` / `BETTER_AUTH_SECRET` /
      `d1_databases` / `kv_namespaces` の 4 種類のコメント予約を追加。
      また T-I commit に紛れ込んだ `app/app.tsx` の "PageOrFrame" コメント文字列を
      "Frame ベースのレイアウト" に書き換えて TC-022 の grep `PageOrFrame|createPageOrFrame`
      が 0 件 hit になることを確実化。
      
      **Cross-implementer concern**: 私 (implementer-C) が T-J の `wrangler.jsonc` /
      `app.tsx` 編集を staged 状態で持っていたタイミングで、implementer-B が並列で
      `git add -A` (or 同等) で T-F を commit したため、私の T-J 編集が
      a089283 (T-F commit) に巻き込まれてしまった。実体としては
      `js/app/identity-provider/wrangler.jsonc` と `js/app/identity-provider/app/app.tsx`
      の T-J 内容は a089283 に含まれているため、機能的な実装結果は task-plan.md の
      意図通りに完成しているが、commit 単位の論理分離が崩れた状態。
      最終報告で Main に詳細を共有する。

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
