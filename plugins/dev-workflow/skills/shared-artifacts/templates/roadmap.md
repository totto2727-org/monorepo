# Roadmap: {{title}}

- **Roadmap ID:** {{roadmap_id}}
- **Author:** {{author}}
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}
- **Status:** {{status}} <!-- planned | active | completed (`roadmap-progress.yaml.status` と一致させる) -->

このドキュメントは `dev-roadmap` の **Step 1 (Roadmap Intent)** で起草され、**Step 2 (Milestone Decomposition)** でマイルストーン一覧と依存グラフが追記されて確定する**戦略層の不変な計画書**。1 サイクルの `dev-workflow` では収まらない複数サイクル規模の開発を束ねる。書き方の詳細は `shared-artifacts/references/roadmap.md` を参照。

## 背景

{{background}}

なぜ今このロードマップに取り組むのか、複数の `dev-workflow` サイクルにまたがる必要が生じた経緯を記述する。「単一サイクルでは収まらない理由」を必ず示すこと (= 戦略層が必要な根拠)。

## 目的

{{purpose}}

ロードマップが達成したいゴールを 1〜3 文で。**定性的な到達点**でよい (観測可能な成功基準は配下の各 `dev-workflow` サイクルの Intent Spec が持つ責務)。例: 「OAuth 認証が本番運用可能な状態になっている」「決済基盤の段階的リプレースが完了している」。

## スコープ境界

{{scope}}

- ロードマップ全体で扱う領域・モジュール・対象ユーザー
- 配下マイルストーン群の最大外周

## 非スコープ

{{out_of_scope}}

- 意図的に扱わない領域 (将来別ロードマップで扱う / 別チームの責務 / 今回見送り 等)
- 「roadmap-of-roadmaps (1 階層を超える入れ子)」「観測可能な成功基準を roadmap 自身に持たせる」など、`dev-roadmap` スキル全体の非スコープ事項に該当するものはここに改めて書かなくてよい

## 大局的制約

{{constraints}}

ロードマップ全体に影響する制約。配下の `dev-workflow` サイクル個別の制約はそれぞれの Intent Spec が持つため、ここには **複数サイクルを横断して効くもの** だけを書く。

- 技術的制約 (使用可能スタック、互換性、共有インフラ等)
- 組織的制約 (期限、人員配分、予算上限、サイクル並行数の上限等)
- 規範的制約 (セキュリティ、コンプライアンス、既存 ADR、上位プロダクト方針等)

## マイルストーン一覧

{{milestone_summary}}

Step 2 (Milestone Decomposition) で `roadmap-planner` が確定するセクション。1 行 1 マイルストーンで概要を列挙し、詳細は `milestones/<milestone-id>.md` (1 ファイル / マイルストーン) に切り出す。

| ID                | タイトル          | 想定 dev-workflow サイクル数 | 依存マイルストーン        | 詳細                              |
| ----------------- | ----------------- | ---------------------------- | ------------------------- | --------------------------------- |
| {{milestone_1_id}} | {{milestone_1_title}} | {{milestone_1_cycle_count}}  | {{milestone_1_depends_on}} | `milestones/{{milestone_1_id}}.md` |
| {{milestone_2_id}} | {{milestone_2_title}} | {{milestone_2_cycle_count}}  | {{milestone_2_depends_on}} | `milestones/{{milestone_2_id}}.md` |
| {{milestone_3_id}} | {{milestone_3_title}} | {{milestone_3_cycle_count}}  | {{milestone_3_depends_on}} | `milestones/{{milestone_3_id}}.md` |

<!-- 必要な数だけ行を追加する。最低 3 行を目安とする (SC-11: 仮想マイルストーン分解の説明性) -->

## 依存グラフ

{{dependency_graph}}

マイルストーン間の依存関係を Mermaid `graph LR` で図示する。`task-plan.md` 等の既存パターンと表記を揃え、追加レンダラに依存しない GitHub 標準レンダリングで完結すること。

```mermaid
graph LR
  {{milestone_1_id}}[{{milestone_1_id}} {{milestone_1_short_title}}]
  {{milestone_2_id}}[{{milestone_2_id}} {{milestone_2_short_title}}]
  {{milestone_3_id}}[{{milestone_3_id}} {{milestone_3_short_title}}]
  {{milestone_1_id}} --> {{milestone_2_id}}
  {{milestone_2_id}} --> {{milestone_3_id}}
```

ノード数は 15〜20 を推奨上限とし、超える場合は段階分割 (例: フェーズごとに別グラフ) を検討する。

## 関連リンク

{{references}}

- 関連 ADR (`docs/adr/`)
- 関連 Issue / チケット
- 上位プロダクト計画書 / OKR
- 関連既存サイクル (`docs/workflow/<identifier>/`、関係する完了サイクルの `intent-spec.md` 等)

## 未解決事項

{{open_questions}}

Step 1〜Step 2 段階で解消しきれなかった戦略レベルの論点。各マイルストーンに紐付く `dev-workflow` サイクルが Step 1 (Intent Clarification) や Step 2 (Research) で扱う論点はここではなく、配下サイクルに委譲する旨を明記する。
