# Task List: 2026-04-29-retro-cleanup

- **Source:** `task-plan.md`
- **Active Steps:** Step 6〜7 (Implementation / External Review)
- **Created at:** 2026-04-29T13:50:00Z
- **Last updated:** 2026-04-29T13:50:00Z

## 後発追加タスク

- なし (デフォルト)

## タスク

### Wave 1 (並列、5 タスク)

- [x] **T1** — A-2 dev-workflow/SKILL.md に 3-5 案推奨を追記
  - status: completed
  - dependencies: []
  - started_at: 2026-04-29T14:05:00Z
  - completed_at: 2026-04-29T14:05:30Z
  - commit: (本commit)
  - implementer: main
  - re_activations: 0
  - notes: Report-Based Confirmation セクション L52 直後に 1 行追加

- [x] **T2** — A-5 specialist-reviewer に holistic 小節を新設
  - status: completed
  - dependencies: []
  - started_at: 2026-04-29T14:10:00Z
  - completed_at: 2026-04-29T14:10:30Z
  - commit: (本commit)
  - implementer: main
  - re_activations: 0
  - notes: 既存 5 観点と同階層 `### holistic` (3 hash) で追加。qa-design TC-002 の grep パターンも `^### holistic` に修正

- [x] **T3** — A-8 + C-3 specialist-retrospective-writer 修正
  - status: completed
  - dependencies: []
  - started_at: 2026-04-29T14:15:00Z
  - completed_at: 2026-04-29T14:15:30Z
  - commit: (本commit)
  - implementer: main
  - re_activations: 0
  - notes: 成果物パス → docs/retrospective/<id>.md、ライフサイクル行追加、データ分析に再活性化 SHA 列挙項目追加

- [x] **T4** — ADR 新規作成 (A-4 保留記録)
  - status: completed
  - dependencies: []
  - started_at: 2026-04-29T14:20:00Z
  - completed_at: 2026-04-29T14:20:30Z
  - commit: (本commit)
  - implementer: main
  - re_activations: 0
  - notes: docs/adr/2026-04-29-researcher-project-skill-inventory-deferral.md 作成。confirmed: false、Decision/Impact/再検討トリガー/関連サイクル の 4 セクション

- [x] **T5** — C 構造変更 (新規 + 削除 3 件 + パス更新 + 削除ポリシー)
  - status: completed
  - dependencies: []
  - started_at: 2026-04-29T14:25:00Z
  - completed_at: 2026-04-29T14:30:00Z
  - commit: (本commit)
  - implementer: main
  - re_activations: 0
  - notes: |
    過去 3 retrospective を git rm。dev-workflow/SKILL.md (Step 9 セクション
    - Step 一覧テーブル + コミット規約表)、shared-artifacts/SKILL.md (成果物
      一覧テーブル + 保存構造 ASCII + サイクル外成果物セクション)、references/
      retrospective.md (ファイル位置 + ライフサイクル)、agents/retrospective-
      writer.md (概要パス) の 4 ファイルでパス更新 + 削除ポリシー追記。docs/
      retrospective/ ディレクトリは Step 9 (本サイクル retrospective 作成時)
      に自動生成

### Wave 2 (Wave 1 完了後、1 タスク)

- [x] **T6** — Step 8 Validation 一括検証
  - status: completed
  - dependencies: [T1, T2, T3, T4, T5]
  - started_at: 2026-04-29T14:35:00Z
  - completed_at: 2026-04-29T14:40:00Z
  - commit: (本commit)
  - implementer: main
  - re_activations: 0
  - notes: |
    Step 7 holistic レビュー (Blocker/Major/Minor 0 件、approved) →
    Step 8 Validation 19 PASS / 1 保留 (TC-011 docs/retrospective/ ディレクトリ
    は Step 9 で自動生成、TC-012 は Step 9 完了後最終確認)。
    実質全 SC PASS、サイクル completed 直前まで進行

## 状態遷移ガイド

- `pending`: 未着手。`[ ]` 表示
- `in_progress`: 実装中。`[ ]` 表示、`started_at` と implementer 記録
- `completed`: 完了。`[x]` 表示、`completed_at` と `commit` SHA を記録
- External Review Blocker 指摘で戻す場合: `completed` → `in_progress` に戻し `re_activations` インクリメント
