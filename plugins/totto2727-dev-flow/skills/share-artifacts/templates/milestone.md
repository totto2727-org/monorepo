# Milestone: {{milestone_title}}

- **Milestone ID:** {{milestone_id}}
- **Roadmap ID:** {{roadmap_id}}
- **Status:** {{status}} <!-- planned | active | completed | blocked | cancelled (must match `progress.yaml.milestones[].status`) -->
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}

This document is the **definition of a single milestone**, drafted by the `roadmap-planner` Specialist during `roadmap` **Step 2 (Milestone Decomposition)**. The rule is one file per milestone; place each one at `docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md`. See `share-artifacts/references/milestone.md` for authoring details.

## Purpose

{{purpose}}

Describe in 1-2 sentences the state this milestone aims to reach. **A qualitative goal is sufficient** (the responsibility for observable success criteria lies with the workflow-level executions underneath). Examples: "the OAuth client registration feature is operational", "the first one-third of the payment API endpoints run on the new platform".

## Outcomes (qualitative)

{{outcomes}}

List, as bullets, the **qualitative observation points** that justify a "completed" judgment. Write at the level of granularity at which a human can visually agree "this has been achieved" once the underlying workflow-level executions finish and `progress.yaml.milestones[<this>].status` transitions to `completed`.

- {{outcome_1}}
- {{outcome_2}}
- {{outcome_3}}

## Scope

{{scope}}

Describe concretely the area covered by this milestone. This is the boundary defining **how far the underlying workflow-level executions are allowed to reach**.

- Target modules / components / file groups
- Target users / system boundary
- Target features and areas

## Out of scope

{{out_of_scope}}

Areas intentionally not handled (responsibility of another milestone / deferred to a later milestone / handled by a different roadmap, etc.).

- {{out_of_scope_1}}
- {{out_of_scope_2}}

## Milestone dependencies

{{depends_on}}

List the IDs of other milestones that **must complete before** this one. Keep this in exact agreement with `progress.yaml.milestones[].depends_on[]`. For root milestones (no dependencies) write `(none)` explicitly.

- {{milestone_dependency_1_id}}: {{milestone_dependency_1_reason}}
- {{milestone_dependency_2_id}}: {{milestone_dependency_2_reason}}

## Related workflow-level executions (workflow_identifiers)

{{workflow_identifiers}}

The list of `<identifier>` values for workflow-level executions linked to this milestone. 1:1 mapping is recommended, but 1:N is allowed when the owning agents or execution systems split the milestone.

- At creation time (Step 2): leave as empty `[]`, or pre-fill with the planned `<identifier>` values
- When an underlying execution starts: it appends its own `<identifier>` to `progress.yaml.milestones[].workflow_identifiers[]` through the roadmap CLI (appending here is optional — `progress.yaml` is the primary source)

| Execution `<identifier>`  | Status (`active` / `completed` / `blocked` / `cancelled`) | Comment             |
| ------------------------- | --------------------------------------------------------- | ------------------- |
| {{workflow_identifier_1}} | {{workflow_status_1}}                                     | {{workflow_note_1}} |
| {{workflow_identifier_2}} | {{workflow_status_2}}                                     | {{workflow_note_2}} |

## Estimated number of workflow-level executions

{{cycle_count_estimate}}

The number of workflow-level executions expected to be required to complete this milestone (1 is the standard; if more, also write the rationale). Examples of valid 1:N rationales: "split into two executions, one for design and one for implementation", "multiple teams or agents will run parallel executions to try different approaches".

## Notes / additional remarks

{{notes}}

Supplementary notes that do not fit into `progress.yaml.milestones[].notes`, or handoff memos for when an underlying workflow-level execution is launched. Optional (may be left empty).
