---
name: step-task-decomposition
description: >
  [Main coordinator] Detail skill for dev-workflow Step 5 (Task Decomposition).
  Read this when starting Step 5 of dev-workflow, when the user asks to "break
  the design into implementable tasks" or to "produce task-plan.md". This is a
  Main-only step: Main personally decomposes `design.md` into implementer-sized
  tasks (each completable by a single `implementer` in hours to one day),
  records them in an immutable `task-plan.md`, and prepares the dependency
  graph plus parallel waves. Trigger phrases: "starting Step 5 of dev-workflow",
  "task decomposition step", "produce task-plan.md".
  Do NOT use for: implementation (`step-implementation`), test design
  (`step-qa-design`), in-step task tracking (Main maintains `TODO.md`), or any
  other artifact than `task-plan.md`.
---

# Step 5: Task Decomposition

## Purpose

Decompose `design.md` into tasks small enough for a single `implementer` to complete (typically a few hours up to one day), record them in an immutable `task-plan.md` together with a dependency graph and parallel waves, and obtain user approval to start implementation.

## Invocation

**Main only.** No specialist is launched. Justifications:

- The input set (`design.md` + `intent-spec.md`) is small relative to other steps — context isolation is unnecessary.
- A single coherent decomposition is required; parallelism would split the dependency graph.
- No independent-viewpoint requirement: Main is preparing the work plan, not evaluating finished artifacts.

## Required inputs from Main

- `docs/workflow/<identifier>/design.md`.
- `docs/workflow/<identifier>/intent-spec.md`.
- `docs/workflow/<identifier>/qa-design.md` (optional cross-link target — TC-IDs may be referenced from tasks but task definition does not depend on test design).
- `share-artifacts/references/task-plan.md` and `share-artifacts/templates/task-plan.md`.

## Procedure

1. Read `design.md` and identify implementable units (component / module / feature slice).
2. For each unit, write a task entry: ID, summary, deliverables, dependencies, parallelism flag, estimated size.
3. Build the dependency graph and group independent tasks into parallel waves.
4. Verify that each task is completable by a single `implementer` in hours to one day. Re-decompose anything that exceeds this budget.
5. Save as `docs/workflow/<identifier>/task-plan.md`. **Treat this file as immutable from this point forward** — Step 6 must add new tasks only via the `TODO.md` "late-added" section, never by editing `task-plan.md`.
6. Present `task-plan.md` directly to the user (Artifact-as-Gate-Review) and request approval to start implementation.
7. On approval, commit `task-plan.md` + `progress.yaml` in one commit.

## Expected artifacts

- `docs/workflow/<identifier>/task-plan.md` — populated from `share-artifacts/templates/task-plan.md`, following `share-artifacts/references/task-plan.md`. Immutable for the rest of the cycle.
- `docs/workflow/<identifier>/progress.yaml` — updated.

## Exit criteria

- Each task is completable by a single `implementer` in hours to one day.
- Inter-task dependencies are explicitly graphed.
- Independent tasks (parallel waves) are identified.
- `task-plan.md` and `progress.yaml` are committed.
- The CI run linked to this step's completion commit has passed (with up to 2 retry attempts; otherwise the failure is escalated to a Blocker per `share-ci-monitoring`).

## Gate

User approval (mandatory) — this gate is the explicit "go-ahead to start implementation".

## Failure modes / Rollback

| Cause | Action / Target step |
| ----- | -------------------- |
| Task granularity is wrong | Re-decompose inside Step 5 (Main only — no specialist to feed back to). |
| Dependencies are unresolvable | Roll back to Step 3 (Design) for design adjustment. |
| Test design and task list cannot align | Roll back to Step 4 (QA Design) only if QA cannot be salvaged; otherwise note the cross-references in `task-plan.md` and continue. |

## Commit conventions

- `docs(dev-workflow/<identifier>): complete Step 5 (Task Decomposition)`.

## Parallelism notes

Not applicable. A single Main-driven decomposition is the entire procedure.

## Pre-Step-6 task list mirroring (mandatory)

`task-plan.md` is immutable. Before Step 6 begins, the running task state must be mirrored to **two** locations:

1. **Main's internal task list (in-session):** registered via `TaskCreate`; updated via `TaskUpdate` (`pending` → `in_progress` → `completed`). This is volatile.
2. **Persistent task list `docs/workflow/<identifier>/TODO.md`:** generated from `task-plan.md` at Step 6 start (all tasks `status: pending`). Format details: `share-artifacts/references/todo.md` + `share-artifacts/templates/TODO.md`.

`TODO.md` is the source of truth (persistent layer); `TaskCreate` is its in-session view (volatile layer). State changes flow as `TODO.md → commit → TaskUpdate`. Detailed Step 6 operation rules live in `step-implementation`.

## Sub-agent invocation rule reminder

Not applicable — no specialist is launched in this step.
