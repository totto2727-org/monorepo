# Design Document: {{title}}

- **Identifier:** {{identifier}}
- **Author:** {{architect_instance_id}}
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}
- **Status:** {{status}} <!-- draft | approved -->

## 設計目標と制約

{{goals_and_constraints}}

Intent Spec の目的・成功基準・制約をここに取り込み、設計判断の前提を明示する。

- **目的（Intent Spec より）:** {{purpose_quote}}
- **成功基準:** {{success_criteria_quote}}
- **主要制約:** {{constraints_quote}}

## アプローチの概要

{{approach_overview}}

採用するアプローチの全体像を 1–3 段落で記述する。なぜこのアプローチなのかの核心を含める。

## コンポーネント構成

{{components}}

主要コンポーネント / モジュール / 層の一覧と役割を記述する。必要に応じて図（Mermaid 等）を埋め込む。

```mermaid
{{component_diagram}}
```

### 主要な型・インターフェース

{{key_types}}

```typescript
{
  {
    type_definitions_example
  }
}
```

## データフロー / API 設計

{{data_flow}}

リクエストの経路、データ変換、API シグネチャを記述する。

### API エンドポイント

| Method | Path     | Description | Request | Response |
| ------ | -------- | ----------- | ------- | -------- |
| {{m}}  | {{path}} | {{desc}}    | {{req}} | {{resp}} |

## 代替案と採用理由

{{alternatives}}

検討した代替案と却下理由を表で明示する。

| 案           | 概要                 | 採用 / 却下 | 理由                   |
| ------------ | -------------------- | ----------- | ---------------------- |
| {{option_a}} | {{option_a_summary}} | 採用        | {{option_a_rationale}} |
| {{option_b}} | {{option_b_summary}} | 却下        | {{option_b_rationale}} |
| {{option_c}} | {{option_c_summary}} | 却下        | {{option_c_rationale}} |

## 想定される拡張ポイント

{{extension_points}}

将来の拡張が見込まれる箇所と、そのために今回の設計で確保しているインターフェース・抽象を記述する。

## 運用上の考慮事項

{{operational_considerations}}

- **監視 / 観測:** {{observability}}
- **移行 / 切替:** {{migration_strategy}}
- **ロールアウト:** {{rollout_plan}}
- **ロールバック:** {{rollback_strategy}}
- **セキュリティ:** {{security_considerations}}
- **パフォーマンス予測:** {{performance_expectations}}

## プロジェクト横断 ADR への参照

{{external_adrs}}

このサイクルで起票した、または既存のプロジェクト横断 ADR があればリンクする。サイクル固有の判断はここではなく本ドキュメント内で完結させる。

- [{{adr_title}}]({{adr_path}})

## Task Decomposition への引き継ぎポイント

{{handoff_notes}}

Step 4 (Task Decomposition) で `planner` が参照すべき設計判断を明示する。タスク分割の粒度目安や並列性の手掛かりを含める。
