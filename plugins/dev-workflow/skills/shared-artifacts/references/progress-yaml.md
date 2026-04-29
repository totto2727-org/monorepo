# Reference: `progress.yaml` の書き方

## 目的

サイクル全体の**進捗を機械可読な形で永続化**する。Main が唯一の書き手となる真のソース。中断・再開時はこのファイルを読むだけで状態を復元できる。

## 作成者 / 更新タイミング

- **作成者:** Main
- **初期化:** サイクル開始時（Step 1 に着手する直前）
- **更新:** 各ステップ完了時 / ユーザー承認時 / Blocker 発生時 / ロールバック時 / セッション再開時

## ファイル位置

`docs/dev-workflow/<identifier>/progress.yaml`

## 各フィールドの書き方

### `identifier` / `started_at` / `updated_at`

- `identifier`: サイクル開始時にユーザーと合意した識別子（機能名 / チケット ID 等）
- `started_at`: サイクル開始の ISO8601 タイムスタンプ（固定、以降変更しない）
- `updated_at`: YAML を更新するたびに最新の ISO8601 に書き換え

### `status` / `current_step`

- `status`: `active` / `completed` / `blocked` のいずれか (サイクル全体の状態。フェーズ概念は持たない)
- `current_step`: 「Step 3: Design」のようにステップ番号と名称を併記

### `completed_steps`

完了したステップを時系列で記録。

```yaml
completed_steps:
  - step: 'Step 1: Intent Clarification'
    completed_at: 2026-04-24T10:00:00Z
    artifact: intent-spec.md
```

### `pending_gates`

ユーザー承認・Main 判定待ちの項目を列挙。ゲートが解消されたら削除してリストから除外。

### `active_specialists`

**現在走っている Specialist のみ**を記録。完了したら `completed_steps` 側に吸収され、このリストから削除される。

```yaml
active_specialists:
  - name: researcher
    task: existing-impl 観点の調査
    status: running
    started_at: 2026-04-24T10:30:00Z
```

### `blockers`

未解決の Blocker。解消されたら削除。文言は「事象 + 影響 + 対応方針」を含める。

### `artifacts`

全成果物の相対パス。`null` のまま未生成のフィールドを残してよい。複数作成される成果物（research, review）はリスト形式。

フィールド一覧:

- `intent_spec` (Step 1) — `intent-spec.md`
- `research` (Step 2) — リスト
- `design` (Step 3) — `design.md`
- `qa_design` (Step 4) — `qa-design.md`
- `qa_flow` (Step 4) — `qa-flow.md`
- `external_adrs` — サイクル外に起票したプロジェクト横断 ADR (リスト)
- `task_plan` (Step 5) — `task-plan.md`
- `todo` (Step 6 開始時に生成) — `TODO.md`
- `self_review` (Step 7) — `self-review-report.md`
- `review` (Step 7) — リスト
- `validation` (Step 8) — `validation-report.md`
- `retrospective` (Step 9) — `retrospective.md`

### `user_approvals`

ユーザー承認の履歴。承認 / 却下の区別を `notes` に書く。

### `rollbacks`

ステップ間ロールバックの履歴。原因と移動先を明示。

## 品質基準

| ✅ よい                              | ❌ 悪い                                    |
| ------------------------------------ | ------------------------------------------ |
| 各イベントを発生時に即反映           | 後からまとめて書こうとして漏れる           |
| タイムスタンプに UTC + ISO8601 使用  | ローカル時刻・自然言語表記                 |
| Blocker が具体的（事象・影響・方針） | 「問題が発生」のような抽象的記述           |
| 活性 Specialist が現実と一致         | running 状態が放置されセッション跨ぎで残る |

## 関連成果物

- このファイルは**全成果物への索引**。`artifacts` フィールドが成果物ディレクトリの目次として機能する
- `TODO.md` と連携（Step 6〜7 中のタスク状態は TODO.md が真のソース、YAML 側はサイクルレベルのサマリ）
