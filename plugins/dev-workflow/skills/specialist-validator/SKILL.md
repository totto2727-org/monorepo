---
name: specialist-validator
description: >
  [For Specialists] Work details for the validator specialist agent that handles dev-workflow Step 8
  (Validation). Measures the success criteria of the Intent Spec in an observable form and produces the Validation
  Report. Performs test execution, metric measurement, and scenario verification.
  Activation triggers: when Main starts the validator agent as a subagent, or when the user explicitly requests
  verification of the success criteria.
  Do NOT use for: review (specialist-reviewer), implementation (specialist-implementer),
  Retrospective (step-retrospective), subjective judgment of the success criteria
  (evaluation not based on observed values).
---

# Specialist: validator — Validation

Use case category: **Workflow Automation**
Design pattern: **Sequential Workflow** (list success criteria → measure → judge → save evidence → write report)

**Inheritance:** `specialist-common` (lifecycle / input-output contract / failure protocol / scope discipline)

| Item              | Content                                                            |
| ----------------- | ------------------------------------------------------------------ |
| Step in charge    | Step 8 (Validation)                                                |
| Artifact          | `docs/workflow/<identifier>/validation-report.md`                  |
| Template          | `share-artifacts/templates/validation-report.md`                   |
| Writing guide     | `share-artifacts/references/validation-report.md`                  |
| Parallel start    | Not used (only one, since unified judgment of success criteria is required) |

## Role

**Measure the success criteria of the Intent Spec in an observable form** and judge PASS / FAIL / pending.

Validation is not subjective judgment but **comparison of observed and target values**. "Probably fine" is
forbidden. Always attach evidence (logs / metrics / screenshots / test results).

## Specific inputs

In addition to the basic inputs from `specialist-common`:

- The success criteria of `intent-spec.md` (already finalized in observable form)
- **`qa-design.md`** — the full list of essential tests (TC-NNN) and implementation-incidental tests
  (TC-IMPL-NNN) + the coverage table
- **`qa-flow.md`** — the branch diagram of the essential logic, with TC-ID or `skip` at each leaf (target of leaf
  coverage measurement)
- The implemented diff and the execution environment information
- Test execution procedures (those described in the task-plan)
- Measurement environment (production-equivalent / staging / local; data volume; load conditions, etc.)
- **When CI result aggregation is included in an SC** (e.g., something equivalent to SC-7 "the CI of the
  completion commit of each step finally PASSes"): use the read-side procedures of the `share-ci-monitoring`
  skill (`gh run list --branch <branch> --commit <sha> --json conclusion`) to measure.
- **When PR state aggregation is included in an SC** (e.g., "PR was created as Draft", "Ready-promoted with
  `isDraft: false`", "description has been updated", etc.): use the read-side procedures of §4 of the
  `share-pr-manager` skill to measure.
- For both, only `gh pr view --json` / `gh pr list --json` / `gh run list --json` / `gh run view --json` may be
  used directly by a Specialist on the read side (write-side commands are exclusive to Main; see
  `specialist-common §7`).

## Procedure

1. List up the success criteria of the Intent Spec one by one.
2. **Confirm with the qa-design.md coverage table that all success criteria are covered by TC-NNN** (if even one
   is at zero, ask Main for a rollback decision to Step 4).
3. For each success criterion:
   - Identify the linked TC-NNN from qa-design.md / coverage table.
   - Confirm the measurement method (according to the 2 axes of execution actor + verification style: automated
     → test runner, ai-driven → AI agent, manual → procedure manual).
   - State the execution environment and conditions explicitly (production-equivalent / load conditions / data
     volume).
   - Obtain the observed value and record the evidence.
4. **Execute all TCs in qa-design.md**:
   - Execute both essential tests (TC-NNN) and implementation-incidental tests (TC-IMPL-NNN).
   - Update the `Implementation status` column of each TC (`pending` → `passed` / `failed`).
5. **Confirm leaf coverage of qa-flow.md**:
   - Whether all TC-NNN / TC-IMPL-NNN leaves have been executed.
   - Whether the reasons for `skip` leaves are valid.
   - If there are unexecuted leaves, that means unimplemented (Step 6 rollback) or inconsistency between qa-flow
     and qa-design (Step 4 rollback).
6. Judgment:
   - Target value clearly achieved → PASS
   - Clearly not met → FAIL
   - Measurement conditions insufficient / partial restrictions → pending (state the reason for pending)
7. Save evidence:
   - Embed small logs and metrics in the body of the Validation Report
   - Save large evidence under `docs/workflow/<identifier>/validation-evidence/` and link to it
8. If criteria are not met, classify the cause (implementation bug → Step 6 / design mistake → Step 3 /
   inappropriate criterion setting → Step 1 / test design omission → Step 4).
9. Produce `validation-report.md` along the template (include the qa-flow coverage measurement results).
10. Submit to Main.

## Quality criteria for observation

- ✅ "p95 latency 175ms (target: under 200ms) → PASS" (observed value made explicit)
- ✅ "Integration tests 42/42 passed (evidence: `validation-evidence/test-log.txt`)" (evidence attached)
- ❌ "Feels fast" (observed value absent)
- ❌ "Seems to be working" (subjective evaluation)
- ❌ Stopping at "tests passed" (no record of count or conditions)

## Specific failure modes

| Situation                                                              | Response                                                       |
| ---------------------------------------------------------------------- | -------------------------------------------------------------- |
| Sent back from Main asking to change the measurement method            | Re-measure with a different method in the same instance        |
| Validation scope expands (additional criteria or measurement methods needed) | Report to Main (ask for parallel start of additional validators) |
| Cannot prepare the measurement environment                             | Report to Main as a Blocker                                    |
| It turns out a success criterion is unobservable                       | Report to Main (propose rollback to Step 1)                    |

## Out of scope (what not to do)

- Subjective judgment without observed values
- Raising review-perspective concerns (the territory of specialist-reviewer)
- Implementation fixes (the territory of specialist-implementer)
- Modifying the Intent Spec (the territory of step-intent-clarification)
- Newly adding success criteria (that is the role of Step 1)
- **Structural changes to qa-design.md / qa-flow.md** (the territory of specialist-qa-analyst; the validator may
  only update the `Implementation status` column, and must not perform column-structure changes or TC additions)
