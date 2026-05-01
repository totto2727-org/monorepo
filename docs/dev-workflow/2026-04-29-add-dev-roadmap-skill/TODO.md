# Task List: 2026-04-29-add-dev-roadmap-skill

- **Source:** `task-plan.md`
- **Active Steps:** Step 6〜7 (Implementation / External Review)
- **Created at:** 2026-05-01T03:30:00Z
- **Last updated:** 2026-05-01T03:30:00Z

> **Path 注記**: T0 (storage rename) 完了後、本ファイル自身が `docs/workflow/2026-04-29-add-dev-roadmap-skill/TODO.md` に移動する。Step 6 implementer は移動後パスで作業を継続。

このファイルは**永続化されたタスク状態**。Main 内部の `TaskCreate` タスクリストと同期するが、**こちらが真のソース**。状態変化時は TODO.md 更新 → コミット → TaskUpdate の順で実行する。

## 後発追加タスク (`task-plan.md` 以降に発生したもの)

- なし (デフォルト)

## タスク

- [ ] **T0** — 保存先ディレクトリの一括リネーム (`docs/dev-workflow/` → `docs/workflow/`、`docs/roadmap/` 新規作成)
  - status: pending
  - dependencies: なし
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: 必須先行・単独コミット。`git mv` のみで内容変更なし。

- [ ] **T1** — `dev-roadmap/SKILL.md` 新規作成
  - status: pending
  - dependencies: T0
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T2** — `specialist-roadmap-analyst/SKILL.md` 新規作成
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T3** — `specialist-roadmap-planner/SKILL.md` 新規作成
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T4** — `specialist-roadmap-retrospective-writer/SKILL.md` 新規作成
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T5** — roadmap 系 Agent 定義 3 個の新規作成
  - status: pending
  - dependencies: T2, T3, T4
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T6** — `progress.yaml` テンプレート + reference 拡張 (`roadmap` ネストブロック)
  - status: pending
  - dependencies: T0
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T7** — 新規テンプレート/リファレンス 4 セット (roadmap.md / milestone.md / roadmap-progress.yaml / roadmap-retrospective.md)
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: 8 ファイル一括、必要なら T7a〜T7d に分割可能 (R6)

- [ ] **T8** — `shared-artifacts/SKILL.md` 追記 (成果物一覧 + 1:1 例外 + 保存構造 + path 置換)
  - status: pending
  - dependencies: T7
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T9** — `dev-workflow/SKILL.md` 追記 (起動時連携 + roadmap-progress.yaml 更新プロトコル + path 置換)
  - status: pending
  - dependencies: T6
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T10** — `specialist-common/SKILL.md` 追記 (Specialist 列挙 9 → 12 + Do NOT use for + path 置換)
  - status: pending
  - dependencies: T2, T3, T4
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T11** — `plugins/dev-workflow/README.md` 追記 (dev-roadmap の位置づけ)
  - status: pending
  - dependencies: T5, T8, T9, T10
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: 収束タスク

- [ ] **T12** — 検証用 manual-tests 手順書 (TC-025 / TC-032)
  - status: pending
  - dependencies: T1, T7, T8
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

## 状態遷移ガイド

- `pending`: 未着手。`[ ]` 表示
- `in_progress`: `implementer` 起動中。`[ ]` 表示、`started_at` と `implementer` を記録
- `completed`: 完了。`[x]` 表示、`completed_at` と `commit` SHA を記録
- External Review Blocker 指摘で戻す場合: `completed` → `in_progress` に戻し、`re_activations` をインクリメント

## コミット規約

- 各タスク状態変化ごとに 1 コミット (頻繁)
- コミットメッセージ例:
  - `docs(dev-workflow/2026-04-29-add-dev-roadmap-skill): start task T1`
  - `feat(dev-workflow/2026-04-29-add-dev-roadmap-skill/task-T1): create dev-roadmap SKILL.md`
  - `docs(dev-workflow/2026-04-29-add-dev-roadmap-skill): complete task T1`
