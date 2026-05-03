---
name: step-qa-design
description: >
  [Main coordinator] Detail skill for dev-workflow Step 4 (QA Design). Read this
  when starting Step 4 of dev-workflow, when the user asks to "design tests for
  the success criteria" or to "produce qa-design.md / qa-flow.md". Defines how
  Main launches `qa-analyst` × 1 to expand the Intent Spec success criteria into
  framework-agnostic test cases (TC-NNN) and a Mermaid flow chart whose leaves
  map to TC IDs. Trigger phrases: "starting Step 4 of dev-workflow", "qa design
  step", "produce qa-design.md".
  Do NOT use for: implementation-time test additions (those are TC-IMPL added by
  Step 6 implementer), test execution (`step-validation`), specialist internals
  (`specialist-qa-analyst`), or artifact format details
  (`share-artifacts/references/qa-design.md`, `share-artifacts/references/qa-flow.md`).
---

# Step 4: QA Design

## Purpose

Convert each Intent Spec success criterion into an observable test case (TC-NNN) plus a Mermaid branch diagram (`qa-flow.md`) whose leaves are TC IDs (or `skip` with rationale). Each TC carries an Execution-subject × Verification-style 2-axis tag and is described at a framework-agnostic level (no Vitest / Playwright specifics).

## Invocation

**Specialist:** `qa-analyst` × 1.

**Justification:**

- **Context isolation (C):** the analyst absorbs Intent Spec, design, and project-specific testing skills (e.g. `vite-plus`, `effect-*`, `moonbit-bestpractice`) — a substantial input set best held in a dedicated context. A single instance preserves coverage consistency.

## Required inputs from Main

- `docs/workflow/<identifier>/intent-spec.md`.
- `docs/workflow/<identifier>/design.md`.
- `share-artifacts/references/qa-design.md` and `share-artifacts/templates/qa-design.md`.
- `share-artifacts/references/qa-flow.md` and `share-artifacts/templates/qa-flow.md`.
- Project-specific testing skills (Main passes paths; `qa-design.md` itself stays at the abstract 2-axis level).

## Procedure

1. Launch `qa-analyst` × 1 with the inputs above. Be explicit that test framework selection is a project-specific concern and `qa-design.md` must remain framework-agnostic.
2. Specialist deepens the success criteria into a TC-NNN table and authors `qa-flow.md` (Mermaid flowchart blocks; each leaf carries a TC-ID or `skip [reason]`).
3. Receive the artifacts and present them directly to the user (Artifact-as-Gate-Review). No temporary summary report.
4. Iterate on the same `qa-analyst` instance until both artifacts pass the gate.
5. Commit `qa-design.md` + `qa-flow.md` + `progress.yaml` in one commit.

## Expected artifacts

- `docs/workflow/<identifier>/qa-design.md` — essential test section (TC-NNN), implementation-incidental section (TC-IMPL-NNN, left empty by `qa-analyst`; populated by `implementer` in Step 6), coverage table, 2-axis enum tags. Source: `share-artifacts/templates/qa-design.md` + `share-artifacts/references/qa-design.md`.
- `docs/workflow/<identifier>/qa-flow.md` — Mermaid flowchart blocks for the essential logic; each leaf is a TC-ID or `skip [reason]`. Source: `share-artifacts/templates/qa-flow.md` + `share-artifacts/references/qa-flow.md`.
- `docs/workflow/<identifier>/progress.yaml` — updated.

## Exit criteria

- Every success criterion is covered by at least one TC-NNN (verified via the coverage table).
- Any TC marked "Target success criterion = (none)" has a documented justification.
- Every TC has its 2-axis enum tags filled (Execution-subject × Verification-style).
- The forbidden combination `automated × inspection` is not used.
- Every leaf in `qa-flow.md` is either a TC-ID or `skip [reason]`.
- The user has approved both `qa-design.md` and `qa-flow.md`.
- `qa-design.md` + `qa-flow.md` + `progress.yaml` are committed.
- The CI run linked to this step's completion commit has passed (with up to 2 retry attempts; otherwise the failure is escalated to a Blocker per `share-ci-monitoring`).

## Gate

User approval (mandatory).

## Failure modes / Rollback

| Cause                                                          | Action / Target step                                                                       |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Discovered an unobservable success criterion                   | Roll back to Step 1 (Intent Clarification).                                                |
| `design.md` cannot pin down the behavior enough to write tests | Roll back to Step 3 (Design).                                                              |
| Insufficient material to choose automated vs manual            | Consult Main / `architect`; remain in Step 4.                                              |
| A success criterion has zero corresponding TCs                 | Roll back to Step 1 (likely combination of test-design gap and unclear success criterion). |

## Notes

- `qa-analyst` only authors essential tests (TC-NNN). Implementation-incidental tests (TC-IMPL-NNN) are appended later by `implementer` in Step 6 — they remain blank here.
- `qa-flow.md`'s Mermaid diagram covers both essential and implementation-incidental tests; the prefix on the TC-ID is enough to distinguish them.
- Detailed format rules belong to `share-artifacts/references/qa-design.md` and `qa-flow.md`; this step does not duplicate them.

## Commit conventions

- `docs(dev-workflow/<identifier>): complete Step 4 (QA Design)`.

## Parallelism notes

Single instance only. Coverage consistency dominates; parallel analysts would produce overlapping or conflicting TCs.

## Sub-agent invocation rule reminder

Per the README "Sub-agent invocation rules", only Main launches additional or replacement specialists. A running `qa-analyst` reports a Blocker rather than spawning a peer.
