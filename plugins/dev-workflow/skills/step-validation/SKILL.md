---
name: step-validation
description: >
  [Main coordinator] Detail skill for dev-workflow Step 8 (Validation). Read
  this when starting Step 8 of dev-workflow, when the user asks to "validate
  the implementation against the success criteria" or to "produce
  validation-report.md". Defines how Main launches `validator` × 1 to measure
  Intent Spec success criteria empirically (test runs, metrics, scenario
  checks) and produce the Validation Report with evidence. Trigger phrases:
  "starting Step 8 of dev-workflow", "validation step", "produce
  validation-report.md".
  Do NOT use for: external review (`step-external-review`), retrospective
  (`step-retrospective`), specialist internals (`specialist-validator`), or
  artifact format details (`share-artifacts/references/validation-report.md`).
---

# Step 8: Validation

## Purpose

Confirm achievement of every Intent Spec success criterion in **observable form** — running tests, measuring metrics, executing scenarios — and capture the evidence in a single Validation Report. This is the gate where "the cycle delivered what it promised" is judged on data, not opinion.

## Invocation

**Specialist:** `validator` × 1.

**Justifications:**

- **Context isolation (C):** the validator must absorb Intent Spec, every diff, test outputs, and any execution-environment information — a substantial input set best held in a dedicated context.
- **Independent viewpoint (V):** a fresh evaluator distinct from the implementer is required; the validator is the empirical adjudicator of success.

## Required inputs from Main

- `docs/workflow/<identifier>/intent-spec.md` (success criteria are the validation targets).
- All Step 6 diffs and the execution-environment information needed to run them.
- The test execution procedure (as documented in `task-plan.md` / `qa-design.md`).
- `share-artifacts/references/validation-report.md` and `share-artifacts/templates/validation-report.md`.
- Read-side `gh pr` query catalog (`share-pr-manager` §4) — used by `validator` for SC validation against PR state when applicable.

## Procedure

1. Launch `validator` × 1 with the inputs above. Make explicit that Validation is **objective measurement against observable signals**, not subjective approval.
2. Direct the specialist to: run the automated test suite, collect metrics, execute scenario checks, and capture evidence (logs, screenshots, metric snapshots).
3. Receive the Validation Report. Present it directly to the user for the gate decision (Artifact-as-Gate-Review).
4. If a success criterion is unmet, raise an In-Progress user inquiry (`$TMPDIR/dev-workflow/step8-*.md`) presenting the alternatives (rollback target, scope adjustment, mitigation) before deciding.
5. Save evidence files under `docs/workflow/<identifier>/validation-evidence/` if they are too large for the report itself.

## Expected artifacts

- `docs/workflow/<identifier>/validation-report.md` — success criteria, observed values, judgment, evidence references. Source: `share-artifacts/templates/validation-report.md` + `share-artifacts/references/validation-report.md`.
- `docs/workflow/<identifier>/validation-evidence/` — large evidence files (logs, screenshots, metrics dumps).
- `docs/workflow/<identifier>/progress.yaml` — `completed_steps`, `artifacts.validation_report`, evidence paths updated.

## Exit criteria

- Every Intent Spec success criterion is PASS or recorded as explicit deferral with rationale.
- Observation evidence (logs / screenshots / metrics) is preserved.
- `validation-report.md`, any `validation-evidence/*`, and `progress.yaml` are committed.
- The CI run linked to this step's completion commit has passed (with up to 2 retry attempts; otherwise the failure is escalated to a Blocker per `share-ci-monitoring`).

## Gate

User approval (mandatory).

## Failure modes / Rollback

| Cause | Action / Target step |
| ----- | -------------------- |
| Implementation bug surfaces in measurement | Roll back to Step 6 (Implementation). |
| Design error surfaces (the design cannot satisfy the criterion) | Roll back to Step 3 (Design). |
| Success criterion itself is unfit | Roll back to Step 1 (Intent Clarification). |
| QA design gap (missing TC for a failing criterion) | Roll back to Step 4 (QA Design). |
| Measurement procedure is inappropriate | Send feedback to the **same** `validator` instance to revise the procedure. |
| Validation scope expands | Launch an additional `validator` in parallel (existing instance stays alive). |

## Commit conventions

- `docs(dev-workflow/<identifier>): complete Step 8 (Validation)`.

## Parallelism notes

Single instance by default. If the scope genuinely expands (e.g. multiple independent measurement tracks), Main may launch additional `validator` instances; existing instances are not terminated mid-step.

## Sub-agent invocation rule reminder

Per the README "Sub-agent invocation rules", only Main launches additional or replacement `validator` specialists. A running `validator` reports a Blocker rather than spawning a peer or invoking an `implementer` / `reviewer` to re-run their work. If evidence is missing because of someone else's work, the validator surfaces a Blocker; Main coordinates the response.
