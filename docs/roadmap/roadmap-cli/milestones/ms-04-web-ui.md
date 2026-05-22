---
milestone_id: 'ms-04-web-ui'
roadmap_id: 'roadmap-cli'
---

# Milestone: Web UI with kanban board

This document is the **definition of a single milestone**. The rule is one file per milestone; place each one at `docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md`.

## Purpose

{{purpose}}

Describe in 1-2 sentences the state this milestone aims to reach. A qualitative goal is sufficient.

## Outcomes (qualitative)

{{outcomes}}

List, as bullets, the qualitative observation points that justify a "completed" judgment.

- {{outcome_1}}
- {{outcome_2}}
- {{outcome_3}}

## Scope

{{scope}}

Describe concretely the area covered by this milestone.

- Target modules / components / file groups
- Target users / system boundary
- Target features and areas

## Out of scope

{{out_of_scope}}

Areas intentionally not handled.

- {{out_of_scope_1}}
- {{out_of_scope_2}}

## Milestone dependencies

{{depends_on}}

List the IDs of other milestones that must complete before this one. Keep this in exact agreement with `progress.yaml.milestones[].depends_on[]`. For root milestones (no dependencies) write `(none)` explicitly.

- {{milestone_dependency_1_id}}: {{milestone_dependency_1_reason}}
- {{milestone_dependency_2_id}}: {{milestone_dependency_2_reason}}

## Notes / additional remarks

{{notes}}

Supplementary notes that do not fit into `progress.yaml.milestones[].notes`. Optional (may be left empty).
