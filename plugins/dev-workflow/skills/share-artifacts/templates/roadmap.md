# Roadmap: {{title}}

- **Roadmap ID:** {{roadmap_id}}
- **Author:** {{author}}
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}
- **Status:** {{status}} <!-- planned | active | completed (must match `roadmap-progress.yaml.status`) -->

This document is **the immutable strategic-layer plan**, drafted in `dev-roadmap` **Step 1 (Roadmap Intent)** and finalized when the milestone list and dependency graph are appended in **Step 2 (Milestone Decomposition)**. It bundles development at a multi-cycle scale that cannot fit into a single `dev-workflow` cycle. See `share-artifacts/references/roadmap.md` for authoring details.

## Background

{{background}}

Describe why this roadmap is being undertaken now and the chain of events that made it necessary to span multiple `dev-workflow` cycles. Always state "the reason this cannot fit into a single cycle" (= the rationale for needing the strategic layer).

## Purpose

{{purpose}}

In 1-3 sentences, the goal the roadmap aims to achieve. **A qualitative goal is sufficient** (the responsibility for observable success criteria lies with the Intent Spec of each underlying `dev-workflow` cycle). Examples: "OAuth authentication is in a state ready for production operation", "the staged replacement of the payment platform has been completed".

## Scope boundary

{{scope}}

- The areas, modules, and target users covered by the entire roadmap
- The outermost perimeter of the milestones beneath it

## Out of scope

{{out_of_scope}}

- Areas intentionally not handled (handled by another roadmap later / responsibility of another team / explicitly skipped this time, etc.)
- Items that are already part of the `dev-roadmap` skill's overall non-scope (e.g. "roadmap-of-roadmaps (nesting beyond one level)", "having observable success criteria on the roadmap itself") do not need to be repeated here

## Strategic-level constraints

{{constraints}}

Constraints that affect the entire roadmap. Cycle-specific constraints belong to each cycle's Intent Spec, so this section lists only constraints that **span multiple cycles**.

- Technical constraints (allowed stack, compatibility, shared infrastructure, etc.)
- Organizational constraints (deadlines, staffing allocation, budget ceiling, maximum concurrent cycle count, etc.)
- Normative constraints (security, compliance, existing ADRs, upstream product policy, etc.)

## Milestone list

{{milestone_summary}}

The section finalized by `roadmap-planner` in Step 2 (Milestone Decomposition). One row per milestone with a one-line summary; details are split into `milestones/<milestone-id>.md` (one file per milestone).

| ID                 | Title                 | Estimated dev-workflow cycle count | Milestone dependencies     | Detail                             |
| ------------------ | --------------------- | ---------------------------------- | -------------------------- | ---------------------------------- |
| {{milestone_1_id}} | {{milestone_1_title}} | {{milestone_1_cycle_count}}        | {{milestone_1_depends_on}} | `milestones/{{milestone_1_id}}.md` |
| {{milestone_2_id}} | {{milestone_2_title}} | {{milestone_2_cycle_count}}        | {{milestone_2_depends_on}} | `milestones/{{milestone_2_id}}.md` |
| {{milestone_3_id}} | {{milestone_3_title}} | {{milestone_3_cycle_count}}        | {{milestone_3_depends_on}} | `milestones/{{milestone_3_id}}.md` |

<!-- Add as many rows as needed. Multiple rows are expected because the very premise of starting a roadmap is that the work does not fit into a single cycle. -->

## Dependency graph

{{dependency_graph}}

Diagram the dependencies between milestones using a Mermaid `graph LR`. Use the same notation already established in artifacts such as `task-plan.md`, and ensure the diagram renders fully under GitHub's standard renderer without depending on any extra renderer.

```mermaid
graph LR
  {{milestone_1_id}}[{{milestone_1_id}} {{milestone_1_short_title}}]
  {{milestone_2_id}}[{{milestone_2_id}} {{milestone_2_short_title}}]
  {{milestone_3_id}}[{{milestone_3_id}} {{milestone_3_short_title}}]
  {{milestone_1_id}} --> {{milestone_2_id}}
  {{milestone_2_id}} --> {{milestone_3_id}}
```

The recommended upper bound for node count is 15-20; if you exceed it, consider stage-splitting (for example, a separate graph per phase).

## Related links

{{references}}

- Related ADRs: General mode `docs/adr/` and the Roadmap mode `docs/roadmap/<roadmap-id>/adr/` under this roadmap (when filed)
- Related issues / tickets
- Upstream product plan / OKRs
- Related existing cycles (`docs/workflow/<identifier>/`, the `intent-spec.md` of relevant completed cycles, etc.)

## Open questions

{{open_questions}}

Strategic-level questions that could not be resolved in Steps 1-2. Questions handled by an underlying `dev-workflow` cycle's Step 1 (Intent Clarification) or Step 2 (Research) do not belong here; instead, explicitly state that they are delegated to the underlying cycle.
