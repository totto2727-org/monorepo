# Roadmap Retrospective: {{roadmap_id}}

- **Roadmap ID:** {{roadmap_id}}
- **Writer:** {{roadmap_retrospective_writer_instance_id}}
- **Created at:** {{created_at}}
- **Roadmap started at:** {{roadmap_started_at}}
- **Roadmap completed at:** {{roadmap_completed_at}}
- **Duration:** {{duration}}

このドキュメントは `dev-roadmap` の **Step 4 (Roadmap Retrospective)** で `roadmap-retrospective-writer` Specialist が起草する**ロードマップ全体の振り返り**。配下の各 `dev-workflow` サイクルの `retrospective.md` を集約し、roadmap 固有の論点 (マイルストーン達成度総括 / 依存グラフ妥当性 / roadmap 固有改善案) を加えて統合する。`docs/retrospective/roadmap-<roadmap-id>.md` (集約形式 + `roadmap-` prefix) に配置する。書き方の詳細は `shared-artifacts/references/roadmap-retrospective.md` を参照。

## ロードマップ概要

{{roadmap_summary}}

`roadmap.md` の目的に対してロードマップ全体として何を達成したかを 1〜3 段落で記述する。

## マイルストーン達成度の総括

{{milestone_completion_summary}}

`roadmap-progress.yaml.milestones[]` の最終状態を一覧化し、各マイルストーンの達成 / 未達 / blocked / cancelled の判定根拠を記述する。

| Milestone ID         | Title                  | Final Status        | 達成判定の根拠                              | 関連 dev-workflow `<identifier>`             |
| -------------------- | ---------------------- | ------------------- | ------------------------------------------- | -------------------------------------------- |
| {{milestone_1_id}}   | {{milestone_1_title}}  | {{milestone_1_status}} | {{milestone_1_completion_rationale}}        | {{milestone_1_workflow_identifiers}}         |
| {{milestone_2_id}}   | {{milestone_2_title}}  | {{milestone_2_status}} | {{milestone_2_completion_rationale}}        | {{milestone_2_workflow_identifiers}}         |
| {{milestone_3_id}}   | {{milestone_3_title}}  | {{milestone_3_status}} | {{milestone_3_completion_rationale}}        | {{milestone_3_workflow_identifiers}}         |

<!-- 必要な数だけ行を追加。`milestones/<milestone-id>.md` の「到達点 (定性)」と照らし合わせて判定する -->

## 依存グラフ妥当性の振り返り

{{dependency_graph_review}}

Step 2 で確定したマイルストーン依存グラフが、実際の進行を経てなお妥当であったかを振り返る。観点例:

- 想定どおり機能した依存 (起点・収束点が適切だった)
- 実行段階で判明した不要な依存 (マイルストーン A が B に依存しないことが判明したが、依存があったため不要に直列化された)
- 実行段階で判明した不足依存 (マイルストーン C が暗黙に D を必要としていたが、依存グラフに無かったため後続サイクルが手戻り)
- 並列度の実効値 (理論並列度 vs 実際の並列起動サイクル数)

## 配下 dev-workflow サイクルの集約

{{workflow_aggregation}}

配下の各 `dev-workflow` サイクルの `docs/retrospective/<identifier>.md` を**1 段落 / サイクル**で要約する。各段落には以下を含める:

- サイクル `<identifier>`
- 紐付くマイルストーン id
- そのサイクル単独で目立った良かった点 / 課題 (1〜2 件まで)
- 当該サイクルの retrospective へのリンク

### {{workflow_identifier_1}} (milestone: {{milestone_1_id}})

{{workflow_summary_1}}

参照: `docs/retrospective/{{workflow_identifier_1}}.md`

### {{workflow_identifier_2}} (milestone: {{milestone_2_id}})

{{workflow_summary_2}}

参照: `docs/retrospective/{{workflow_identifier_2}}.md`

<!-- 配下サイクル数だけ繰り返す -->

## roadmap 固有の改善案

{{roadmap_specific_improvements}}

ロードマップ層 (`dev-roadmap` スキル / `roadmap-progress.yaml` スキーマ / マイルストーン分割粒度等) への改善案。配下サイクル内で完結する改善案は当該サイクルの `retrospective.md` に書かれているため、ここではそれらを統合した戦略レベルの改善のみを書く。

### `roadmap-progress.yaml` スキーマ拡張提案

- {{schema_improvement_1}}
- {{schema_improvement_2}}

### マイルストーン分割粒度の振り返り

- {{decomposition_review_1}}
- {{decomposition_review_2}}

### ステップ単位反映の必要性検討 (本バージョン scope out 方針の再評価)

{{step_level_progress_review}}

本バージョンでは「(b) 各ステップ完了時の進捗サマリ反映」を `roadmap-progress.yaml` の責務から scope out していた。実運用を経て本方針が妥当だったか / 拡張が必要かを評価し、必要であれば次ロードマップでのスキーマ拡張案 (`events` 配列 / `last_step` フィールド等) を起案する。

### `dev-roadmap` ↔ `dev-workflow` 連携プロトコルの振り返り

- {{coupling_review_1}}
- {{coupling_review_2}}

## 次サイクルへの引き継ぎ

{{handoff_to_next_roadmap}}

次に類似のロードマップを起こす場合に活かせる知見、再利用可能なマイルストーンパターン、避けるべき落とし穴を記述する。

## ユーザー承認ゲートの振り返り

{{gate_retrospective}}

各承認ゲート (Step 1: Roadmap Intent / Step 2: Milestone Decomposition / Step 4: Roadmap Retrospective) での承認 / 却下の記録、却下があった場合の原因を振り返る。

- Step 1 (Roadmap Intent): {{gate_1_summary}}
- Step 2 (Milestone Decomposition): {{gate_2_summary}}
- Step 4 (Roadmap Retrospective): {{gate_4_summary}}

## コスト / 時間

{{cost_time}}

- ロードマップ全体の経過日数: {{total_duration}}
- 配下 `dev-workflow` サイクル数: {{workflow_count}}
- 並列度の実効: {{effective_parallelism}}
- Specialist 起動回数 (roadmap 系のみ): {{roadmap_specialist_launch_count}}
