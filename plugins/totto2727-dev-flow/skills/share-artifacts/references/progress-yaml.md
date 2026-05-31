# Reference: How to write `progress.yaml`

## Purpose

**Persist the progress of the entire cycle in a machine-readable form**. Main is the sole writer and this is the true source. On interruption / resumption, state can be restored simply by reading this file.

## Author / update timing

- **Author:** Main
- **Initialization:** at cycle start (immediately before starting Step 1)
- **Updates:** at each step completion / on user approval / on Blocker occurrence / on rollback / on session resumption

## File location

`docs/workflow/<identifier>/progress.yaml`

## How to write each field

### `identifier` / `started_at` / `updated_at`

- `identifier`: the identifier agreed with the user at cycle start (feature name / ticket ID, etc.)
- `started_at`: ISO8601 timestamp of cycle start (fixed, not changed afterwards)
- `updated_at`: rewritten to the latest ISO8601 each time the YAML is updated

### `status` / `current_step`

- `status`: one of `active` / `completed` / `blocked` (the state of the entire cycle. There is no phase concept.)
- `current_step`: write both the step number and name, e.g. "Step 3: Design"

### `completed_steps`

Record completed steps in chronological order.

```yaml
completed_steps:
  - step: 'Step 1: Intent Clarification'
    completed_at: 2026-04-24T10:00:00Z
    artifact: intent-spec.md
```

### `pending_gates`

List items awaiting user approval / Main verdict. When a gate is resolved, remove it from the list.

### `active_specialists`

Record **only Specialists currently running**. When completed, they are absorbed into `completed_steps` and removed from this list.

```yaml
active_specialists:
  - name: researcher
    task: investigation of the existing-impl aspect
    status: running
    started_at: 2026-04-24T10:30:00Z
```

### `blockers`

Unresolved Blockers. Remove when resolved. The wording should include "event + impact + response policy".

- Example for recording a CI failure: `Step 6 task-T1 commit abc1234 had CI fail twice in a row (run id 25270xxxx) → reached retry limit, marked as Blocker`. Do not add new fields; write attempts / run id / corresponding commit in free-form text.

### `artifacts`

Relative paths of all artifacts. Fields not yet generated may remain `null`. Artifacts that may be created multiple times (research, review) are in list form.

Field list:

- `intent_spec` (Step 1) — `intent-spec.md`
- `research` (Step 2) — list
- `design` (Step 3) — `design.md`
- `qa_design` (Step 4) — `qa-design.md`
- `qa_flow` (Step 4) — `qa-flow.md`
- `external_adrs` — paths of ADRs filed outside the cycle (list). General mode (`docs/adr/<file>.md`) and Roadmap mode (`docs/roadmap/<roadmap-id>/adr/<file>.md`) are listed at the same level. Scope is identified by the `scope: general` / `scope: roadmap:<roadmap-id>` frontmatter in the ADR itself (details: `share-adr/SKILL.md`)
- `task_plan` (Step 5) — `task-plan.md`
- `todo` (generated at Step 6 start) — `TODO.md`
- `review` (Step 7) — list (`review/<aspect>.md`, 6 aspects)
- `validation` (Step 8) — `validation-report.md`
- `retrospective` (Step 9) — `retrospective.md`

### `roadmap` (optional nested block, determining whether the cycle is under a roadmap)

A field indicating whether the cycle was launched from a milestone under `roadmap`. Default is `null` (= independent cycle). Holds a nested block embedding the parent roadmap ID and milestone ID as the source for bidirectional reference with `roadmap`.

#### Field meaning

- `roadmap.id`: the `roadmap-id` of the parent `roadmap` (matches the `docs/roadmap/<roadmap-id>/` directory name). Required when non-null.
- `roadmap.milestone.id`: the linked milestone id (matches the basename of `docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md`). Required when non-null.
- No other subfields exist in this version (scoped out as future extension room).

#### Setting timing

When a cycle under a roadmap starts, Main initializes the `roadmap` block in the same step as `progress.yaml` initialization (step 4' in "When the workflow starts" of `totto2727-dev-flow/SKILL.md`). At the same time, transition the corresponding `milestones[].status` of the parent `docs/roadmap/<roadmap-id>/progress.yaml` from `planned → active`, and append its own `<identifier>` to `milestones[].workflow_identifiers[]`. For details, follow "`progress.yaml` update protocol" in `totto2727-dev-flow/SKILL.md`.

For independent cycles, leave the `roadmap` block as `null` (default) and skip the initialization process.

#### Usage rules (3 viewpoints)

1. **(a) `roadmap == null`**: an independent cycle (default). Indicates a normal cycle that is not under `roadmap`.
2. **(b) `roadmap` non-null**: a cycle under a roadmap. Written in the nested object form `{id: <roadmap-id>, milestone: {id: <milestone-id>}}`, where both `roadmap.id` and `roadmap.milestone.id` are required. Missing either is treated as a schema violation.
3. **(c) Writing the equivalent of `milestone` alone with `roadmap == null` is invalid**: forms such as "writing milestone without writing roadmap.id" or "expressing milestone in another top-level key while `roadmap: null`" are not allowed (schema violation). The expression of `milestone` must always be placed under the `roadmap` nest as `roadmap.milestone`.

#### Example YAML

Independent cycle (default):

```yaml
roadmap: null
```

Cycle under a roadmap:

```yaml
roadmap:
  id: 2026-q2-oauth-rollout
  milestone:
    id: ms-02-token-refresh
```

### Deprecated fields

- Keys for the integrity report generated in the old Step 7 (now removed) — removed in the 2026-04 schema overhaul. The old keys may remain in `progress.yaml` of past cycles (before 2026-04), but they are read-and-discard targets in the current schema, and adding new ones is forbidden. When a Specialist reads an old cycle's yaml on resumption, it must ignore those keys. The integrity check responsibility is unified into the `holistic` aspect of Step 7 External Review (`review/holistic.md`).

### `user_approvals`

History of user approvals. Distinguish approval / rejection in `notes`.

### `rollbacks`

History of rollbacks between steps. Make the cause and the destination explicit.

## Quality criteria

| Good                                               | Bad                                                         |
| -------------------------------------------------- | ----------------------------------------------------------- |
| Each event is reflected immediately when it occurs | Trying to write everything later, leading to omissions      |
| Timestamps use UTC + ISO8601                       | Local time / natural-language notation                      |
| Blockers are concrete (event, impact, policy)      | Abstract descriptions like "a problem occurred"             |
| Active Specialists match reality                   | A `running` state is left over and persists across sessions |

## Related artifacts

- This file is **the index for all artifacts**. The `artifacts` field functions as the table of contents for the artifacts directory
- Linked to `TODO.md` (the true source of task state during Steps 6-7 is TODO.md; the YAML side is a cycle-level summary)
