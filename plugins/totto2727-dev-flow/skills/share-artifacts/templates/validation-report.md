# Validation Report: {{identifier}}

- **Validator:** {{validator_instance_id}}
- **Validated at:** {{validated_at}}
- **Target:** Implemented code (all commits)
- **Reference:** Success criteria in `intent-spec.md`

## Summary

| Verdict             | Count              |
| ------------------- | ------------------ |
| PASS                | {{pass_count}}     |
| FAIL                | {{fail_count}}     |
| Deferred (explicit) | {{deferred_count}} |

**Overall verdict:** {{overall_verdict}} <!-- passed | failed | partially_passed -->

## Per-criterion verdicts

### Criterion #1: {{criterion_1_statement}}

- **Observed:** {{criterion_1_observed}}
- **Verdict:** {{criterion_1_verdict}} <!-- PASS | FAIL | Deferred -->
- **Evidence:** {{criterion_1_evidence}} <!-- link to logs / screenshots / metrics -->
- **Measurement method:** {{criterion_1_method}}
- **Measurement conditions:** {{criterion_1_conditions}} <!-- environment, data volume, load, etc. -->
- **Notes:** {{criterion_1_notes}}

### Criterion #2: {{criterion_2_statement}}

- **Observed:** {{criterion_2_observed}}
- **Verdict:** {{criterion_2_verdict}}
- **Evidence:** {{criterion_2_evidence}}
- **Measurement method:** {{criterion_2_method}}
- **Measurement conditions:** {{criterion_2_conditions}}
- **Notes:** {{criterion_2_notes}}

<!-- Add as many as needed -->

## Test execution results

```
{{test_execution_log}}
```

- Automated tests: {{automated_test_summary}}
- Integration tests: {{integration_test_summary}}
- E2E tests: {{e2e_test_summary}}

## Metrics

{{metrics_summary}}

Summarize the measurement results corresponding to quantitative success criteria. Save large data sets under `docs/workflow/<identifier>/validation-evidence/` and link to them.

| Metric       | Target       | Observed     | Verdict |
| ------------ | ------------ | ------------ | ------- |
| {{metric_1}} | {{target_1}} | {{actual_1}} | {{v_1}} |
| {{metric_2}} | {{target_2}} | {{actual_2}} | {{v_2}} |

## Records of unmeasurable cases / collapsed premises

{{unmeasurable_entries}}

Record criteria whose measurement premises collapsed (for example: a production-equivalent environment could not be prepared, an external API was down, the criterion turned out to be unobservable). Treat these as **unmeasurable** rather than as a plain FAIL.

- **Target criterion:** <quote from Intent Spec>
- **Nature of the collapsed premise:** <what differed from the assumption>
- **Possibility of an alternative observation:** <feasible alternative measurement / reason if infeasible>
- **Recommended action:** <Intent Spec revision / measurement-method redesign / Validation deferral>

When there are no such cases, write "None" explicitly (do not leave it blank).

## Remediation plan for unmet criteria

{{remediation_plan}}

If any FAIL or deferred verdicts exist, Main records the cause, the remediation plan, and the candidate rollback target. Follow the behavior defined for Step 7 failures.

- None (default)

## Evidence archive

{{evidence_archive}}

When large evidence (logs, screenshots, profiler output) is saved under `validation-evidence/`, list it here.

- `validation-evidence/{{evidence_file_1}}`: {{description_1}}
- `validation-evidence/{{evidence_file_2}}`: {{description_2}}
