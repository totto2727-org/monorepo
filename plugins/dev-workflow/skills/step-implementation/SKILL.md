---
name: step-implementation
description: >
  [Main coordinator] Detail skill for dev-workflow Step 6 (Implementation). Read
  this when starting Step 6 of dev-workflow, when the user asks to "begin
  implementation" or to "launch parallel implementer specialists for the
  approved task plan". Defines how Main launches `implementer` × N (one per
  task) in parallel, how `TODO.md` and the in-session `TaskCreate` list stay
  in sync, and how the Step 6 ↔ Step 7 round-trip re-activates implementation
  for review-driven Blockers / Major findings. Trigger phrases: "starting Step
  6 of dev-workflow", "implementation step", "launch implementer specialists".
  Do NOT use for: external review (`step-external-review`), validation
  (`step-validation`), specialist internals (`specialist-implementer`), or
  artifact format details (`share-artifacts/references/todo.md`,
  `implementation-log.md`).
---

# Step 6: Implementation

## Purpose

Implement the approved Task Plan as commit-sized diffs, one task per `implementer` instance, while keeping `TODO.md` (persistent) and `TaskCreate` (in-session) synchronized so the work survives session boundaries.

## Invocation

**Specialist:** `implementer` × N (one per task, launched in parallel for independent tasks).

**Justifications:**

- **Parallelism (P):** independent tasks can progress concurrently.
- **Context isolation (C):** each task pulls in code areas that would otherwise crowd Main's working context.

## Required inputs from Main (per `implementer`)

- The single task ID assigned to this `implementer` and the matching section of `task-plan.md`.
- Relevant excerpts of `design.md`.
- `intent-spec.md` (scope and non-scope).
- Output paths and commit conventions.
- Test additions policy (link to `qa-design.md` and `qa-flow.md`; `implementer` populates TC-IMPL-NNN).
- Project-specific skills paths (e.g. `effect-layer`, `effect-hono`, `effect-runtime`, `totto2727-fp`, `git-workflow`, `macos-cli-rules`) — these dominate over workflow defaults for implementation pattern, naming, and commit conventions.

## Prerequisites

`TODO.md` and `TaskCreate` must be initialized from `task-plan.md` at Step 6 start (per `step-task-decomposition` "Pre-Step-6 task list mirroring"). All tasks begin as `status: pending`.

## Procedure

1. From `TODO.md`, identify launchable tasks (dependency-graph roots / independent tasks with `status: pending`).
2. For each task to be launched, update its status to `in_progress` in `TODO.md` (record `started_at` and the `implementer` ID). Commit. Then mirror the change via `TaskUpdate`.
3. Launch one `implementer` per independent task in parallel (each specialist owns exactly one task). Pass the per-implementer inputs above.
4. Sequential tasks wait for their dependencies to complete before launch.
5. As each `implementer` returns its diff and operational notes, aggregate the result.
6. On task completion, update `TODO.md`: `[ ]` → `[x]`, record `completed_at` and `commit` SHA. Commit. Then mirror via `TaskUpdate` to `completed`.
7. Main directs lint / type-check / existing-test runs as required (the responsibility is set explicitly when launching the specialist).
8. Repeat until all tasks in `TODO.md` are `[x] completed`.

## TODO.md / TaskCreate synchronization rules

- `TODO.md` is the **source of truth** (persistent). `TaskCreate` is the in-session view (volatile).
- State transitions flow as `TODO.md → commit → TaskUpdate`.
- Update on every state change: launch (`pending` → `in_progress`), completion (`in_progress` → `[x] completed`), re-activation by review (see Step 6 ↔ Step 7 round-trip below).
- `task-plan.md` stays immutable through Step 6. Late-added tasks go into a dedicated "late-added" section of `TODO.md`, with a reason recorded at the top of the file. Frequent late-additions suggest rolling back to Step 5.
- Format details: `share-artifacts/references/todo.md` + `share-artifacts/templates/TODO.md`.

## Step 6 ↔ Step 7 round-trip mechanism (summary)

External Review (Step 7) may emit Blocker or Major findings that re-activate Step 6. Main re-flips the affected task in `TODO.md` from `[x]` back to `[ ]` with `status: in_progress`, increments `re_activations`, commits, and launches a **new** `implementer` for the fix. The previous round's `implementer` has already retired at the Step 6 exit and is not reused. After the fix completes, Step 6 exits again and a **new** `reviewer` cohort is launched in Step 7's next round. Detailed round-trip rules live in `step-external-review`.

## Expected artifacts

- Per-task diff (Git commits, one per task).
- `docs/workflow/<identifier>/TODO.md` — updated at each state change. Source: `share-artifacts/references/todo.md` + `share-artifacts/templates/TODO.md`.
- (Conditional) `docs/workflow/<identifier>/implementation-logs/<task-id>.md` — when operational notes are too large for `progress.yaml`. Source: `share-artifacts/references/implementation-log.md` + `share-artifacts/templates/implementation-log.md`.
- (Conditional) `docs/workflow/<identifier>/qa-design.md` — `implementer` appends TC-IMPL-NNN entries.
- (Conditional) `docs/workflow/<identifier>/qa-flow.md` — `implementer` updates leaf TC mappings.
- `docs/workflow/<identifier>/progress.yaml` — `completed_steps`, `artifacts.implementation_logs[]`, `artifacts.commits[]` updated at the step exit.

## Exit criteria

- Every task in `TODO.md` is `[x] completed`.
- Type check, lint, and existing tests pass.
- New tests are added per task (or absence is justified inline).
- Each diff conforms to `design.md` decisions.
- Per-task commits exist in the repository (Step 6 produces multiple commits, one per task).
- `TODO.md` and `progress.yaml` are committed in their final state.
- The CI run linked to **each** task-level completion commit has passed (with up to 2 retry attempts per commit; otherwise the failure is escalated to a Blocker per `share-ci-monitoring`).

## Gate

Main judgment.

## Failure modes / Rollback

| Cause | Action / Target step |
| ----- | -------------------- |
| A specific task's `implementer` returns an unexpected result | Send feedback to that **same** `implementer` instance (no replacement until Step 6 exits). Keep the `TODO.md` row at `in_progress`. |
| Insufficient task count for the work that turned up | Launch additional `implementer` instances in parallel (existing instances stay alive). New tasks go in `TODO.md`'s late-added section; `task-plan.md` stays immutable. Frequent occurrences suggest rolling back to Step 5. |
| Task definition is fundamentally wrong | Roll back to Step 5. All Step 6 `implementer` instances retire at the step exit. After re-decomposition, regenerate `TODO.md` (rename the previous one to `TODO.md.pre-rollback-<timestamp>`). New `implementer` instances are launched on re-entry. |
| Diff conflicts with `design.md` | Main decides whether to roll back to Step 3. |
| Review-driven Blocker / Major (Step 7 → Step 6) | Re-activate the affected task in `TODO.md` (`[x]` → `[ ]`, `status: in_progress`, `re_activations++`), commit, launch a new `implementer` for the fix. |

## Parallelism notes

- If two parallel `implementer` instances target the same file, the dependency graph in `task-plan.md` should have serialized them. If not, Main re-serializes.
- Branch strategy (per-task feature branch vs sequential commits on a single branch) is decided by Main per the project's `git-workflow` skill.
- No `implementer` may be terminated mid-step. Idle instances wait until the step exits.

## Commit conventions

- `feat(dev-workflow/<identifier>/task-<id>): <task summary>` — each task gets its own commit (Conventional Commits scope; project-specific `git-workflow` skill takes precedence if it differs).
- For review-driven re-implementation, create a fresh commit (do not amend a previously pushed task commit).

## Sub-agent invocation rule reminder

Per the README "Sub-agent invocation rules", only Main launches additional or replacement `implementer` specialists. A running `implementer` reports a Blocker rather than spawning a peer. The Step 7 → Step 6 round-trip is mediated by Main: a `reviewer` does not directly launch an `implementer`.

## Session resume note

When resuming an interrupted Step 6:

1. Read `TODO.md` and re-load `progress.yaml`.
2. Restore the in-session task list via `TaskCreate`:
   - `[x] completed` rows → `TaskUpdate` to `completed`.
   - `status: in_progress` rows → revert to `pending` (the previous `implementer` has retired across the session boundary; a new instance must be launched).
3. If `TODO.md` and `TaskCreate` disagree, **`TODO.md` wins** — fix and commit.
4. All previous-session `implementer` instances are considered retired regardless of their `active_specialists` entry.
