---
name: step-research
description: >
  [Main coordinator] Detail skill for dev-workflow Step 2 (Research). Read this
  when starting Step 2 of dev-workflow, when the user asks to "investigate
  existing code / dependencies / similar prior art" before designing, or when
  Main needs to launch parallel `researcher` specialists across multiple angles.
  Defines the contract Main uses to invoke `researcher` × N in parallel and how
  to collect the resulting Research Notes. Trigger phrases: "starting Step 2 of
  dev-workflow", "research step", "launch researcher specialists".
  Do NOT use for: design work (`step-design`), specialist internals
  (`specialist-researcher`), or artifact format details
  (`share-artifacts/references/research-note.md`).
---

# Step 2: Research

## Purpose

Survey existing code, dependencies, ADRs, and external constraints across multiple angles in parallel so the upcoming Design step has a verified factual base. Each angle is captured as one Research Note authored by an isolated `researcher` instance.

## Invocation

**Specialist:** `researcher` × N (one per research angle, launched in parallel by Main).

**Justifications:**

- **Parallelism (P):** angles are independent and benefit from concurrent execution.
- **Context isolation (C):** each angle may pull in large amounts of code or external material that would otherwise crowd out Main's working context.

## Required inputs from Main

- `docs/workflow/<identifier>/intent-spec.md` (approved in Step 1).
- The list of research angles Main has derived from the Intent Spec (e.g. existing implementation, dependency graph, prior art, related ADRs, external specifications).
- For each `researcher`: its single assigned angle, the expected Note path, and the linked references.
- `share-artifacts/references/research-note.md` and `share-artifacts/templates/research-note.md`.
- Any project-specific skills relevant to the angle (Main passes paths into the specialist input).

## Procedure

1. Derive the research angles from `intent-spec.md`. One angle per `researcher` instance.
2. For each angle, launch a `researcher` specialist in parallel with explicit scope (this angle only), the input artifacts above, and the expected output path `docs/workflow/<identifier>/research/<topic>.md`.
3. While specialists run, do not interfere mid-task; wait for return.
4. Aggregate all Research Notes once returned. Cross-check coverage against `intent-spec.md` constraints.
5. If an angle was missed, **launch an additional `researcher` in parallel** (do not reuse a finished instance and do not have an existing specialist spawn one).
6. If a returned Note lacks depth, send the same `researcher` instance feedback (no replacement) until Step 2 completes; the instance is retired only when the step exits.
7. Record any unresolved unknowns explicitly as Blockers in `progress.yaml.blockers` (residual unknowns are allowed but must be visible).
8. Commit all Research Notes together with the updated `progress.yaml` (one commit for the whole step).

## Expected artifacts

- `docs/workflow/<identifier>/research/<topic>.md` — one per angle, following `share-artifacts/references/research-note.md`, populated from `share-artifacts/templates/research-note.md`.
- `docs/workflow/<identifier>/progress.yaml` — `completed_steps`, `artifacts.research_notes[]`, blockers updated.

## Exit criteria

- All Intent Spec constraints are corroborated by at least one Research Note.
- Connection points and conflict points with the existing codebase are enumerated.
- Unresolved unknowns are recorded as Blockers (presence is acceptable; invisibility is not).
- All Research Notes and the updated `progress.yaml` are committed.
- The CI run linked to this step's completion commit has passed (with up to 2 retry attempts; otherwise the failure is escalated to a Blocker per `share-ci-monitoring`).

## Gate

Main judgment. User confirmation is optional and is requested only when a Blocker materially affects scope (via In-Progress user inquiry under `$TMPDIR/dev-workflow/step2-*.md`).

## Failure modes / Rollback

| Cause | Action / Target step |
| ----- | -------------------- |
| Granularity insufficient on a single angle | Send feedback to the same `researcher` instance for deeper investigation (no replacement). |
| A research angle is missing | Main launches an additional `researcher` in parallel; existing instances stay alive until Step 2 exits. |
| Findings contradict the Intent Spec at the root | Roll back to Step 1 (Intent Clarification). All `researcher` instances retire at the step exit. |

## Commit conventions

- `docs(dev-workflow/<identifier>): complete Step 2 (Research)` — covers all Research Notes and the `progress.yaml` update in a single commit.

## Parallelism notes

- Each `researcher` instance is dedicated to a single angle. Do not multiplex angles inside one specialist.
- Additional `researcher` instances may be added inside Step 2; existing instances must not be terminated until Step 2's Exit Criteria are met.
- If a running `researcher` discovers a need for a different angle, it must report a Blocker — it must not spawn a peer specialist.

## Sub-agent invocation rule reminder

Per the README "Sub-agent invocation rules", only Main launches additional or replacement `researcher` specialists. A running `researcher` that needs another angle reports a Blocker rather than invoking a peer.
