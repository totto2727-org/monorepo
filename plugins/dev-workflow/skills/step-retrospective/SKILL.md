---
name: step-retrospective
description: >
  [Main coordinator] Detail skill for dev-workflow Step 9 (Retrospective). Read
  this when starting Step 9 of dev-workflow, when the user asks to "wrap up the
  cycle with a retrospective" or to "produce docs/retrospective/<id>.md". This
  is a Main-only step: Main reviews every artifact, the progress log, blockers,
  loop counts, and gate history to write a retrospective note for the next
  cycle. The note is **volatile** — it is deleted when the next cycle digests
  the improvements; durable decisions migrate to ADRs via `share-adr`. Trigger
  phrases: "starting Step 9 of dev-workflow", "retrospective step",
  "produce retrospective.md".
  Do NOT use for: validation (`step-validation`), per-cycle artifact format
  (`share-artifacts/references/retrospective.md`), roadmap-level retrospective
  (`step-roadmap-retrospective`), or any non-retrospective summary.
---

# Step 9: Retrospective

## Purpose

Aggregate the cycle's learnings — what worked, what did not, concrete next-cycle improvements, and reusable knowledge — into a single retrospective note. The note is a deliberately volatile improvement bin; durable decisions are migrated to ADRs.

## Invocation

**Main only.** No specialist is launched. Justifications:

- The work is aggregation across already-produced artifacts; context isolation does not help.
- A single coherent narrative is needed; parallelism would fragment the analysis.
- No independent-viewpoint requirement: Main has full context already.

## Required inputs from Main

- The full set of cycle artifacts (`intent-spec.md`, `research/*.md`, `design.md`, `qa-design.md`, `qa-flow.md`, `task-plan.md`, `TODO.md`, all diffs, `review/*.md`, `validation-report.md`, any filed ADRs).
- `docs/workflow/<identifier>/progress.yaml` (especially `blockers[]`, `rollbacks[]`, `user_approvals[]`, `re_activations`).
- Round counts for the Step 6 ↔ Step 7 round-trip and any re-entry history.
- Any `$TMPDIR/dev-workflow/<identifier>-*.md` In-Progress inquiry reports retained for analysis.
- `share-artifacts/references/retrospective.md` and `share-artifacts/templates/retrospective.md`.

## Procedure

1. Re-read the full artifact set listed above to reconstruct the cycle narrative.
2. Identify "what went well", "issues", "next-cycle improvements", and "reusable knowledge". Make each entry concrete (specific episode, file path, or commit SHA).
3. Save as `docs/retrospective/<identifier>.md` (note: this is **outside** `docs/workflow/<identifier>/`; the retrospective is a cycle-external aggregation directory mirroring the `docs/adr/` pattern).
4. Update `progress.yaml` to `status: completed` (cycle final commit).
5. If the cycle is part of a roadmap (`progress.yaml.roadmap.id` is set), apply the cycle-completion update to `docs/roadmap/<roadmap-id>/roadmap-progress.yaml` (`milestones[].status: active → completed`, `updated_at`) per the `roadmap-progress.yaml` update protocol in `dev-workflow/SKILL.md` and bundle that change in the same final commit.
6. Inform the user. There is no user approval gate at this step (Main judgment).

## Artifact lifecycle

`docs/retrospective/<identifier>.md` is **volatile**:

- Treat it as an improvement bin for the **next cycle** to digest.
- Once the next cycle ingests the recommended changes, the file is deleted.
- Decisions that must persist (cross-cycle architectural choices, project-wide norms) are migrated to an ADR via `share-adr`:
  - **ADR (permanent)** — `docs/adr/<file>.md` (General mode) or `docs/roadmap/<roadmap-id>/adr/<file>.md` (Roadmap mode).
  - **`docs/retrospective/<identifier>.md` (volatile)** — improvement-bin only; deleted once digested.

The split is intentional: not every retrospective insight deserves immortality, and ADRs should remain a curated record of decisions, not a backlog of suggestions.

## Expected artifacts

- `docs/retrospective/<identifier>.md` — populated from `share-artifacts/templates/retrospective.md`, following `share-artifacts/references/retrospective.md`.
- `docs/workflow/<identifier>/progress.yaml` — `status: completed` (final commit of the cycle).
- (Conditional) `docs/roadmap/<roadmap-id>/roadmap-progress.yaml` — milestone state transitioned to `completed` for roadmap-linked cycles.

## Exit criteria

- `docs/retrospective/<identifier>.md` and the final `progress.yaml` are committed (cycle-final commit).
- The retrospective note is in the location and naming the next cycle can find.
- For roadmap-linked cycles, `roadmap-progress.yaml` shows the milestone transitioned to `completed` and is committed in the same final commit.
- The CI run linked to this step's completion commit has passed (with up to 2 retry attempts; otherwise the failure is escalated to a Blocker per `share-ci-monitoring`).

## Gate

Main judgment (the user is informed but no explicit approval is required).

## Failure modes / Rollback

| Cause                                             | Action / Target step                                                                                                                                                                      |
| ------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| The retrospective is too abstract                 | Re-author inside Step 9 (Main only — no specialist to feed back to); demand concrete episodes (file path, commit SHA, round number).                                                      |
| Next-cycle improvements are not actionable        | Decompose to action-level bullet points and rewrite.                                                                                                                                      |
| A retrospective insight clearly merits permanence | File an ADR (General or Roadmap mode per `share-adr/SKILL.md`) and reference the ADR from the retrospective note; the note still gets deleted on next-cycle digest, but the ADR persists. |

## Commit conventions

- `docs(dev-workflow/<identifier>): close cycle with retrospective` — final commit (volatile retrospective note + final `progress.yaml`).
- For roadmap-linked cycles: `docs(dev-workflow/<identifier>): close cycle with retrospective (completed milestone <milestone-id> in roadmap <roadmap-id>)`.

## Parallelism notes

Not applicable. Single Main-driven aggregation.

## Sub-agent invocation rule reminder

Not applicable — no specialist is launched in this step.
