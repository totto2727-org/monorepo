# Reference: How to write `TODO.md`

## Purpose

**Persist task state during Steps 6-7**. Since Main's internal task list (managed via `TaskCreate`) is volatile, this file becomes the **true source** for work hand-off and interruption / resumption. Across sessions, a new Main can fully restore task state by reading `TODO.md`.

## Author / update timing

- **Author:** Main (Specialists do not create it)
- **Generation:** generated from `task-plan.md` at the start of Step 6
- **Updates:** every time a task state changes (`pending` → `in_progress` → `completed` / on reactivation), **always commit at the same time**

## File location

`docs/workflow/<identifier>/TODO.md`

## How to write each section

### Header

- Source: `task-plan.md`
- Created at / Last updated: timestamps

### Subsequently added tasks (those occurring after `task-plan.md`)

Since **`task-plan.md` is operated immutably**, additional tasks discovered during Steps 6-7 are made explicit here:

- The contents of the additional task
- Reason for addition
- Which task it has dependencies with

### Tasks

Checkbox form:

```markdown
- [x] **T1** — Setup database schema
  - status: completed
  - dependencies: -
  - started_at: 2026-04-24T09:00:00Z
  - completed_at: 2026-04-24T09:30:00Z
  - commit: abc1234
  - implementer: impl-1
  - re_activations: 0
  - notes: -
- [ ] **T3** — Implement auth endpoint
  - status: in_progress
  - dependencies: T1, T2
  - started_at: 2026-04-24T10:30:00Z
  - implementer: impl-3
```

Items always recorded for each task:

- **status**: `pending` / `in_progress` / `completed`
- **dependencies**: predecessor task IDs
- **started_at**: recorded at transition to `in_progress`
- **completed_at**: recorded at transition to `completed`
- **commit**: the main commit SHA of the responsible implementer
- **implementer**: instance identifier
- **re_activations**: number of times reverted to Step 6 due to External Review Blocker findings

### State transition guide

- `pending`: not yet started. Displayed `[ ]`
- `in_progress`: `implementer` is running. Displayed `[ ]`, recording `started_at` and `implementer`
- `completed`: done. Displayed `[x]`, recording `completed_at` and `commit` SHA
- When reverting due to External Review Blocker findings: change `completed` → `in_progress` and increment `re_activations`

## Synchronization rules with TaskCreate

**TODO.md is the true source; TaskCreate is its view.**

1. On state change: execute in the order **update TODO.md → commit → TaskUpdate** (confirm the persistent side first)
2. On session resumption: read `TODO.md` and fully restore the internal task list with `TaskCreate`
3. If a discrepancy occurs: take TODO.md as the truth and fix TaskCreate

## Quality criteria

| Good                                                           | Bad                                                  |
| -------------------------------------------------------------- | ---------------------------------------------------- |
| All task state changes are immediately reflected and committed | Updates are batched, losing fine-grained granularity |
| commit SHAs are concretely filled in                           | The commit field is empty                            |
| The re_activations counter is accurately recorded              | Loop history is lost                                 |
| The reason for additional tasks is written                     | New tasks appear out of nowhere                      |

## Related artifacts

- **Input:** `task-plan.md` (source of initial state)
- **Linkage:** `progress.yaml` (overall phase progress. TODO.md is at the task level, the yaml at the phase level)
- **Reference:** Blocker findings during External Review → increment the `re_activations` of the relevant task and revert to `in_progress`
- **Hand-off:** `retrospective.md` analyzes the loop history of TODO.md to extract learnings
