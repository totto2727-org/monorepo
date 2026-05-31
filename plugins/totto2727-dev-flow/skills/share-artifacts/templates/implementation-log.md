# Implementation Log: {{task_id}}

- **Task:** {{task_id}} — {{task_title}}
- **Implementer:** {{implementer_instance_id}}
- **Started at:** {{started_at}}
- **Completed at:** {{completed_at}}
- **Commits:** {{commit_shas}} <!-- Comma-separated when there are several -->

Capture long-form logs and detailed verification evidence that do not fit in the `notes` column of `TODO.md`.

## Implementation summary

{{summary}}

Describe what was done in this task in 1-2 paragraphs.

## Changed files

{{changed_files}}

- `{{file_1}}`: {{file_1_change_summary}}
- `{{file_2}}`: {{file_2_change_summary}}

## Tests

### Tests that were added

- {{added_test_1}}
- {{added_test_2}}

### Test execution results

```
{{test_output}}
```

- Type check: {{type_check_result}} <!-- passed | failed -->
- Lint: {{lint_result}}
- Existing tests: {{existing_tests_result}}
- New tests: {{new_tests_result}}

## Manual verification log

{{manual_verification}}

When applicable, record the scenarios that were verified manually and their results.

- Scenario: {{scenario_1}}
  - Steps: {{scenario_1_steps}}
  - Result: {{scenario_1_result}}

## Issues encountered and how they were resolved

{{issues_and_resolutions}}

Record unexpected events that occurred during implementation and how they were resolved. This material feeds External Review (six aspects in parallel, including the `holistic` aspect) and Retrospective.

- {{issue_1}} → {{resolution_1}}

## Deviations from the design document

{{design_deviations}}

Record any deviations (ideally none). When a deviation exists, External Review (the `holistic` aspect) examines it and uses the result as input for deciding whether to send the work back to Design.

- None (default)
