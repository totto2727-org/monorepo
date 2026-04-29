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

- [ ] **T2** — A-5 specialist-reviewer に holistic 小節を新設
  - status: pending
  - dependencies: []
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes: 「観点別のレビュー指針」セクション末尾

- [ ] **T3** — A-8 + C-3 specialist-retrospective-writer 修正
  - status: pending
  - dependencies: []
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes: 再活性化 SHA 列挙手順 + パス更新

- [ ] **T4** — ADR 新規作成 (A-4 保留記録)
  - status: pending
  - dependencies: []
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes: docs/adr/2026-04-29-researcher-project-skill-inventory-deferral.md

- [ ] **T5** — C 構造変更 (新規 + 削除 3 件 + パス更新 + 削除ポリシー)
  - status: pending
  - dependencies: []
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes: 過去 3 retrospective 削除 + 4 ファイルでパス更新 + 削除ポリシー追記

### Wave 2 (Wave 1 完了後、1 タスク)

- [ ] **T6** — Step 8 Validation 一括検証
  - status: pending
  - dependencies: [T1, T2, T3, T4, T5]
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes: TC-001..TC-020 のうち TC-012 は Step 9 完了後

## 状態遷移ガイド

- `pending`: 未着手。`[ ]` 表示
- `in_progress`: 実装中。`[ ]` 表示、`started_at` と implementer 記録
- `completed`: 完了。`[x]` 表示、`completed_at` と `commit` SHA を記録
- External Review Blocker 指摘で戻す場合: `completed` → `in_progress` に戻し `re_activations` インクリメント
