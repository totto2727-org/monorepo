# Validation Report: {{identifier}}

- **Validator:** {{validator_instance_id}}
- **Validated at:** {{validated_at}}
- **Target:** 実装済みコード（全コミット）
- **Reference:** `intent-spec.md` の成功基準

## サマリ

| 判定        | 件数                 |
| ----------- | -------------------- |
| PASS        | {{pass_count}}       |
| FAIL        | {{fail_count}}       |
| 保留（明示）| {{deferred_count}}   |

**全体判定:** {{overall_verdict}}  <!-- passed | failed | partially_passed -->

## 成功基準ごとの判定

### 成功基準 #1: {{criterion_1_statement}}

- **観測値:** {{criterion_1_observed}}
- **判定:** {{criterion_1_verdict}}  <!-- PASS | FAIL | 保留 -->
- **証拠:** {{criterion_1_evidence}}  <!-- ログ / スクリーンショット / メトリクスへのリンク -->
- **計測手段:** {{criterion_1_method}}
- **計測条件:** {{criterion_1_conditions}}  <!-- 環境、データ量、負荷等 -->
- **備考:** {{criterion_1_notes}}

### 成功基準 #2: {{criterion_2_statement}}

- **観測値:** {{criterion_2_observed}}
- **判定:** {{criterion_2_verdict}}
- **証拠:** {{criterion_2_evidence}}
- **計測手段:** {{criterion_2_method}}
- **計測条件:** {{criterion_2_conditions}}
- **備考:** {{criterion_2_notes}}

<!-- 必要な数だけ追加 -->

## テスト実行結果

```
{{test_execution_log}}
```

- 自動テスト: {{automated_test_summary}}
- 統合テスト: {{integration_test_summary}}
- E2E テスト: {{e2e_test_summary}}

## メトリクス

{{metrics_summary}}

定量的な成功基準に対応する計測結果をまとめる。大きなデータは `docs/ai-dlc/<identifier>/validation-evidence/` に保存してリンクする。

| メトリクス       | 目標値       | 観測値       | 判定   |
| ---------------- | ------------ | ------------ | ------ |
| {{metric_1}}     | {{target_1}} | {{actual_1}} | {{v_1}} |
| {{metric_2}}     | {{target_2}} | {{actual_2}} | {{v_2}} |

## 計測不能 / 前提崩壊の記録

{{unmeasurable_entries}}

計測手段の前提が崩れた基準（例: 本番相当環境を用意できない、外部 API が停止、成功基準が観測不能と判明）をここに記録する。単なる FAIL ではなく **観測不能** として扱う。

- **対象成功基準:** <Intent Spec からの引用>
- **前提崩壊の内容:** <何が想定と違ったか>
- **代替観測の可否:** <可能な代替計測 / 不可能な場合の理由>
- **対応推奨:** <Intent Spec 修正 / 観測手段再設計 / Validation 延期 のいずれか>

該当なしの場合は「なし」と明示（空欄にしない）。

## 未達基準への対応方針

{{remediation_plan}}

FAIL や保留があれば、原因・対応方針・ロールバック先候補を Main が記録する。Step 8 失敗時の挙動に従う。

- なし（デフォルト）

## 証拠アーカイブ

{{evidence_archive}}

大きな証跡（ログ、スクリーンショット、プロファイル結果）を `validation-evidence/` 配下に保存した場合、一覧する。

- `validation-evidence/{{evidence_file_1}}`: {{description_1}}
- `validation-evidence/{{evidence_file_2}}`: {{description_2}}
