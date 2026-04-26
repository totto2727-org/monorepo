# Task Plan: {{title}}

- **Identifier:** {{identifier}}
- **Author:** {{planner_instance_id}}
- **Source:** `design.md`
- **Created at:** {{created_at}}
- **Status:** {{status}} <!-- draft | approved -->

このドキュメントは **Step 4 で確定する不変な計画書**。Step 5〜6 中のタスク状態追跡は `TODO.md` で行う。

## 前提

- Design Document のコンポーネント構成・主要型・API 設計に基づいてタスクを分解している
- 1 タスク = 1 人の `implementer` が完遂可能な粒度
- 並列実行可能なタスクは明示されている

## タスク一覧

### T1: {{task_1_title}}

- **概要:** {{task_1_summary}}
- **成果物:** {{task_1_artifact}} <!-- 追加されるファイル / 変更されるファイル / コミット対象 -->
- **依存タスク:** {{task_1_dependencies}} <!-- なし または T<n>, T<m> -->
- **並列可否:** {{task_1_parallelizable}} <!-- yes | no（他タスクと同時起動可か） -->
- **見積り規模:** {{task_1_estimate}} <!-- S | M | L など、プロジェクト規約に従う -->
- **テスト追加方針:** {{task_1_test_strategy}}
- **設計ドキュメント参照箇所:** {{task_1_design_ref}}

### T2: {{task_2_title}}

- **概要:** {{task_2_summary}}
- **成果物:** {{task_2_artifact}}
- **依存タスク:** {{task_2_dependencies}}
- **並列可否:** {{task_2_parallelizable}}
- **見積り規模:** {{task_2_estimate}}
- **テスト追加方針:** {{task_2_test_strategy}}
- **設計ドキュメント参照箇所:** {{task_2_design_ref}}

<!-- 必要な数だけ T3, T4, ... を追加 -->

## 依存グラフ

```mermaid
{{dependency_graph}}
```

例:

```
graph LR
  T1 --> T3
  T2 --> T3
  T3 --> T4
  T3 --> T5
```

## 並列実行可能グループ

Step 5 で Main が参照する並列起動単位。

- **Wave 1（起点）:** {{wave_1}} <!-- 例: T1, T2 -->
- **Wave 2:** {{wave_2}} <!-- 例: T3（T1, T2 完了後）-->
- **Wave 3:** {{wave_3}} <!-- 例: T4, T5（T3 完了後、並列実行可）-->

## リスク / 想定される Blocker

{{risks}}

- {{risk_1}}
- {{risk_2}}
