# Review Report: {{aspect}}

- **Identifier:** {{identifier}}
- **Aspect:** {{aspect}} <!-- security | performance | readability | test-quality | api-design | holistic | etc. -->
- **Reviewer:** {{reviewer_instance_id}}
- **Reviewed at:** {{reviewed_at}}
- **Scope:** {{review_scope}} <!-- 観点ごとのスコープ限定を明示 -->

## サマリ

| 深刻度  | 件数              |
| ------- | ----------------- |
| Blocker | {{blocker_count}} |
| Major   | {{major_count}}   |
| Minor   | {{minor_count}}   |

**Gate 判定:** {{gate_verdict}} <!-- approved | needs_fix | blocked -->

## 指摘事項

### #1 {{finding_1_title}}

- **深刻度:** {{finding_1_severity}} <!-- Blocker | Major | Minor -->
- **該当箇所:**
  - Commit: {{finding_1_commit}}
  - File: {{finding_1_file}}
  - Line: {{finding_1_line}}
- **問題の要約:** {{finding_1_summary}}
- **根拠:** {{finding_1_reasoning}}
- **推奨アクション:** {{finding_1_recommended_action}}
- **設計との関連:** {{finding_1_design_ref}}

### #2 {{finding_2_title}}

- **深刻度:** {{finding_2_severity}}
- **該当箇所:**
  - Commit: {{finding_2_commit}}
  - File: {{finding_2_file}}
  - Line: {{finding_2_line}}
- **問題の要約:** {{finding_2_summary}}
- **根拠:** {{finding_2_reasoning}}
- **推奨アクション:** {{finding_2_recommended_action}}
- **設計との関連:** {{finding_2_design_ref}}

<!-- 必要な数だけ追加 -->

## 観点固有の評価項目

{{aspect_specific_evaluation}}

例（aspect が security の場合）:

- 認証認可の網羅性: {{auth_coverage}}
- 入力検証の強度: {{input_validation}}
- 秘匿情報の取り扱い: {{secrets_handling}}
- 依存ライブラリの脆弱性: {{dep_vulnerabilities}}

例（aspect が performance の場合）:

- 計算量評価: {{complexity_assessment}}
- I/O 効率: {{io_efficiency}}
- メモリ使用量: {{memory_usage}}
- 並行性の正当性: {{concurrency_correctness}}

観点ごとにテンプレート利用時に書き替えること。

## 修正ラウンド履歴

Step 6 ↔ Step 7 のループで Round 2 以降を行った場合、Round 単位の Blocker / Major / Minor 件数推移を記録する。Round 1 のみで完了した場合は Round 1 行のみ記入。3 周以上ループした場合は Step 3 ロールバック判断材料となる (`dev-workflow/SKILL.md` の「ループ上限の目安」参照)。

| Round | Blocker         | Major         | Minor         | 主要指摘 (要約)         | 修正コミット SHA          |
| ----- | --------------- | ------------- | ------------- | ----------------------- | ------------------------- |
| 1     | {{r1_blocker}}  | {{r1_major}}  | {{r1_minor}}  | {{r1_summary}}          | {{r1_commits}}            |
| 2     | {{r2_blocker}}  | {{r2_major}}  | {{r2_minor}}  | {{r2_summary}}          | {{r2_commits}}            |

<!-- Round 3 以降が発生した場合は行を追加 -->

## 他レビューとの整合性

{{cross_review_consistency}}

他の Review Report と矛盾する指摘がある場合はここに記録する。Main が両者の根拠を比較して判断する材料となる。

- なし（デフォルト）
