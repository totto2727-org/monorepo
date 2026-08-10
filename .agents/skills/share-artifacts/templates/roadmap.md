# Roadmap: {{title}}

- **Roadmap ID:** {{roadmap_id}}
- **Author:** {{author}}
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}
- **Status:** {{status}} <!-- planned | active | completed; must match progress.yaml -->

See [Roadmap Authoring Guide](../references/roadmap.md).

## Background

{{background}}

Explain why the roadmap is needed now and why one implementation effort is insufficient.

## Purpose

{{purpose}}

State the qualitative end state in one to three sentences.

## Scope

{{scope}}

## Exclusions

{{exclusions}}

## Shared constraints

{{constraints}}

Include only constraints that apply to multiple milestones.

## Milestones

| ID                 | Title                 | Estimated effort count       | Dependencies                 | Detail                             |
| ------------------ | --------------------- | ---------------------------- | ---------------------------- | ---------------------------------- |
| {{milestone_1_id}} | {{milestone_1_title}} | {{milestone_1_effort_count}} | {{milestone_1_dependencies}} | `milestones/{{milestone_1_id}}.md` |
| {{milestone_2_id}} | {{milestone_2_title}} | {{milestone_2_effort_count}} | {{milestone_2_dependencies}} | `milestones/{{milestone_2_id}}.md` |

## Dependency graph

```mermaid
graph LR
  {{milestone_1_id}}[{{milestone_1_id}} {{milestone_1_short_title}}]
  {{milestone_2_id}}[{{milestone_2_id}} {{milestone_2_short_title}}]
  {{milestone_1_id}} --> {{milestone_2_id}}
```

## Related links

{{references}}

## Open strategic questions

{{open_questions}}
