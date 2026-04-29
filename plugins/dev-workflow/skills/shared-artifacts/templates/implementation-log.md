# Implementation Log: {{task_id}}

- **Task:** {{task_id}} — {{task_title}}
- **Implementer:** {{implementer_instance_id}}
- **Started at:** {{started_at}}
- **Completed at:** {{completed_at}}
- **Commits:** {{commit_shas}} <!-- 複数ある場合はカンマ区切り -->

`TODO.md` の notes 欄に収まらない長大なログや、動作確認の詳細証跡を保存する。

## 実装サマリ

{{summary}}

このタスクで何をしたかを 1–2 段落で記述する。

## 変更ファイル

{{changed_files}}

- `{{file_1}}`: {{file_1_change_summary}}
- `{{file_2}}`: {{file_2_change_summary}}

## テスト

### 追加したテスト

- {{added_test_1}}
- {{added_test_2}}

### テスト実行結果

```
{{test_output}}
```

- Type check: {{type_check_result}} <!-- passed | failed -->
- Lint: {{lint_result}}
- Existing tests: {{existing_tests_result}}
- New tests: {{new_tests_result}}

## 手動確認ログ

{{manual_verification}}

該当する場合、手動で確認したシナリオと結果を記録する。

- シナリオ: {{scenario_1}}
  - 手順: {{scenario_1_steps}}
  - 結果: {{scenario_1_result}}

## 発生した問題とその対処

{{issues_and_resolutions}}

実装中に遭遇した想定外の事象と、どう解決したかを記録する。External Review (`holistic` 観点を含む 6 観点並列) および Retrospective の材料となる。

- {{issue_1}} → {{resolution_1}}

## 設計ドキュメントからの逸脱

{{design_deviations}}

あれば記録する（理想的にはゼロ）。逸脱がある場合は External Review (`holistic` 観点) で確認され、必要なら Design への差し戻し判断材料となる。

- なし（デフォルト）
