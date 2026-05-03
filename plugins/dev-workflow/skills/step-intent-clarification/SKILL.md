---
name: step-intent-clarification
description: >
  [Main coordinator] Detail skill for dev-workflow Step 1 (Intent Clarification).
  Read this when starting Step 1 of dev-workflow, when the user asks to "clarify intent",
  "produce an intent spec", or "start a new dev-workflow cycle". Defines the Main-only
  procedure for converting an initial user request into a committed `intent-spec.md`
  artifact with observable success criteria. Trigger phrases: "starting Step 1 of
  dev-workflow", "intent clarification step", "produce intent-spec.md".
  Do NOT use for: subsequent steps (see `step-research` / `step-design` / etc.),
  pure artifact format questions (see `share-artifacts/references/intent-spec.md`),
  or roadmap-level intent (see `step-roadmap-intent`).
---

# Step 1: Intent Clarification

## Purpose

Translate the user's raw request into a committed Intent Spec that captures scope, non-scope, observable success criteria, and constraints, so every later step has a single source of truth for "what we are building and how we will know it succeeded".

## Invocation

**Main only.** No specialist is launched. Justifications for keeping this Main-driven:

- The dialogue with the user is best handled by Main directly (no context isolation issue).
- A single instance is sufficient (no parallelism need).
- No independent-viewpoint requirement: Main is gathering raw intent, not evaluating finished work.

## Required inputs from Main

- The initial user request (free-form description).
- A summary of current repository state relevant to the request.
- The path of the cycle directory `docs/workflow/<identifier>/` and the initialized `progress.yaml`.
- `share-artifacts/references/intent-spec.md` and `share-artifacts/templates/intent-spec.md` for format guidance.

## Procedure

1. Confirm the cycle `<identifier>` and that `docs/workflow/<identifier>/` and `progress.yaml` are initialized (if not, initialize per `dev-workflow/SKILL.md` "session start" rules).
2. Engage the user in a clarifying dialogue: ask about the underlying problem, distinguish symptoms from goals, surface unstated constraints, and list candidate non-scope items explicitly.
3. Draft `intent-spec.md` filling the template sections: background, purpose, scope, non-scope, success criteria, constraints. Each success criterion must be **observable** (e.g. "p95 < 200ms" rather than "feels faster").
4. Present the populated `intent-spec.md` to the user and request approval. Do **not** create a separate summary report — the artifact itself is the gate-review material (Artifact-as-Gate-Review).
5. On approval, commit `intent-spec.md` together with the updated `progress.yaml` and trigger the PR/CI pipeline per the top-tier trigger table.
6. If the user is ambiguous, repeat the dialogue (no specialist involved). If a success criterion cannot be made observable, surface this via In-Progress user inquiry (temporary report under `$TMPDIR/dev-workflow/step1-*.md`).

## Expected artifacts

- `docs/workflow/<identifier>/intent-spec.md` — produced from `share-artifacts/templates/intent-spec.md`, following `share-artifacts/references/intent-spec.md`.
- `docs/workflow/<identifier>/progress.yaml` — updated with this step's completion (`completed_steps`, `artifacts.intent_spec`, `updated_at`).

## Exit criteria

- Scope and non-scope are explicitly documented.
- Every success criterion is written in observable form (measurable signal, threshold, or check).
- The user has approved the Intent Spec.
- `intent-spec.md` and the updated `progress.yaml` are committed.
- The CI run linked to this step's completion commit has passed (with up to 2 retry attempts; otherwise the failure is escalated to a Blocker per `share-ci-monitoring`).

## Gate

User approval (mandatory). Approval is given against the Intent Spec artifact itself; no temporary summary report is created.

## Failure modes / Rollback

| Cause                                       | Action / Target step                                                                                                  |
| ------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| User answers remain ambiguous               | Continue dialogue inside Step 1 (no rollback).                                                                        |
| Success criterion cannot be made observable | Negotiate measurement strategy with the user via In-Progress inquiry; remain in Step 1 until criteria are observable. |
| User rejects the Intent Spec at the gate    | Capture the rejection reason in `progress.yaml`, refine the artifact, re-present.                                     |

This step is the root of the workflow; it has no upstream rollback target.

## Commit conventions

- `docs(dev-workflow/<identifier>): initialize cycle` (cycle bootstrap commit, may already exist).
- `docs(dev-workflow/<identifier>): complete Step 1 (Intent Clarification)`.
- `docs(dev-workflow/<identifier>): record user approval for Step 1` (if approval lands in a separate commit).

When the cycle is launched from a roadmap milestone, append the linkage marker:
`docs(dev-workflow/<identifier>): initialize cycle (linked to roadmap <roadmap-id> milestone <milestone-id>)`.

## Parallelism notes

Not applicable. A single Main-driven dialogue is the entire procedure.

## Session resume note

When resuming an interrupted Step 1: re-read the existing `intent-spec.md` (if any), re-load `progress.yaml`, and continue the dialogue from the last unanswered question recorded in `progress.yaml.blockers` or in the partial draft.
