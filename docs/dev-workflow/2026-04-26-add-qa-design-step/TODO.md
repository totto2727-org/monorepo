# Task List: 2026-04-26-add-qa-design-step

- **Source:** `task-plan.md`
- **Active Steps:** Step 5〜6 (Implementation / Self-Review)
- **Created at:** 2026-04-26T16:00:00Z
- **Last updated:** 2026-04-26T16:00:00Z

このファイルは**永続化されたタスク状態**。Main 内部の `TaskCreate` タスクリストと同期するが、**こちらが真のソース**。状態変化時は TODO.md 更新 → コミット → TaskUpdate の順で実行する。

## 後発追加タスク (`task-plan.md` 以降に発生したもの)

`task-plan.md` 不変運用の原則に従い、Step 5〜6 中に発見された追加タスクはここに記録する。追加理由を明記すること。

- なし (デフォルト)

## タスク

- [ ] **T1** — shared-artifacts に qa-design / qa-flow の reference + template を追加
  - status: pending
  - dependencies: なし (Wave 1 起点)
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: 4 ファイル新規 (references/qa-design.md, references/qa-flow.md, templates/qa-design.md, templates/qa-flow.md)

- [ ] **T2** — specialist-qa-analyst skill + agent を新規作成
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: 2 ファイル新規 (specialist-qa-analyst/SKILL.md, agents/qa-analyst.md)

- [ ] **T3** — dev-workflow/SKILL.md の大規模更新
  - status: pending
  - dependencies: なし (Wave 1 起点、T1 と並列可)
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: 1 ファイル大規模修正 (ステップ一覧 / 全体図 / Step 4 詳細追加 / 番号シフト 5→6, 6→7, 7→8, 8→9, 9→10 / Step 5↔6 ループ → 6↔7 / コミット規約 / 並列起動ガイド / ロールバック早見表)

- [ ] **T4** — specialist-planner / implementer / validator の入出力契約変更
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: 3 ファイル修正 (入出力欄 + Step 番号リナンバー + planner はテスト方針削除 / implementer はカバレッジ追記責任 / validator はカバレッジ検証責任)

- [ ] **T5** — 機械的番号シフト (specialist-self-reviewer / reviewer / retrospective-writer + agents 6 件)
  - status: pending
  - dependencies: T3
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: 9 ファイル機械置換 (gsed 逆順 9→10 から実行)

- [ ] **T6** — shared-artifacts/SKILL.md + progress.yaml + task-plan の template/reference 更新
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: 5 ファイル修正 (成果物テーブルに qa-design/qa-flow / artifacts に qa_design/qa_flow / task-plan の test_strategy 削除 + TC-ID 任意追加)

- [ ] **T7** — その他 templates の Step 番号シフト + README 更新
  - status: pending
  - dependencies: T3
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: 4 ファイル (TODO/self-review-report/retrospective テンプレートの番号シフト + README.md の 9→10 ステップ反映)

- [ ] **T8** — 最終 grep verification
  - status: pending
  - dependencies: T1, T2, T3, T4, T5, T6, T7
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: Intent Spec 14 成功基準を機械的に検証、不一致あれば該当タスクに差し戻し

## 状態遷移ガイド

- `pending`: 未着手。`[ ]` 表示
- `in_progress`: `implementer` 起動中。`[ ]` 表示、`started_at` と `implementer` を記録
- `completed`: 完了。`[x]` 表示、`completed_at` と `commit` SHA を記録
- Self-Review High 指摘で戻す場合: `completed` → `in_progress` に戻し、`re_activations` をインクリメント

## コミット規約

- 各タスク状態変化ごとに 1 コミット (頻繁)
- コミットメッセージ例:
  - `docs(dev-workflow/2026-04-26-add-qa-design-step): start task T1`
  - `docs(dev-workflow/2026-04-26-add-qa-design-step): complete task T1`
  - `docs(dev-workflow/2026-04-26-add-qa-design-step): re-activate task T1 (self-review feedback)`
