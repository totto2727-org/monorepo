# Task List: 2026-05-03-pr-ci-integration

- **Source:** `task-plan.md`
- **Active Steps:** Step 6〜7 (Implementation / External Review)
- **Created at:** 2026-05-03T05:10:00Z
- **Last updated:** 2026-05-03T05:10:00Z

このファイルは**永続化されたタスク状態**。Main 内部の `TaskCreate` タスクリストと同期するが、**こちらが真のソース**。状態変化時は TODO.md 更新 → コミット → TaskUpdate の順で実行する。

## 後発追加タスク（`task-plan.md` 以降に発生したもの）

`task-plan.md` 不変運用の原則に従い、Step 6〜7 中に発見された追加タスクはここに記録する。追加理由を明記すること。

- なし（デフォルト）

## タスク

- [x] **T1** — dev-workflow/SKILL.md に新セクション「## サイクル PR と CI 連携プロトコル」を追加
  - status: completed
  - dependencies: なし (Wave 1 起点)
  - started_at: 2026-05-03T05:15:00Z
  - completed_at: 2026-05-03T05:30:00Z
  - commit: 45dff2bd044e1e38d076b92c7bded167b9986f9e
  - implementer: implementer-T1
  - re_activations: 0
  - notes: design.md の「コンポーネント構成 § A」「主要な型・インターフェース § シェル擬似コード」「PR description テンプレート」を SKILL.md L767 直後にコピーペースト。約 110 行。Wave 1 で T4 / T5 と並列起動可。

- [ ] **T2** — dev-workflow/SKILL.md の各 Step Exit Criteria に CI PASS 条件を追記
  - status: pending
  - dependencies: T1 (同一ファイル編集のため Wave 跨ぎで直列化)
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: Step 1〜9 の Exit Criteria 末尾に統一文言で 1 行追加 (9 箇所)。Step 6 のみ「全タスク単位コミット」に微修正。Wave 2 で単独実行。実装前に動的行番号取得必須 (T1 でファイルが伸びているため)。

- [ ] **T3** — dev-workflow/SKILL.md コミット規約セクション末尾に PR-CI プロトコルへの参照リンクを追加
  - status: pending
  - dependencies: T1, T2 (同一ファイル編集のため Wave 跨ぎで直列化)
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: 「コミット規約」末尾 (T1 が追加した新セクション直前) に「PR 概要更新および CI 確認の運用は『## サイクル PR と CI 連携プロトコル』を参照」1 行追加。Wave 3 で単独実行。

- [x] **T4** — specialist-common/SKILL.md §7 に PR 操作 = Main 専属の 1 行を追記
  - status: completed
  - dependencies: なし (T1 と並列可)
  - started_at: 2026-05-03T05:15:00Z
  - completed_at: 2026-05-03T05:25:00Z
  - commit: bc1a84d6f93bbb7573b257f8999f7cf3c3149068
  - implementer: implementer-T4
  - re_activations: 0
  - notes: §7「Git コミットに関する注意」(L177-L194) リスト末尾 (L184 直後) に 1 行追加。Wave 1 で T1 / T5 と並列起動可。

- [x] **T5** — progress-yaml.md `### blockers` セクションに CI failure 記録例を追記
  - status: completed
  - dependencies: なし (T1 と並列可)
  - started_at: 2026-05-03T05:15:00Z
  - completed_at: 2026-05-03T05:25:00Z
  - commit: 8a2aff6
  - implementer: implementer-T5
  - re_activations: 0
  - notes: `### blockers` セクション (L57-L60) 末尾に CI 失敗を自由テキスト形式で記録する例を 1〜2 行追記。schema 拡張なし。Wave 1 で T1 / T4 と並列起動可。

## 状態遷移ガイド

- `pending`: 未着手。`[ ]` 表示
- `in_progress`: `implementer` 起動中。`[ ]` 表示、`started_at` と `implementer` を記録
- `completed`: 完了。`[x]` 表示、`completed_at` と `commit` SHA を記録
- External Review Blocker 指摘で戻す場合: `completed` → `in_progress` に戻し、`re_activations` をインクリメント

## Wave 構成

- **Wave 1 (3 並列)**: T1 + T4 + T5
- **Wave 2 (単独)**: T2 (T1 完了後)
- **Wave 3 (単独)**: T3 (T1, T2 完了後)

## コミット規約

- 各タスク状態変化ごとに 1 コミット（頻繁）
- コミットメッセージ例:
  - `docs(dev-workflow/2026-05-03-pr-ci-integration): start task T1`
  - `feat(dev-workflow/2026-05-03-pr-ci-integration/task-T1): add cycle PR-CI protocol section to dev-workflow/SKILL.md`
  - `docs(dev-workflow/2026-05-03-pr-ci-integration): re-activate task T1 (external-review feedback)`
