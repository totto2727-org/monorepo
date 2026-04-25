# Retrospective: {{identifier}}

- **Identifier:** {{identifier}}
- **Writer:** {{retrospective_writer_instance_id}}
- **Created at:** {{created_at}}
- **Cycle started at:** {{cycle_started_at}}
- **Cycle completed at:** {{cycle_completed_at}}
- **Duration:** {{duration}}

## サイクル概要

{{cycle_summary}}

何を達成したサイクルか、Intent Spec の目的に対してどう応えたかを 1–3 段落で記述する。

## 良かった点（うまく機能したパターン）

{{what_went_well}}

次サイクル以降にも意図的に再現すべきアプローチを記録する。

- {{good_point_1}}
- {{good_point_2}}
- {{good_point_3}}

## 課題（うまくいかなかった箇所）

{{issues}}

ループ回数が多かった箇所、Blocker の根本原因、想定外のコストが発生した箇所を記録する。

### ループ回数の分析

| ステップ間ループ                | 回数              | 根本原因            |
| ------------------------------- | ----------------- | ------------------- |
| Step 5 ↔ Step 6                 | {{loop_5_6}}      | {{root_cause_5_6}}  |
| Construction → Inception Step 3 | {{rollback_c_i3}} | {{root_cause_c_i3}} |
| Verification → Construction     | {{rollback_v_c}}  | {{root_cause_v_c}}  |

### Blocker 履歴

- {{blocker_1}}（発生: {{blocker_1_at}}、解消: {{blocker_1_resolved_at}}、対応: {{blocker_1_resolution}}）
- {{blocker_2}}（発生: {{blocker_2_at}}、解消: {{blocker_2_resolved_at}}、対応: {{blocker_2_resolution}}）

## 次回改善案

{{improvements}}

具体的なアクション粒度まで分解する（「〜を改善する」ではなく「〜のときに〜する」）。

### プロセス改善

- {{process_improvement_1}}
- {{process_improvement_2}}

### スキル改善

AI-DLC プラグインのスキル（workflow / inception / construction / verification）への具体的な改善提案。

- {{skill_improvement_1}}
- {{skill_improvement_2}}

### Specialist プロンプト改善

Specialist の役割定義・入力仕様・期待成果物の改善提案。

- `intent-analyst`: {{intent_analyst_improvement}}
- `researcher`: {{researcher_improvement}}
- `architect`: {{architect_improvement}}
- `planner`: {{planner_improvement}}
- `implementer`: {{implementer_improvement}}
- `self-reviewer`: {{self_reviewer_improvement}}
- `reviewer`: {{reviewer_improvement}}
- `validator`: {{validator_improvement}}

## 再利用可能な知見

{{reusable_insights}}

他のサイクル・他のプロジェクトでも役立ちそうな学び。メモリや CLAUDE.md への反映候補を含む。

- {{insight_1}}
- {{insight_2}}

## ユーザー承認ゲートの振り返り

{{gate_retrospective}}

各承認ゲートでの承認 / 却下の記録、却下があった場合の原因を振り返る。

- Step 1 (Intent Clarification): {{gate_1_summary}}
- Step 3 (Design): {{gate_3_summary}}
- Step 4 (Task Decomposition): {{gate_4_summary}}
- Step 7 (External Review): {{gate_7_summary}}
- Step 8 (Validation): {{gate_8_summary}}

## In-Progress ユーザー問い合わせの振り返り

{{in_progress_question_summary}}

サイクル中に作成した `$TMPDIR/ai-dlc/*.md` 一時レポート（作業途中の判断要請）の件数と主要トピックを要約する。件数が多ければ Intent Spec 段階での明確化不足を示唆している可能性がある。

- 件数: {{in_progress_question_count}}
- 主要トピック: {{in_progress_question_topics}}

## コスト / 時間

{{cost_time}}

- 各フェーズの実時間: {{phase_durations}}
- Specialist 起動回数: {{specialist_launch_count}}
- 並列度の実効: {{effective_parallelism}}
