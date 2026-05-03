# Reference: How to write `implementation-logs/<task-id>.md`

## Purpose

Store **long execution-confirmation logs and detailed implementation evidence** that do not fit in the `notes` field of `TODO.md`. Normally a single-line entry in TODO.md is sufficient, and this file is created only when needed.

## Author / creation timing

- **Author:** `implementer` Specialist (per assigned task)
- **Step:** Step 6 (Implementation)
- **Creation criteria:** create only when one of the following applies
  - The test execution log is long (more than several dozen lines)
  - Multiple scenarios were manually verified
  - Records of unforeseen events that occurred during implementation are needed
  - A decision deviating from the design document occurred
- **No need to create:** if the task is simple and fits in the `notes` field of TODO.md, do not create one

## File location

`docs/workflow/<identifier>/implementation-logs/<task-id>.md`

## How to write each section

### Header

- Task: ID + title
- Implementer: instance identifier
- Started at / Completed at: timestamps
- Commits: list all commits if multiple were made for one task

### Implementation summary

State what was done in **1-2 paragraphs**. At a granularity where the overview can be grasped without reading the diff.

### Changed files

Summarize the changes per file.

### Tests

- List of tests added
- Test execution output (include in this log if long)
- Pass/fail results of type checking, linting, existing tests, and new tests

### Manual verification log

Only when applicable. Record steps and results for each scenario manually verified.

### Issues encountered and how they were addressed

If unforeseen events occur during implementation, record the event and the response. Used as material for External Review (6-aspect parallel including the `holistic` aspect) and the Retrospective.

### Deviations from the design document

**Ideally zero.** When deviations exist, clearly state the reason and the hand-off to External Review (`holistic` aspect).

## Quality criteria

| Good                                                              | Bad                                                          |
| ----------------------------------------------------------------- | ------------------------------------------------------------ |
| Creation decision is appropriate (not created for short tasks)    | Created routinely for every task (when TODO.md alone is enough) |
| Test execution log is pasted as-is                                | Abstract description like "the tests passed"                 |
| Design deviations are explicit                                    | Implementing while hiding the deviation                      |
| Manual verification steps are reproducible                        | Only the verified facts, with no reproducibility             |

## Related artifacts

- **Inputs:** the assigned task, relevant sections of `design.md` / `task-plan.md`
- **Output destinations:** `review/<aspect>.md` (referenced by reviewer, especially the `holistic` aspect), `retrospective.md` (extraction of learnings)
- **Parent artifact:** `TODO.md` (link from the relevant task to `implementation-logs/<task-id>.md`)
