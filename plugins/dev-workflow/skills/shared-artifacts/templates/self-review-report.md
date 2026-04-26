# Self-Review Report: {{identifier}}

- **Reviewer:** {{self_reviewer_instance_id}}
- **Target:** Step 5 (Implementation) diff（全タスク）
- **Reviewed at:** {{reviewed_at}}
- **Last updated:** {{updated_at}}

## サマリ

| 深刻度 | 件数             |
| ------ | ---------------- |
| High   | {{high_count}}   |
| Medium | {{medium_count}} |
| Low    | {{low_count}}    |

**Gate 判定:** {{gate_verdict}} <!-- passed | failed (High 残あり) -->

## 指摘事項

### #1 {{finding_1_title}}

- **深刻度:** {{finding_1_severity}} <!-- High | Medium | Low -->
- **該当箇所:**
  - Commit: {{finding_1_commit}}
  - File: {{finding_1_file}}
  - Line: {{finding_1_line}}
  - Task: {{finding_1_task_id}}
- **問題の要約:** {{finding_1_summary}}
- **根拠:** {{finding_1_reasoning}}
- **推奨アクション:** {{finding_1_recommended_action}}
- **design.md との関連:** {{finding_1_design_ref}}
- **Status:** {{finding_1_status}} <!-- open | fixed | wontfix_with_reason -->

### #2 {{finding_2_title}}

- **深刻度:** {{finding_2_severity}}
- **該当箇所:**
  - Commit: {{finding_2_commit}}
  - File: {{finding_2_file}}
  - Line: {{finding_2_line}}
  - Task: {{finding_2_task_id}}
- **問題の要約:** {{finding_2_summary}}
- **根拠:** {{finding_2_reasoning}}
- **推奨アクション:** {{finding_2_recommended_action}}
- **design.md との関連:** {{finding_2_design_ref}}
- **Status:** {{finding_2_status}}

<!-- 必要な数だけ #3, #4, ... を追加 -->

## ADR / Intent Spec との整合性チェック

- **Intent Spec 成功基準:** {{success_criteria_alignment}} <!-- 満たす見込みあり / 懸念あり / 未達の恐れあり -->
- **Design Document との整合:** {{design_alignment}} <!-- 準拠 / 部分的に逸脱 / 大きく逸脱 -->
- **詳細:** {{alignment_details}}

## 修正ラウンド履歴

{{revision_history}}

- Round 1: {{round_1_summary}} <!-- 例: 「High 3 件検出、Step 5 に差し戻し」 -->
- Round 2: {{round_2_summary}}
