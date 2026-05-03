# Reference: How to write `validation-report.md`

## Purpose

**Measure the success criteria of `intent-spec.md` in observable form** and judge PASS / FAIL / pending. Not subjective judgment but **comparison of observed values with target values**. Always attach evidence (logs / metrics / screenshots / test results).

## Author / creation timing

- **Author:** `validator` Specialist (single instance)
- **Step:** Step 8 (Validation)
- **Approval:** user approval required

## File location

`docs/workflow/<identifier>/validation-report.md`

Large evidence data is stored under `docs/workflow/<identifier>/validation-evidence/` and linked.

## How to write each section

### Summary

| Verdict            | Count |
| ------------------ | ----- |
| PASS               | {{n}} |
| FAIL               | {{n}} |
| Pending (explicit) | {{n}} |

**Overall verdict:** `passed` / `failed` / `partially_passed`

### Verdict per success criterion

For each success criterion, append:

- **Observed value:** the actually measured value
- **Verdict:** PASS / FAIL / pending
- **Evidence:** link (path) to logs / screenshots / metrics
- **Measurement means:** how it was measured (automated test / metric collection / scenario execution)
- **Measurement conditions:** environment (production-equivalent / staging / local), data volume, load
- **Notes:** caveats

### Test execution results

Paste actual test execution logs (if long, excerpt only the head and tail and store the whole under `validation-evidence/`).

- Number of automated tests / pass-fail
- Number of integration tests / pass-fail
- Number of E2E tests / pass-fail

### Metrics

Measurement results corresponding to quantitative success criteria:

| Metric      | Target  | Observed | Verdict |
| ----------- | ------- | -------- | ------- |
| p95 latency | < 200ms | 175ms    | PASS    |

### Response policy for unmet criteria

If there are FAILs or pendings:

- Cause classification (implementation bug / design mistake / inappropriate criterion setting)
- Recommended rollback target
- Whether to hand off to user judgment

### Evidence archive

List of files under `validation-evidence/` and explanations.

## Observation quality criteria

| Good                                                                                                   | Bad                                        |
| ------------------------------------------------------------------------------------------------------ | ------------------------------------------ |
| "p95 175ms (target < 200ms) → PASS"                                                                    | "Feels fast"                               |
| "Integration tests 42/42 passed (evidence `validation-evidence/test-log.txt`)"                         | "Looks like it works"                      |
| Measurement conditions (environment / data volume / load) are explicit                                 | Just "confirmed locally" with nothing more |
| If pending, the reason for pending and the technical background that prevents measurement are explicit | Pending reason is "for now"                |

## Validation principles

- **No subjective judgment**: do not write "probably fine" or "likely no problem" in the Validation Report
- **Evidence attachment required**: always attach a source (log file / metric dashboard link / screenshot) to observed values
- **Make measurement conditions explicit**: without writing production-equivalent / staging / local, data volume, and load conditions, there is no reproducibility
- **Cite the target values**: cite the success criteria of `intent-spec.md` and place them side by side (so target and observed values are visible at a glance)

## Related artifacts

- **Inputs:** the success criteria of `intent-spec.md`, the implemented diff and execution environment information, test execution procedure
- **Output destination:** unmet success criterion → determination of rollback target (implementation bug: Step 6 / design mistake: Step 3 / inappropriate criterion: Step 1)
- **Subsequent:** Validation results are reflected in `retrospective.md`
