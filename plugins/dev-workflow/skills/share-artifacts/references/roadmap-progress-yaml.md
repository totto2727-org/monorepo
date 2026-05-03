# Reference: How to write `roadmap-progress.yaml`

## Purpose

**Persist the progress of the entire roadmap and its underlying milestones in `dev-roadmap` in a machine-readable form**. Just as `progress.yaml` is the true source for a single cycle, `roadmap-progress.yaml` functions as the true source at the roadmap level.

**Minimal responsibility**: the schema in this version holds only the "linkage between milestones ↔ `dev-workflow` cycle `<identifier>`" and coarse-grained statuses (`planned` / `active` / `completed` / `blocked` / `cancelled`). It **does not hold fine-grained progress (current step name, gate state, detailed event history)**. When needed, fetch via `milestones[].workflow_identifiers[]` by traversing `docs/workflow/<identifier>/progress.yaml`.

## File location (1:1 correspondence exception)

`docs/roadmap/<roadmap-id>/roadmap-progress.yaml`

`templates/roadmap-progress.yaml` (extension `.yaml`) and this reference (`references/roadmap-progress-yaml.md`, extension `.md`) are the **third 1:1 correspondence exception**. Follows the same naming pattern as the existing exception (`templates/progress.yaml` ↔ `references/progress-yaml.md`). For details, see the 1:1 exception list in `share-artifacts/SKILL.md`.

## Author / updaters

- **Author:** `roadmap-analyst` Specialist (initialized in Step 1 with `milestones: []` empty)
- **Updater (Step 2):** `roadmap-planner` Specialist (confirms `milestones[]`, transitions roadmap-wide `status: active`)
- **Updater (Step 3):** the **Main of each underlying `dev-workflow` cycle** (autonomous updates; the "`dev-workflow`-side update protocol" section of this document is normative)
- **Updater (Step 4):** `roadmap-retrospective-writer` Specialist (transitions roadmap-wide `status: completed`)

## Overall schema structure

```yaml
roadmap_id: <roadmap-id>
title: <short description>
status: planned | active | completed # roadmap-wide
created_at: <ISO8601 second precision>
updated_at: <ISO8601 second precision>

milestones:
  - id: <milestone-id>
    title: <short description>
    status: planned | active | completed | blocked | cancelled
    depends_on: [] # milestone dependencies (id array, DAG)
    workflow_identifiers: [] # linked dev-workflow cycles (1:N allowed)
    notes: null # optional supplement (default null)
```

## How to write each field

### `roadmap_id` / `title` / `status` (roadmap-wide)

| Field        | How to write                                                                                                 |
| ------------ | ------------------------------------------------------------------------------------------------------------ |
| `roadmap_id` | Match the `docs/roadmap/<roadmap-id>/` directory name. kebab-case recommended (e.g. `2026-q2-oauth-rollout`) |
| `title`      | Match the title (1 line) of `roadmap.md`                                                                     |
| `status`     | 3 values: `planned` (during Steps 1-2) / `active` (during Step 3) / `completed` (Step 4 completed)           |

Transition timing of roadmap-wide `status`:

- `planned`: Step 1 (`roadmap-analyst` initializes)
- `planned → active`: at Step 2 completion (`roadmap-planner` transitions in tandem with confirming `milestones[]`)
- `active → completed`: at Step 4 completion (`roadmap-retrospective-writer` transitions simultaneously with generating `docs/retrospective/roadmap-<roadmap-id>.md`)

### `created_at` / `updated_at`

- ISO8601 **second precision** (e.g. `2026-04-29T00:00:00Z`). ms precision is unnecessary (does not depend on same-second contention since there is no events array)
- `created_at`: fixed at initialization, not changed afterwards
- `updated_at`: rewritten to the latest ISO8601 each time any field is rewritten

### `milestones[]`

| Sub-field              | How to write                                                                                                                                                      |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                   | kebab-case recommended (e.g. `ms-01-foundation`). Match the `milestones/<id>.md` file basename. **Immutable after Step 2 confirmation**                           |
| `title`                | Short description (1 line). Match the title of `milestones/<id>.md`                                                                                               |
| `status`               | 5 values: `planned` / `active` / `completed` / `blocked` / `cancelled`. Scalar rewrite from `planned → active` at cycle start, `active → completed` at completion |
| `depends_on`           | Array of milestone IDs that must be completed first. Maintain DAG. Immutable after Step 2 confirmation                                                            |
| `workflow_identifiers` | Array of linked `dev-workflow` cycle `<identifier>` values (1:N allowed). **Append-only operation** (do not delete; if no longer needed, explain in `notes` etc.) |
| `notes`                | Optional supplement (default `null`). Free area for future schema extension. Do not include PII / tokens / internal URLs (consistent with `specialist-common` §9) |

#### Recommended `id` naming examples

- When indicating order: `ms-NN-<short-name>` (e.g. `ms-01-foundation`, `ms-02-token-refresh`)
- When grouping by feature area: `<area>-<short-name>` (e.g. `auth-foundation`, `auth-token-refresh`)
- Be consistent within a roadmap (avoid mixing styles)

#### `status` transition rules

| Transition           | Timing                                                                                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `planned → active`   | At underlying `dev-workflow` cycle start (Main transitions at the same time as `progress.yaml` initialization; see "Update protocol" of this document)  |
| `active → completed` | At underlying `dev-workflow` cycle completion (= `dev-workflow` Step 9 Retrospective completion). For 1:N, the final state judgment is left to the user |
| `* → blocked`        | When an underlying cycle hits a hard-to-resolve Blocker, transitioned by Main's judgment                                                                |
| `* → cancelled`      | When the user judges to cancel a milestone during roadmap Step 2 / Step 3                                                                               |

#### Append/delete rules for `workflow_identifiers[]`

- **Append-only operation**: append the `<identifier>` at underlying `dev-workflow` cycle start. High git 3-way merge auto-merge affinity
- **Do not delete**: keep the linkage as history. If the cycle is canceled, express it via that cycle's `progress.yaml.status: cancelled`; do not delete from `workflow_identifiers[]`
- **No duplicate appending**: the same `<identifier>` must not appear multiple times (set semantics). For merge rules when concurrent appends occur on parallel branches, see "Concurrent cycle conflict avoidance" in this document

## `dev-workflow`-side update protocol

This section is the core operating rule of `roadmap-progress.yaml`. A cycle whose `progress.yaml.roadmap` is non-null (= a `dev-workflow` cycle linked to a milestone of the parent roadmap) is responsible for **autonomously updating** this file according to its own progression. The detailed protocol is written in the "`roadmap-progress.yaml` update protocol" section (independent top level) of `dev-workflow/SKILL.md`, and this section restates it from 3 perspectives (what / when / how) on the `references/roadmap-progress-yaml.md` side.

### What — fields to update

| Update target                         | Nature                                                                                                                  |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `milestones[].status`                 | Scalar rewrite. Only the 2 transitions `planned → active` (at cycle start) / `active → completed` (at cycle completion) |
| `milestones[].workflow_identifiers[]` | append-only. Append its own `<identifier>` exactly once at cycle start                                                  |
| `updated_at`                          | Rewritten to the latest ISO8601 (second precision) simultaneously with any update                                       |

Fields **not** to update (immutable or other Specialist's responsibility):

- `roadmap_id` / `title` / `created_at` (fixed at initialization)
- Roadmap-wide `status` (responsibility of `roadmap-planner` / `roadmap-retrospective-writer`)
- `milestones[].id` / `title` / `depends_on` (immutable after Step 2 confirmation)
- `milestones[].notes` (responsibility of `roadmap-planner` at filing time, or Main's supplemental updates)

### When — update timing

Following the user-simplification policy ("only the linkage is needed"), this version updates only at the following **2 timings**:

| Timing                      | Details                                                                                                                                                                                                                                                                           |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **(a) At cycle start**      | Same timing as `progress.yaml` initialization (`dev-workflow/SKILL.md` "When the workflow starts" step 5). Transition the relevant `milestones[].status` from `planned → active`, append the cycle's `<identifier>` to `milestones[].workflow_identifiers[]`, update `updated_at` |
| **(c) At cycle completion** | **At `dev-workflow` Step 9 Retrospective completion** (the 9-step system). Transition the relevant `milestones[].status` from `active → completed`, update `updated_at`                                                                                                           |

#### Timing scoped out in this version: (b) Per-step progress summary reflection

Updating `roadmap-progress.yaml` at each `dev-workflow` step completion is **not done in this version (scope out)**. Reasons:

- Fine-grained progress can be traced via `docs/workflow/<identifier>/progress.yaml` (avoids double management)
- Limiting update timings to 2 points dramatically reduces the chance of concurrent-update conflicts
- If insufficiency is found, in a later cycle we can incrementally extend with adding an `events` array / `last_step` field, etc.

### How — value transition rules / commit granularity / concurrent cycle conflict avoidance

#### Value transition rules

- `status` is a scalar rewrite (`planned → active` / `active → completed`). The transition to `completed` is irreversible (to revert, requires Main's judgment + user confirmation + recording in `notes`)
- `workflow_identifiers[]` is append-only (do not delete). Duplicate appending is forbidden to keep set semantics
- `updated_at` is ISO8601 second precision. UTC (`Z` suffix) recommended for the timezone

#### Commit granularity (consistent with `dev-workflow/SKILL.md` commit conventions)

- `roadmap-progress.yaml` update at **(a) cycle start**: **bundled** with the `progress.yaml` initialization commit (do not split into a separate commit)
- `roadmap-progress.yaml` update at **(c) cycle completion**: **bundled** with the `dev-workflow` Step 9 Retrospective completion commit
- Example commit messages:
  - On start: `docs(dev-workflow/<identifier>): initialize cycle (linked to roadmap <roadmap-id> milestone <milestone-id>)`
  - On completion: `docs(dev-workflow/<identifier>): close cycle with retrospective (completed milestone <milestone-id> in roadmap <roadmap-id>)`
- **Specify the path explicitly with `git add`** (`-A` / `.` forbidden, consistent with `specialist-common` Git guardrails)

#### Concurrent cycle conflict avoidance

Because parallel `dev-workflow` cycles may update the same `roadmap-progress.yaml`, conflict mitigation is needed. This version **delegates to git 3-way merge** (adopting a minimal schema + simple merge policy: limit `status` scalar rewrites and `workflow_identifiers[]` to append-only, ensuring conflict resilience at the schema level):

| Conflict scenario                                                                                                    | Probability                                                                   | Mitigation                                                                                                                                        |
| -------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| The same milestone's `status` is rewritten to different values (e.g. `completed` vs `blocked`) on different branches | Low (only when two cycles complete at the same instant on different branches) | The `pre-commit` hook's YAML syntax check blocks leftover conflict markers. Specialist must not resolve unilaterally; report to Main as a Blocker |
| Appends to `workflow_identifiers[]` happen at the same position on both branches                                     | Very low (appends usually go to different lines)                              | git 3-way merge auto-merges. If a "both-add" conflict occurs, manually merge by **keeping both (set union)**                                      |
| Simultaneous rewrite of `notes`                                                                                      | Very low (essentially no update responsibility in this version)               | Normal 3-way merge                                                                                                                                |

#### Recovery procedure on merge conflict

1. If conflict markers (`<<<<<<<` / `>>>>>>>`) are detected by the `pre-commit` hook, the commit is blocked
2. Specialist must not resolve unilaterally and reports to Main as a Blocker (`specialist-common` §4 case B)
3. Main does the following:
   1. Confirm the logical consistency of the `status` of the relevant milestone (e.g. if both branches claim `completed`, adopt `completed`; if one is `blocked`, judge based on situation by user)
   2. **Keep both (set union)** of the additions in `workflow_identifiers[]` from both branches
   3. Regenerate `updated_at` (ISO8601 of the current time)
   4. Normal commit (`docs(dev-roadmap/<roadmap-id>): resolve concurrent updates`)

### Applicability — skip rule for `roadmap == null`

- Cycles with `progress.yaml.roadmap == null` (= independent cycles) skip this protocol entirely
- The protocol is invoked only when `progress.yaml.roadmap` is non-null and `progress.yaml.roadmap.milestone.id` exists
- If the `roadmap` block exists but `milestone.id` is missing, treat as an invalid state and report as a Blocker (upper schema violation)

For details, also refer to the `roadmap` section of `references/progress-yaml.md`.

## Quality criteria

| Good                                                                                                         | Bad                                                                              |
| ------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| Parses without syntax error in `yq` / any YAML parser                                                        | Mixed indentation / mixed tabs / missing space after colon                       |
| All required fields (`roadmap_id` / `title` / `status` / `created_at` / `updated_at` / `milestones`) present | Missing required fields                                                          |
| `status` values are within the enum (`planned` / `active` / `completed` / `blocked` / `cancelled`)           | Non-enum values (`done` / `progress`, etc.) mixed in                             |
| `milestones[].depends_on[]` is a DAG (no cycles)                                                             | Circular dependencies present (also detectable via the Mermaid dependency graph) |
| `workflow_identifiers[]` keeps set semantics (no duplicates)                                                 | The same `<identifier>` appears multiple times                                   |
| `updated_at` is rewritten on every update                                                                    | Left stale                                                                       |
| `roadmap_id` / milestone `id` exactly match `roadmap.md` / `milestones/<id>.md`                              | Notation drift (e.g. `ms-01_foundation` vs `ms-01-foundation`)                   |

## Related artifacts

- **No input** (initialized by `roadmap-analyst` in Step 1; afterwards updated according to this protocol)
- **Linkage:**
  - `roadmap.md` (matches title / milestone list)
  - `milestones/<milestone-id>.md` (matches id / title / depends_on / workflow_identifiers)
  - `progress.yaml.roadmap` block (bidirectional reference; see `references/progress-yaml.md`)
  - "`roadmap-progress.yaml` update protocol" section in `dev-workflow/SKILL.md` (the source-of-truth of this protocol)
- **Subsequent:** in Step 4, `roadmap-retrospective-writer` references this file and transitions roadmap-wide `status: completed`
