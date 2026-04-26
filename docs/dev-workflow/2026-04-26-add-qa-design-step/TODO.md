# Task List: 2026-04-26-add-qa-design-step

- **Source:** `task-plan.md`
- **Active Steps:** Step 5〜6 (Implementation / Self-Review)
- **Created at:** 2026-04-26T16:00:00Z
- **Last updated:** 2026-04-26T16:30:00Z

このファイルは**永続化されたタスク状態**。Main 内部の `TaskCreate` タスクリストと同期するが、**こちらが真のソース**。状態変化時は TODO.md 更新 → コミット → TaskUpdate の順で実行する。

## 後発追加タスク (`task-plan.md` 以降に発生したもの)

`task-plan.md` 不変運用の原則に従い、Step 5〜6 中に発見された追加タスクはここに記録する。追加理由を明記すること。

- なし (デフォルト)

## タスク

- [x] **T1** — shared-artifacts に qa-design / qa-flow の reference + template を追加
  - status: completed
  - dependencies: なし (Wave 1 起点)
  - started_at: 2026-04-26T16:05:00Z
  - completed_at: 2026-04-26T16:30:00Z
  - commit: (this commit)
  - implementer: Main (兼任)
  - re_activations: 0
  - notes: 4 ファイル新規完成 (references/qa-design.md 列定義+2軸enum+業界taxonomy対応、references/qa-flow.md 分割指針+skip規約、templates/qa-design.md プレースホルダ表+enum早見表、templates/qa-flow.md 関心領域+横断+実装都合分岐セクション)

- [x] **T2** — specialist-qa-analyst skill + agent を新規作成
  - status: completed
  - dependencies: T1
  - started_at: 2026-04-26T17:00:00Z
  - completed_at: 2026-04-26T17:15:00Z
  - commit: (this commit)
  - implementer: Main (兼任)
  - re_activations: 0
  - notes: 2 ファイル新規完成 (specialist-qa-analyst/SKILL.md: 役割/2軸選定ガイド/業界taxonomy対応/失敗モード/スコープ外、agents/qa-analyst.md: description+参照スキル+Main要求)

- [x] **T3** — dev-workflow/SKILL.md の大規模更新
  - status: completed
  - dependencies: なし (Wave 1 起点、T1 と並列可)
  - started_at: 2026-04-26T16:30:00Z
  - completed_at: 2026-04-26T17:00:00Z
  - commit: (this commit)
  - implementer: Main (兼任)
  - re_activations: 0
  - notes: gsed 逆順番号シフト (placeholder で複合表現保護) + Step 4 QA Design 詳細セクション新規追加 + ステップ一覧 10 行化 + ASCII 図 10 ノード化 + コミット規約/並列起動/ロールバック早見表に Step 4 関連追加 + 9→10 ステップ表記更新

- [x] **T4** — specialist-planner / implementer / validator の入出力契約変更
  - status: completed
  - dependencies: T1
  - started_at: 2026-04-26T17:15:00Z
  - completed_at: 2026-04-26T17:45:00Z
  - commit: (this commit)
  - implementer: Main (兼任)
  - re_activations: 0
  - notes: 3 ファイル修正完了 (gsed で Step 番号リナンバー + Edit で I/O 変更)。planner: テスト方針削除/qa-design 任意参照/qa-analyst 領域明記、implementer: qa-design+qa-flow 入力/TC-NNN+TC-IMPL 追記責任/判断フロー、validator: qa-design+qa-flow 入力/カバレッジ実測手順/qa-flow 葉カバレッジ検証

- [x] **T5** — 機械的番号シフト (specialist-self-reviewer / reviewer / retrospective-writer + agents 6 件)
  - status: completed
  - dependencies: T3
  - started_at: 2026-04-26T18:15:00Z
  - completed_at: 2026-04-26T18:30:00Z
  - commit: (this commit)
  - implementer: Main (兼任)
  - re_activations: 0
  - notes: 9 ファイル機械置換完了 (gsed 逆順 + placeholder で複合表現保護)。残存 references の追加 gsed も実施 (design.md / retrospective.md / todo.md / self-review-report.md / その他、計 13 ファイル)

- [x] **T6** — shared-artifacts/SKILL.md + progress.yaml + task-plan の template/reference 更新
  - status: completed
  - dependencies: T1
  - started_at: 2026-04-26T17:45:00Z
  - completed_at: 2026-04-26T18:15:00Z
  - commit: (this commit)
  - implementer: Main (兼任)
  - re_activations: 0
  - notes: 5 ファイル修正完了 (gsed 番号シフト + qa-design/qa-flow 追加 + 重複 dev-workflow 整理 + Step 6〜6 → 6〜7 修正)。task-plan の test_strategy → covered_test_cases 任意化、progress.yaml の artifacts に qa_design/qa_flow フィールド追加

- [x] **T7** — その他 templates の Step 番号シフト + README 更新
  - status: completed
  - dependencies: T3
  - started_at: 2026-04-26T18:15:00Z
  - completed_at: 2026-04-26T18:30:00Z
  - commit: (this commit)
  - implementer: Main (兼任)
  - re_activations: 0
  - notes: T5 と同一コミット内で処理 (templates/TODO.md, templates/self-review-report.md, templates/retrospective.md は gsed バッチに含めた)。README.md は 10 specialist + 10-step lifecycle に更新

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
