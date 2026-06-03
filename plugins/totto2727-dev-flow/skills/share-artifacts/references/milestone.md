# Reference: How to write `milestone.md`

## Purpose

Create the **definition of one milestone** under a roadmap. It is a detailed write-up that supplements the milestone list table in `roadmap.md`, and the primary input for the agent or execution system that owns the milestone's workflow-level execution. By following the principle of one milestone = one file, diffs when adding, splitting, or deleting dependencies remain localized.

`milestone.md` plays the role of a **bridge between the strategic and tactical layers**. The qualitative goals, scope boundaries, and dependency relationships agreed upon here are expanded into observable success criteria by the milestone's owning workflow-level agent or execution system.

## Author / creation timing

- **Author:** `roadmap-planner` Specialist
- **Step:** `roadmap` Step 2 (Milestone Decomposition)
- **Approval:** user approval required at Step 2 completion (Artifact-as-Gate-Review)

## File location

`docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md`

- kebab-case is recommended for `<milestone-id>` (e.g. `ms-01-foundation`)
- Make it perfectly match `progress.yaml.milestones[].id` and the milestone list ID in `roadmap.md`

## How to write each section

### Purpose

Describe the **qualitative goal** in 1-2 sentences. As with the "Purpose" of `roadmap.md`, **it does not carry observable success criteria**. When observable criteria are needed, the milestone's owning agent or execution system expands them during workflow-level execution.

| Good (qualitative goal)                                            | Bad (requires a measurement method)                      |
| ------------------------------------------------------------------ | -------------------------------------------------------- |
| OAuth client registration is functioning                           | OAuth client registration API has p95 < 200ms            |
| The first 1/3 of the payment API endpoints run on the new platform | 99.9% availability across the entire API after migration |

### Goals (qualitative)

**Qualitative observation points** that serve as the basis for the completion judgment. The primary reference for `roadmap-retrospective-writer` in Step 4 (Roadmap Retrospective) when summarizing milestone achievement, and also a basis for transitioning `progress.yaml.milestones[].status` to `completed`.

- "The user can actually log in via the new flow"
- "All existing tests remain green"
- "The migration document has been shared with other teams"

### Scope / non-scope

- Scope: the boundary of **the maximum extent the underlying workflow-level executions may touch**. Specify target modules / features / users / environments
- Non-scope: responsibilities of other milestones / sent to subsequent milestones / handled in another roadmap, etc.

If non-scope is not written, milestone boundaries silently expand as the underlying executions progress, causing overlap with dependent milestones. **Always write it.**

### Dependent milestones

List the IDs of other milestones that **must be completed first**.

- Make it match the `progress.yaml.milestones[].depends_on[]` array exactly (the order does not matter)
- For starting milestones (no dependencies), write `(none)` explicitly (avoid implicit empty fields)
- Add a one-line rationale per dependency (clue for circular-dependency detection)

### Linked workflow-level executions (workflow_identifiers)

List of `<identifier>` values of workflow-level executions linked to this milestone. 1:1 recommended, 1:N allowed when the owning agents or execution systems split the milestone.

**The primary source is `progress.yaml`**: each time an underlying execution starts, it appends its own `<identifier>` to `progress.yaml.milestones[].workflow_identifiers[]` through the roadmap CLI. The table in this `milestone.md` is updated optionally as a supplemental memo (to avoid double management, in case of conflict prefer `progress.yaml`).

### Anticipated number of workflow-level executions

The expected number of executions needed to achieve this milestone. 1 is standard. When adopting 1:N (= multiple executions), include the rationale.

| Number of executions | Anticipated case                                                                                    |
| -------------------- | --------------------------------------------------------------------------------------------------- |
| 1 (recommended)      | The milestone fits within a single workflow-level execution scale                                   |
| 2-3                  | Intentional split across design / implementation / verification, or parallel multi-team             |
| 4 or more            | Recommend re-examining milestone decomposition (consider further splitting into smaller milestones) |

### Supplementary notes / things to keep in mind

Supplementary notes that do not fit in `progress.yaml.milestones[].notes`, or hand-off memos for the launch of an underlying workflow-level execution. Optional (may be empty).

## Layout pattern example: integration verification milestone

As **an optional layout pattern example** when the `roadmap-planner` carves out milestones, there is a pattern of placing the final milestone of a roadmap as an "integration verification milestone". This is a pattern **example** of "**final milestone = integration verification milestone**"; it is **expressed as a normal milestone (this template)**. For example, after the underlying milestones individually complete unit/integration testing, the final milestone can be owned by a workflow-level execution that runs "scenario tests across all milestones", "production-equivalent load testing", and "user acceptance testing". This section is purely a layout pattern **example** and is not mandatory.

## Quality criteria

| Good                                              | Bad                                                                         |
| ------------------------------------------------- | --------------------------------------------------------------------------- |
| Purpose is written as a qualitative goal          | Observable criteria are mixed in (encroaching on workflow's responsibility) |
| Dependent milestone IDs match `progress.yaml`     | Notation drift or missing entries                                           |
| Starting milestones explicitly list `(none)`      | The dependency section is left blank                                        |
| The principle of 1 file = 1 milestone is followed | Multiple milestones bundled into one file                                   |
| Anticipated execution count stays within 1-3      | Execution count is 4 or more without considering re-decomposition           |
| Non-scope is explicit                             | Only scope, with ambiguous boundaries                                       |

## Related artifacts

- **Inputs:** `roadmap.md` (purpose, scope boundaries, and macro constraints of the parent roadmap)
- **Premise for downstream artifacts:**
  - `progress.yaml.milestones[]` (CLI-managed roadmap state initialized at Step 2)
  - The planning artifact of each underlying workflow-level execution (this file is used as input to draft observable success criteria)
- **Impact when changed:** in principle immutable after confirmation in Step 2. Changes during the underlying execution are equivalent to regressing back to roadmap Step 2.
- **Related:** `references/roadmap.md`, `references/roadmap-retrospective.md`
