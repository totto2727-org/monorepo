# Task List: {{identifier}}

- **Source:** `task-plan.md`
- **Active Steps:** Step 6-7 (Implementation / External Review)
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}

This file holds the **persisted task state**. It is kept in sync with the `TaskCreate` task list inside Main, but **this file is the source of truth**. On every state change, update TODO.md first, then commit, then run `TaskUpdate` (in that order).

## Tasks added later (after `task-plan.md` was finalized)

{{appended_tasks_note}}

Following the rule that `task-plan.md` is immutable, any additional tasks discovered during Steps 6-7 are recorded here. Always state the reason the task was added.

- None (default)

## Tasks

- [{{t1_checkbox}}] **T1** — {{t1_title}}
  - status: {{t1_status}} <!-- pending | in_progress | completed -->
  - dependencies: {{t1_dependencies}}
  - started_at: {{t1_started_at}}
  - completed_at: {{t1_completed_at}}
  - commit: {{t1_commit_sha}}
  - implementer: {{t1_implementer_id}}
  - re_activations: {{t1_re_activations}} <!-- Number of times the task was returned to Step 6 due to External Review Blocker findings -->
  - notes: {{t1_notes}}

- [{{t2_checkbox}}] **T2** — {{t2_title}}
  - status: {{t2_status}}
  - dependencies: {{t2_dependencies}}
  - started_at: {{t2_started_at}}
  - completed_at: {{t2_completed_at}}
  - commit: {{t2_commit_sha}}
  - implementer: {{t2_implementer_id}}
  - re_activations: {{t2_re_activations}}
  - notes: {{t2_notes}}

<!-- Add T3, T4, ... as needed -->

## State transition guide

- `pending`: Not started. Rendered as `[ ]`.
- `in_progress`: An `implementer` is running. Rendered as `[ ]`; record `started_at` and `implementer`.
- `completed`: Finished. Rendered as `[x]`; record `completed_at` and the `commit` SHA.
- When an External Review Blocker forces a rollback: change `completed` back to `in_progress` and increment `re_activations`.

## Commit conventions

- One commit per task state change (commit frequently).
- Example commit messages:
  - `docs(dev-workflow/{{identifier}}): start task T1`
  - `docs(dev-workflow/{{identifier}}): complete task T1`
  - `docs(dev-workflow/{{identifier}}): re-activate task T1 (external-review feedback)`
