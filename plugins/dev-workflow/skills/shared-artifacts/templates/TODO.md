# Task List: {{identifier}}

- **Source:** `task-plan.md`
- **Active Steps:** Step 5〜6 (Implementation / Self-Review)
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}

このファイルは**永続化されたタスク状態**。Main 内部の `TaskCreate` タスクリストと同期するが、**こちらが真のソース**。状態変化時は TODO.md 更新 → コミット → TaskUpdate の順で実行する。

## 後発追加タスク（`task-plan.md` 以降に発生したもの）

{{appended_tasks_note}}

`task-plan.md` 不変運用の原則に従い、Step 5〜6 中に発見された追加タスクはここに記録する。追加理由を明記すること。

- なし（デフォルト）

## タスク

- [{{t1_checkbox}}] **T1** — {{t1_title}}
  - status: {{t1_status}} <!-- pending | in_progress | completed -->
  - dependencies: {{t1_dependencies}}
  - started_at: {{t1_started_at}}
  - completed_at: {{t1_completed_at}}
  - commit: {{t1_commit_sha}}
  - implementer: {{t1_implementer_id}}
  - re_activations: {{t1_re_activations}} <!-- Self-Review High 指摘で Step 5 に戻った回数 -->
  - notes: {{t1_notes}}

- [{{t2_checkbox}}] **T2** — {{t2_title}}
  - status: {{t2_status}}
  - dependencies: {{t2_dependencies}}
  - started_at: {{t2_started_at}}
  - completed_at: {{t2_completed_at}}
  - commit: {{t2_commit_sha}}
  - implementer: {{t2_implementer_id}}
  - re_activations: {{t2_re_activations}}
  - notes: {{t2_notes}}

<!-- 必要な数だけ T3, T4, ... を追加 -->

## 状態遷移ガイド

- `pending`: 未着手。`[ ]` 表示
- `in_progress`: `implementer` 起動中。`[ ]` 表示、`started_at` と `implementer` を記録
- `completed`: 完了。`[x]` 表示、`completed_at` と `commit` SHA を記録
- Self-Review High 指摘で戻す場合: `completed` → `in_progress` に戻し、`re_activations` をインクリメント

## コミット規約

- 各タスク状態変化ごとに 1 コミット（頻繁）
- コミットメッセージ例:
  - `docs(dev-workflow/{{identifier}}): start task T1`
  - `docs(dev-workflow/{{identifier}}): complete task T1`
  - `docs(dev-workflow/{{identifier}}): re-activate task T1 (self-review feedback)`
