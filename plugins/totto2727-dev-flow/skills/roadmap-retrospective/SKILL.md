---
name: roadmap-retrospective
description: >
  [Main only] roadmap Step 4 (Roadmap Retrospective). Aggregate the retrospectives of
  all downstream workflow-level executions, evaluate milestone achievement and dependency-graph
  validity, capture roadmap-specific improvements, and finalise
  `docs/retrospective/roadmap-<roadmap-id>.md`. Transition the roadmap-wide status to
  `completed`. Main authors the aggregate retrospective directly; no specialist subagent is
  invoked.
  Activation triggers: "Roadmap Retrospective", "roadmap retrospective", "create
  roadmap-<roadmap-id>.md", "close the roadmap", "roadmap Step 4".
  Do NOT use for: per-execution retrospective owned by a workflow-level execution system,
  roadmap intent (`roadmap-intent`), milestone decomposition
  (`roadmap-decomposition`), implementation/validation of downstream executions (each execution
  owns its own process), CLAUDE.md updates (only proposed candidates, never written from this
  step).
---

# Roadmap Step 4: Roadmap Retrospective

## Purpose

Close out the roadmap. Summarise milestone achievement, evaluate the validity of the
dependency graph, aggregate the retrospectives of all downstream workflow-level executions
into one summary section, capture roadmap-specific improvements (schema-extension ideas
for `progress.yaml`, finer-grained progress tracking, etc.), and transition the
roadmap-wide `status` to `completed`.

## Invocation: Main only

This step is **Main-only**: no specialist subagent is invoked.

- **Aggregation work**: this is a single-pass synthesis across all downstream execution
  retrospectives. There is no parallelism to fan out.
- **No context-isolation justification**: the inputs (roadmap artifacts and one
  retrospective or summary per downstream execution) usually fit comfortably in Main's window. If the
  number of executions is large, Main reads them sequentially rather than spawning a
  specialist.
- **No independent-viewpoint justification**: this is a self-evaluation of the roadmap
  itself; there is no separate evaluator role (the user reads the result, but the gate
  is Main judgment).

Main therefore performs all the procedure below directly. No `agents/<role>.md` wrapper
exists for this step.

## Required inputs from Main

- `roadmap.md` (Intent section + milestone decomposition + dependency graph).
- `progress.yaml` with all milestones in their final state (`completed` or
  `cancelled`) and `workflow_identifiers[]` populated when delegated executions exist.
- For every `<identifier>` in `milestones[].workflow_identifiers[]`:
  - Any retained delegated execution artifacts or summaries linked from milestone notes.
  - The execution's retrospective or summary, when one is retained.
- Path of `share-artifacts/templates/roadmap-retrospective.md` and
  `share-artifacts/references/roadmap-retrospective.md` (writing guide).

If any item is missing, Main confirms with the user before starting work.

## Procedure

1. Confirm every `milestones[].status` is `completed` or `cancelled`. If any delegated execution's
   retrospective is missing, fall back to Step 3 (await cycle completion) — see
   "Failure modes" below.
2. Read all available per-execution retrospectives `docs/retrospective/<identifier>.md` to gather
   delegated execution insight.
3. Copy `share-artifacts/templates/roadmap-retrospective.md` to
   `docs/retrospective/roadmap-<roadmap-id>.md` and fill in following
   `share-artifacts/references/roadmap-retrospective.md`. Cover at minimum:
   - Milestone achievement summary.
   - Dependency-graph validity reflection.
   - One paragraph per downstream execution aggregating its retrospective.
   - Roadmap-specific improvements (e.g. proposed `progress.yaml` schema
     extensions, the case for finer-grained progress reporting, parallel-execution
     operational lessons, specialist-launch-count observations, etc.).
4. Use the roadmap CLI to set the roadmap-wide `status` to `completed` and refresh
   `updated_at` in `progress.yaml`.
5. If long-lived insights worth permanent recording surface during retrospective,
   propose extracting them into ADRs (Main's judgment):
   - **Roadmap mode** (`docs/roadmap/<roadmap-id>/adr/`) when the insight stays inside
     this roadmap.
   - **General mode** (`docs/adr/`) when the insight will impact other roadmaps or
     independent workflows. Link from the retrospective to the new ADR.
     See `share-adr/SKILL.md`.
6. Present the finished `docs/retrospective/roadmap-<roadmap-id>.md` to the user (for
   information only — the gate is Main judgment, not user approval).
7. Commit the artifacts as the roadmap's final commit.

## Expected artifacts

- `docs/retrospective/roadmap-<roadmap-id>.md` — aggregated retrospective.
  Note the `roadmap-` prefix avoids collision with per-execution retrospectives in the same
  directory.
  Template: `share-artifacts/templates/roadmap-retrospective.md`.
  Reference: `share-artifacts/references/roadmap-retrospective.md`.
- `docs/roadmap/<roadmap-id>/progress.yaml` — `status: completed`, `updated_at`
  refreshed.
  Managed by the roadmap CLI.
- (Optional) ADR(s) extracted from retrospective insights, in either mode per
  `share-adr/SKILL.md`.

## Exit criteria

- A milestone-achievement summary is recorded.
- A reflection on dependency-graph validity is recorded.
- Each downstream workflow-level execution retrospective or summary is aggregated into at least one
  paragraph.
- Roadmap-specific improvements are recorded (e.g. `progress.yaml` schema
  proposals, the need for step-level progress reporting, etc.).
- `docs/retrospective/roadmap-<roadmap-id>.md` is committed; `progress.yaml` is
  updated to `status: completed` and committed (this is the roadmap's final commit).
- Any CI / PR verification required by the surrounding execution system has completed;
  detailed CI handling is delegated to that system.

## Gate

**Main judgment.** The user is shown the finished retrospective for information only;
no explicit user-approval gate is required. If a Roadmap mode / General mode ADR is
extracted from the retrospective, that ADR has its own approval flow per
`share-adr/SKILL.md`.

## Failure modes / Rollback

These rollbacks originate from this step:

- **The retrospective body stays too abstract** (no concrete episodes, no Blocker
  references, no parallel-cycle operational lessons) → Main rewrites with concrete
  evidence within the step (no specialist to "send back to").
- **One or more downstream cycle retrospectives are missing** (i.e. a cycle did not
  complete its own Step 9) → Roll back to Step 3 (Execution): wait for the cycle to
  finish, then return here.

Cross-step rollbacks beyond Step 3 are not initiated from this step (Step 4 is the
final step).

## Commit conventions

One commit at step completion, containing the retrospective and the
`progress.yaml` transition. Recommended message format (project-specific commit
conventions take precedence):

```
docs(roadmap/<roadmap-id>): close roadmap with retrospective
```

Stage files explicitly by path (do not use `git add .` / `git add -A`).

## Sub-agent invocation reminder

This step is Main-only. **Main does the work directly without launching a `specialist-*`
subagent.** Main may freely orchestrate other specialists in subsequent steps (there are
none; this is the final step), but inside this step there is no nested specialist work.
