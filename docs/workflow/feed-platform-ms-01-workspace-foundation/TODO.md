# Task List: feed-platform-ms-01-workspace-foundation

- **Source:** `task-plan.md`
- **Active Steps:** Step 6-7 (Implementation / External Review)
- **Created at:** 2026-05-06T10:25:00Z
- **Last updated:** 2026-05-06T10:25:00Z

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

- [ ] **T-B** — feed-platform-backend Effect skeleton 5 ファイル
  - status: pending
  - dependencies: T-A
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: refinement #1 (Logger Env Service 経由) + #2 (await using) を反映

- [ ] **T-C** — feed-platform-backend health entry
  - status: pending
  - dependencies: T-A, T-B
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T-D** — feed-platform-backend bff entry
  - status: pending
  - dependencies: T-A, T-B
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: SC-5 (≥ 2 entry) の構造的担保完成

- [ ] **T-E** — feed-platform-backend smoke test
  - status: pending
  - dependencies: T-B
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T-F** — feed-platform-web プロジェクト初期化
  - status: pending
  - dependencies: なし (Wave 2 ルート)
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: hono-remix-v3-cloudflare-example 1:1 コピーベース、Counter / TODO / Frame サンプル削除

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

- [ ] **T-I** — identity-provider プロジェクト全体 (T-F〜T-H 同形コピー)
  - status: pending
  - dependencies: なし (Wave 2 ルート、T-F と完全並列可)
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: Better Auth 等は ms-02 委譲

- [ ] **T-J** — identity-provider DB binding コメント予約
  - status: pending
  - dependencies: T-I
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: TC-023 対応

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
