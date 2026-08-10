# Milestone: {{milestone_title}}

- **Milestone ID:** {{milestone_id}}
- **Roadmap ID:** {{roadmap_id}}
- **Status:** {{status}} <!-- planned | active | completed | blocked | cancelled; must match progress.yaml -->
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}

Store this file at `docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md`. See [Milestone Authoring Guide](../references/milestone.md).

## Purpose

{{purpose}}

## Outcomes

- {{outcome_1}}
- {{outcome_2}}

## Scope

{{scope}}

## Exclusions

{{exclusions}}

## Dependencies

- {{milestone_dependency_id}}: {{milestone_dependency_reason}}

Write `(none)` when the milestone has no dependencies.

## Linked implementation efforts

`progress.yaml.milestones[].workflow_identifiers[]` is the primary record.

| Workflow identifier     | Status              | Note              |
| ----------------------- | ------------------- | ----------------- |
| {{workflow_identifier}} | {{workflow_status}} | {{workflow_note}} |

## Estimated effort count

{{effort_count_estimate}}

{{effort_count_rationale}}

## Notes

{{notes}}
