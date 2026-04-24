# Task List: 2026-04-24-ai-dlc-plugin-bootstrap

- **Source:** `task-plan.md`
- **Phase:** Construction
- **Created at:** 2026-04-24T14:20:00Z
- **Last updated:** 2026-04-24T16:45:00Z

本 TODO は Construction フェーズを逆算的に再構築したもの。実際の実装は Main が直接行ったため、`implementer` インスタンス ID は仮想的な識別子を付与している。

## 後発追加タスク（`task-plan.md` 以降に発生したもの）

- **T13' (T13 の派生)**: `design.md` の名称をめぐる議論で「ADR と Design Document の使い分け」セクションを shared-artifacts/references/design.md に追加。T13 完了後に発生、T13 の範疇として処理した
- **T14' (T14 の派生)**: Clean-Transition Between Steps 原則を基本方針に新規追加。T14 の一部として処理
- **T15 (M-1 修正)**: Self-Review Medium 指摘 #1（パス表記統一）を受けて追加
- **T16 (M-2 修正)**: Self-Review Medium 指摘 #2（TODO.md スキーマ重複除去）を受けて追加
- **T17 (M-3 修正)**: Self-Review Medium 指摘 #3（main-workflow 委譲理由の説明追加）を受けて追加
- **T18 (M-4 修正)**: Self-Review Medium 指摘 #4（task-plan.md 不変運用の統一）を受けて追加
- 上記は Step 6 Self-Review からの Medium 指摘対応。High 0 件のため Step 5 の再活性化ではなく、Construction Step 5 の追加作業として処理

## タスク

- [x] **T1** — プラグイン骨格を作成
  - status: completed
  - dependencies: なし
  - started_at: 2026-04-24T14:20:00Z
  - completed_at: 2026-04-24T14:22:00Z
  - commit: 2b34716
  - implementer: main-direct
  - re_activations: 0
  - notes: plugin.json 作成のみ

- [x] **T2** — main-workflow スキルを作成
  - status: completed
  - dependencies: T1
  - started_at: 2026-04-24T14:22:00Z
  - completed_at: 2026-04-24T14:45:00Z
  - commit: 2b34716
  - implementer: main-direct
  - re_activations: 2
  - notes: "3 層 → 2 層への変更、Artifact-as-Gate-Review 導入で 2 回書き直し"

- [x] **T3** — main-inception スキルを作成
  - status: completed
  - dependencies: T1
  - started_at: 2026-04-24T14:30:00Z
  - completed_at: 2026-04-24T14:50:00Z
  - commit: 2b34716
  - implementer: main-direct
  - re_activations: 1
  - notes: "ADR → Design Document への変更時に修正"

- [x] **T4** — main-construction スキルを作成
  - status: completed
  - dependencies: T1
  - started_at: 2026-04-24T14:35:00Z
  - completed_at: 2026-04-24T14:55:00Z
  - commit: 2b34716
  - implementer: main-direct
  - re_activations: 2
  - notes: "TaskCreate と TODO.md 同期ルールは後から追加された"

- [x] **T5** — main-verification スキルを作成
  - status: completed
  - dependencies: T1
  - started_at: 2026-04-24T14:40:00Z
  - completed_at: 2026-04-24T14:58:00Z
  - commit: 2b34716
  - implementer: main-direct
  - re_activations: 1
  - notes: "最終完了レポートの扱いを Artifact-as-Gate-Review に寄せた"

- [x] **T6** — specialist-common スキルを作成
  - status: completed
  - dependencies: T1
  - started_at: 2026-04-24T15:00:00Z
  - completed_at: 2026-04-24T15:15:00Z
  - commit: b386eeb
  - implementer: main-direct
  - re_activations: 0
  - notes: "ユーザーから「共通項は独立スキルに」との指示を受けて新規追加"

- [x] **T7** — specialist-* 9 スキルを作成
  - status: completed
  - dependencies: T6
  - started_at: 2026-04-24T15:15:00Z
  - completed_at: 2026-04-24T15:35:00Z
  - commit: b386eeb
  - implementer: main-direct
  - re_activations: 0
  - notes: "9 ファイルまとめて作成。各々が specialist-common を継承する構造"

- [x] **T8** — agents/*.md を作成
  - status: completed
  - dependencies: T7
  - started_at: 2026-04-24T15:35:00Z
  - completed_at: 2026-04-24T15:45:00Z
  - commit: b386eeb
  - implementer: main-direct
  - re_activations: 0
  - notes: "各エージェントは specialist-common + specialist-<role> を参照する軽量エントリポイント"

- [x] **T9** — shared-artifacts スキル骨格と SKILL.md（目次）を作成
  - status: completed
  - dependencies: T1
  - started_at: 2026-04-24T15:50:00Z
  - completed_at: 2026-04-24T15:55:00Z
  - commit: b386eeb
  - implementer: main-direct
  - re_activations: 0
  - notes: "成果物一覧テーブルを目次として実装"

- [x] **T10** — テンプレート 11 件を作成/移管
  - status: completed
  - dependencies: T9
  - started_at: 2026-04-24T15:55:00Z
  - completed_at: 2026-04-24T16:00:00Z
  - commit: b386eeb
  - implementer: main-direct
  - re_activations: 0
  - notes: "git mv で既存テンプレートを移管、履歴保全"

- [x] **T11** — references 11 件を作成
  - status: completed
  - dependencies: T10
  - started_at: 2026-04-24T16:00:00Z
  - completed_at: 2026-04-24T16:10:00Z
  - commit: b386eeb
  - implementer: main-direct
  - re_activations: 0
  - notes: "11 ファイル、良例/悪例を含む書き方ガイド"

- [x] **T12** — 成果物保存構造を shared-artifacts に統合
  - status: completed
  - dependencies: T9, T11
  - started_at: 2026-04-24T16:10:00Z
  - completed_at: 2026-04-24T16:15:00Z
  - commit: b386eeb
  - implementer: main-direct
  - re_activations: 1
  - notes: "main-workflow からのセクション削除時に sed 操作のプラットフォーム差（BSD/GNU）で 1 回やり直し"

- [x] **T13** — 相互参照を shared-artifacts に統一
  - status: completed
  - dependencies: T10, T11
  - started_at: 2026-04-24T16:15:00Z
  - completed_at: 2026-04-24T16:18:00Z
  - commit: b386eeb
  - implementer: main-direct
  - re_activations: 0
  - notes: "grep で旧パス残存を確認、0 件"

- [x] **T14** — ステップ完了コミット規約を追記
  - status: completed
  - dependencies: T13
  - started_at: 2026-04-24T16:18:00Z
  - completed_at: 2026-04-24T16:20:00Z
  - commit: b386eeb
  - implementer: main-direct
  - re_activations: 0
  - notes: "main-workflow に新セクション追加、各 Exit Criteria に commit 要件を追記"

- [x] **T15** — Fix M-1: shared-artifacts SKILL.md のパス表記を shared-artifacts/ プレフィックス付きに統一
  - status: completed
  - dependencies: T14 + Step 6 Self-Review の Medium 指摘 #1
  - started_at: 2026-04-24T16:35:00Z
  - completed_at: 2026-04-24T16:37:00Z
  - commit: 4e9aa46
  - implementer: main-direct
  - re_activations: 0
  - notes: "パス表記ルールの明示文も冒頭に追加"

- [x] **T16** — Fix M-2: main-construction から TODO.md スキーマの重複を除去
  - status: completed
  - dependencies: T14 + Step 6 Self-Review の Medium 指摘 #2
  - started_at: 2026-04-24T16:37:00Z
  - completed_at: 2026-04-24T16:40:00Z
  - commit: 7ea87c1
  - implementer: main-direct
  - re_activations: 0
  - notes: "運用フローのみ残し、スキーマ詳細は shared-artifacts/references/todo.md 参照に置換"

- [x] **T17** — Fix M-3: main-workflow 委譲セクションに集約理由を追記
  - status: completed
  - dependencies: T14 + Step 6 Self-Review の Medium 指摘 #3
  - started_at: 2026-04-24T16:40:00Z
  - completed_at: 2026-04-24T16:42:00Z
  - commit: 06492ce
  - implementer: main-direct
  - re_activations: 0
  - notes: "1 段落で 1:1 対応と真のソース集約の意図を明示"

- [x] **T18** — Fix M-4: task-plan.md 不変運用の文言統一
  - status: completed
  - dependencies: T14 + Step 6 Self-Review の Medium 指摘 #4
  - started_at: 2026-04-24T16:42:00Z
  - completed_at: 2026-04-24T16:45:00Z
  - commit: b1a45d3
  - implementer: main-direct
  - re_activations: 0
  - notes: "「task-plan.md 冒頭に差分理由を記録」との矛盾表現を references/task-plan.md から除去、main-construction 側も統一"

## 状態遷移ガイド

- `pending`: 未着手。`[ ]` 表示
- `in_progress`: `implementer` 起動中。`[ ]` 表示、`started_at` と `implementer` を記録
- `completed`: 完了。`[x]` 表示、`completed_at` と `commit` SHA を記録
- Self-Review High 指摘で戻す場合: `completed` → `in_progress` に戻し、`re_activations` をインクリメント

## コミット規約

- 各タスク状態変化ごとに 1 コミット（本サイクルは逆算再構築なので、実際は 2 つの大きなコミット `2b34716`, `b386eeb` に全タスクが集約された）
- 本来は task-plan の Wave 単位でコミットすべきだが、会話駆動の逆算実装のため履歴が粗い
