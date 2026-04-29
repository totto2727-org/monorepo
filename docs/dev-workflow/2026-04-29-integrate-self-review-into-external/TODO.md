# Task List: 2026-04-29-integrate-self-review-into-external

- **Source:** `task-plan.md`
- **Active Steps:** Step 6〜7 (Implementation / External Review)
- **Created at:** 2026-04-29T05:00:00Z
- **Last updated:** 2026-04-29T05:00:00Z

このファイルは**永続化されたタスク状態**。Main 内部の `TaskCreate` タスクリストと同期するが、**こちらが真のソース**。状態変化時は TODO.md 更新 → コミット → TaskUpdate の順で実行する。

## 後発追加タスク（`task-plan.md` 以降に発生したもの）

`task-plan.md` 不変運用の原則に従い、Step 6〜7 中に発見された追加タスクはここに記録する。追加理由を明記すること。

- なし（デフォルト）

## タスク

### Wave 1 — 削除タスク（並列可）

- [x] **T1a** — `specialist-self-reviewer/` ディレクトリの削除
  - status: completed
  - dependencies: []
  - started_at: 2026-04-29T05:10:00Z
  - completed_at: 2026-04-29T05:10:30Z
  - commit: ed9629c
  - implementer: main
  - re_activations: 0
  - notes: Wave 1 起点。grep ヒット約 38% を即時消滅

- [x] **T1b** — `agents/self-reviewer.md` の削除
  - status: completed
  - dependencies: []
  - started_at: 2026-04-29T05:11:00Z
  - completed_at: 2026-04-29T05:11:30Z
  - commit: 89a09e7
  - implementer: main
  - re_activations: 0
  - notes: agents/ 配下を 9 ファイル構成に

- [x] **T1c** — `shared-artifacts/templates/self-review-report.md` の削除
  - status: completed
  - dependencies: []
  - started_at: 2026-04-29T05:12:00Z
  - completed_at: 2026-04-29T05:12:30Z
  - commit: 5e8a8ed
  - implementer: main
  - re_activations: 0
  - notes:

- [x] **T1d** — `shared-artifacts/references/self-review-report.md` の削除
  - status: completed
  - dependencies: []
  - started_at: 2026-04-29T05:13:00Z
  - completed_at: 2026-04-29T05:13:30Z
  - commit: (本commit)
  - implementer: main
  - re_activations: 0
  - notes: 削除前に運用知見が design.md と T3b/T4 で吸収済みであることが前提

### Wave 2 — ステップ番号機械置換（直列）

- [ ] **T2** — ステップ番号機械置換 (placeholder + gsed 降順)
  - status: pending
  - dependencies: [T1a, T1b, T1c, T1d]
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes: `__SRK_*__` placeholder 命名。降順 (Step 10→9→8→7) で連鎖二重置換回避。事前 `ggrep -rn -F '__SRK_'` で 0 件確認

### Wave 3 — 観点統合 / Edit ハイブリッド

- [ ] **T3a** — `dev-workflow/SKILL.md` ステップ表系の 9-step 化
  - status: pending
  - dependencies: [T2]
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes: ステップ一覧テーブル / フロー ASCII / 並列度ガイドライン表

- [ ] **T3b** — `dev-workflow/SKILL.md` Step 7 Self-Review セクションの物理削除と新 Step 7 統合
  - status: pending
  - dependencies: [T3a]
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes: 同一ファイルのため T3a→T3b→T3c→T3d は直列。新 Step 7 に holistic 観点と「全体整合性」記述を統合

- [ ] **T3c** — `dev-workflow/SKILL.md` ロールバック早見表の 9-step 化
  - status: pending
  - dependencies: [T3b]
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes:

- [ ] **T3d** — `dev-workflow/SKILL.md` その他 Self-Review 言及の文脈書き換え
  - status: pending
  - dependencies: [T3c]
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes:

- [ ] **T4** — `specialist-reviewer/SKILL.md` の責務拡張 (holistic 観点 / Self-Review 言及削除 / 全体整合性追記)
  - status: pending
  - dependencies: [T2]
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes: T3 系と並列可。description 250 文字制約に注意

- [ ] **T5** — 他 specialist スキル / agents の Self-Review 言及削除 + Step 番号整合性確認
  - status: pending
  - dependencies: [T2]
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes: T3/T4 と並列可。複数ファイルを 1 commit にまとめる

- [ ] **T6** — `shared-artifacts/SKILL.md` 成果物一覧 + 保存構造 ASCII の連番再付番
  - status: pending
  - dependencies: [T1c, T1d, T2]
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes: T3/T4/T5 と並列可

- [ ] **T7** — `progress.yaml` / `TODO.md` / `retrospective.md` template と reference の刷新
  - status: pending
  - dependencies: [T2]
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes: B-3/B-4 リスク。`self_review:` 削除と TODO.md 文言刷新を 1 Edit にまとめる。`references/*.md` を全件 grep 確認

- [ ] **T8** — README + plugin.json の 9-step 化
  - status: pending
  - dependencies: [T2]
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes: T3/T4/T5/T6/T7 と並列可

### Wave 4 — 機械検証

- [ ] **T9** — 機械検証 (TC-001 〜 TC-018 のうち事前実行可能な分)
  - status: pending
  - dependencies: [T1a, T1b, T1c, T1d, T2, T3a, T3b, T3c, T3d, T4, T5, T6, T7, T8]
  - started_at:
  - completed_at:
  - commit:
  - implementer:
  - re_activations: 0
  - notes: 委譲チェックリスト (holistic 単一ソース / 3 周ルール書き分け) を grep で機械確認

## 状態遷移ガイド

- `pending`: 未着手。`[ ]` 表示
- `in_progress`: `implementer` 起動中。`[ ]` 表示、`started_at` と `implementer` を記録
- `completed`: 完了。`[x]` 表示、`completed_at` と `commit` SHA を記録
- External Review High/Blocker 指摘で戻す場合: `completed` → `in_progress` に戻し、`re_activations` をインクリメント

## コミット規約

- 各タスク完了ごとに 1 コミット
- 状態変化のメタコミットは progress.yaml と一括にする方針 (キー重複防止のため)
- コミットメッセージ例:
  - `feat(dev-workflow): <task summary>` (実装本体)
  - `docs(dev-workflow/<identifier>): re-activate task Tx (external-review feedback)`
