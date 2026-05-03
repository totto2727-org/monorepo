# Reference: How to write `intent-spec.md`

## Purpose

Convert the user's request into a **verbalized agreement document**. It becomes the starting point for the entire cycle, and every subsequent step (research, design, task decomposition, implementation, validation) refers to it. If "what problem this cycle solves" is ambiguous, everything becomes ambiguous, so the quality of the Intent Spec determines the quality of the entire cycle.

## Author / creation timing

- **Author:** `intent-analyst` Specialist
- **Step:** Step 1 (Intent Clarification)
- **Approval:** user approval required (Artifact-as-Gate-Review, the artifact itself is presented as the review target)

## File location

`docs/workflow/<identifier>/intent-spec.md`

## How to write each section

### Background

Why are we tackling this problem now? Describe the current issues, triggers, and prior events as prose.

### Purpose

State the goal of the cycle in **1-3 sentences**. Write it as an achievement state such as "be able to do X" or "make X possible".

### Scope / non-scope

- Scope: concretely the features / areas the cycle covers
- Non-scope: explicitly state what is not covered. List items "not touched in this cycle" or "to be handled in a future separate cycle"

**If you do not write the non-scope, the scope will silently expand during implementation. Always write it.**

### Success criteria

Describe in **observable form**. This is what is measured in Validation Step 8.

| Good (observable)                         | Bad (not observable)                                             |
| ----------------------------------------- | ---------------------------------------------------------------- |
| The p95 latency of the API is below 200ms | Performance improves                                             |
| Returns 401 on authentication failure     | It works correctly                                               |
| All existing integration tests pass       | Existing functionality is not broken (no definition of "broken") |
| 100 new users can register                | It is easy to use                                                |

### Constraints

Be aware of three kinds:

- **Technical constraints**: language / framework used, compatibility, performance limits
- **Organizational constraints**: deadlines, headcount, budget
- **Normative constraints**: security, compliance, existing ADRs, coding conventions

### Related links

List references needed to reconstruct the context later, such as Issues, tickets, existing ADRs, and external specifications.

### Open questions

**Hand-off to Step 2 (Research).** Explicitly leave any points that could not be resolved during Intent Clarification. If empty, write that it is empty.

## Quality criteria

| Good                                                       | Bad                                                        |
| ---------------------------------------------------------- | ---------------------------------------------------------- |
| Every success criterion has a measurement method           | Subjective expressions like "improves" or "becomes faster" |
| Non-scope is explicit                                      | Only scope, with ambiguous boundaries                      |
| Constraints are covered across all 3 categories            | Constraints section is empty or technical-only             |
| The user reads it and says "yes, that's what I want to do" | Too abstract; can be interpreted any way                   |

## Related artifacts

- **Premise for downstream artifacts:** `research/*.md` / `design.md` / `task-plan.md` / `validation-report.md` / `retrospective.md` reference this
- **Impact when changed:** rewriting the Intent Spec requires consistency checks against downstream artifacts (a large change is equivalent to regressing back to Step 1)
