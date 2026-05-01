# Milestone: {{milestone_title}}

- **Milestone ID:** {{milestone_id}}
- **Roadmap ID:** {{roadmap_id}}
- **Status:** {{status}} <!-- planned | active | completed | blocked | cancelled (`roadmap-progress.yaml.milestones[].status` と一致させる) -->
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}

このドキュメントは `dev-roadmap` の **Step 2 (Milestone Decomposition)** で `roadmap-planner` Specialist が起草する**1 マイルストーンの定義書**。1 ファイル = 1 マイルストーンを原則とし、`docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md` に配置する。書き方の詳細は `shared-artifacts/references/milestone.md` を参照。

## 目的

{{purpose}}

このマイルストーンが達成したい状態を 1〜2 文で記述する。**定性的な到達点**でよい (観測可能な成功基準は配下の `dev-workflow` サイクルの Intent Spec が持つ責務)。例: 「OAuth クライアント登録機能が動作している」「決済 API のうち先頭 1/3 のエンドポイントが新基盤で稼働している」。

## 到達点 (定性)

{{outcomes}}

完了判定の根拠となる**定性的な観測ポイント**を箇条書きで示す。配下の `dev-workflow` サイクルが完了し、`roadmap-progress.yaml.milestones[<this>].status` が `completed` に遷移する条件として、人間が目視で「達成された」と合意できる粒度で書く。

- {{outcome_1}}
- {{outcome_2}}
- {{outcome_3}}

## スコープ

{{scope}}

このマイルストーンで扱う領域を具体的に記述する。配下の `dev-workflow` サイクルが**最大でどこまで触ってよいか**の境界。

- 対象モジュール / コンポーネント / ファイル群
- 対象ユーザー / システム境界
- 対象機能・領域

## 非スコープ

{{out_of_scope}}

意図的に扱わない領域 (他マイルストーンの責務 / 後続マイルストーンに送る / 別ロードマップで扱う 等)。

- {{out_of_scope_1}}
- {{out_of_scope_2}}

## 依存マイルストーン

{{depends_on}}

このマイルストーンが**先行完了を要求する**他のマイルストーン ID を列挙する。`roadmap-progress.yaml.milestones[].depends_on[]` と完全一致させる。起点マイルストーン (依存なし) の場合は明示的に `(なし)` と書く。

- {{milestone_dependency_1_id}}: {{milestone_dependency_1_reason}}
- {{milestone_dependency_2_id}}: {{milestone_dependency_2_reason}}

## 関連 dev-workflow サイクル (workflow_identifiers)

{{workflow_identifiers}}

このマイルストーンに紐付く `dev-workflow` サイクルの `<identifier>` 一覧。1:1 が推奨だが 1:N も許容する (Intent Spec で確定済み)。

- 起票時 (Step 2): 空 `[]` または将来予定の `<identifier>` を仮置き
- 配下サイクル開始時: 各 `dev-workflow` サイクルが `progress.yaml.roadmap` ブロックを初期化するタイミングで、自身の `<identifier>` を `roadmap-progress.yaml.milestones[].workflow_identifiers[]` に追記する (本ファイルへの追記は任意、`roadmap-progress.yaml` が一次ソース)

| サイクル `<identifier>` | 状態 (`active` / `completed` / `blocked` / `cancelled`) | コメント |
| ----------------------- | ------------------------------------------------------- | -------- |
| {{workflow_identifier_1}} | {{workflow_status_1}}                                   | {{workflow_note_1}} |
| {{workflow_identifier_2}} | {{workflow_status_2}}                                   | {{workflow_note_2}} |

## 想定 dev-workflow サイクル数

{{cycle_count_estimate}}

このマイルストーン達成に必要と見込む `dev-workflow` サイクル数 (1 が標準、複数の場合は理由を併記)。1:N とする場合の根拠例: 「設計と実装で 2 サイクルに分けたい」「複数チームが並行して別アプローチを試行する」。

## 補足 / 留意事項

{{notes}}

`roadmap-progress.yaml.milestones[].notes` に書ききれない補足や、配下 `dev-workflow` サイクル起動時の引き継ぎメモ。任意 (空で可)。
