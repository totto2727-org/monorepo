# Roadmap Retrospective: {{roadmap_id}}

- **Roadmap ID:** {{roadmap_id}}
- **Writer:** {{roadmap_retrospective_writer_instance_id}}
- **Created at:** {{created_at}}
- **Roadmap started at:** {{roadmap_started_at}}
- **Roadmap completed at:** {{roadmap_completed_at}}
- **Duration:** {{duration}}

This document is the **retrospective for the roadmap as a whole**, drafted by the `roadmap-retrospective-writer` Specialist during `roadmap` **Step 4 (Roadmap Retrospective)**. It aggregates each underlying oh-my-codingagent execution cycle's `retrospective.md` and adds roadmap-specific themes (a summary of milestone completion / soundness of the dependency graph / improvement proposals specific to roadmaps). Place it at `docs/retrospective/roadmap-<roadmap-id>.md` (aggregation form, with the `roadmap-` prefix). See `share-artifacts/references/roadmap-retrospective.md` for authoring details.

## Roadmap overview

{{roadmap_summary}}

Describe in 1-3 paragraphs what the roadmap as a whole accomplished against the purpose stated in `roadmap.md`.

## Summary of milestone completion

{{milestone_completion_summary}}

List the final state of `progress.yaml.milestones[]` and describe the rationale for each milestone's completion / non-completion / blocked / cancelled judgment.

| Milestone ID       | Title                 | Final Status           | Rationale for the completion judgment | Related totto2727-dev-flow `<identifier>` |
| ------------------ | --------------------- | ---------------------- | ------------------------------------- | ----------------------------------------- |
| {{milestone_1_id}} | {{milestone_1_title}} | {{milestone_1_status}} | {{milestone_1_completion_rationale}}  | {{milestone_1_workflow_identifiers}}      |
| {{milestone_2_id}} | {{milestone_2_title}} | {{milestone_2_status}} | {{milestone_2_completion_rationale}}  | {{milestone_2_workflow_identifiers}}      |
| {{milestone_3_id}} | {{milestone_3_title}} | {{milestone_3_status}} | {{milestone_3_completion_rationale}}  | {{milestone_3_workflow_identifiers}}      |

<!-- Add as many rows as needed. Judge each milestone against the "Outcomes (qualitative)" section of `milestones/<milestone-id>.md`. -->

## Retrospective on the dependency graph

{{dependency_graph_review}}

Look back at the milestone dependency graph finalized in Step 2 and ask whether it remained sound after execution. Aspects to consider:

- Dependencies that worked as expected (root and convergence points were appropriate)
- Unnecessary dependencies discovered during execution (it turned out that milestone A did not depend on B, but the dependency forced unnecessary serialization)
- Missing dependencies discovered during execution (milestone C implicitly required D, but the absence of that dependency forced rework in later cycles)
- Effective vs. theoretical parallelism (theoretical parallelism vs. the actual number of cycles launched in parallel)

## Aggregation of underlying oh-my-codingagent execution cycles

{{workflow_aggregation}}

Summarize each underlying oh-my-codingagent execution cycle's `docs/retrospective/<identifier>.md` in **one paragraph per cycle**. Each paragraph must include:

- The cycle `<identifier>`
- The id of the milestone it is attached to
- Up to 1-2 standout "what went well" / "issues" items observed in that cycle alone
- A link to that cycle's retrospective

### {{workflow_identifier_1}} (milestone: {{milestone_1_id}})

{{workflow_summary_1}}

Reference: `docs/retrospective/{{workflow_identifier_1}}.md`

### {{workflow_identifier_2}} (milestone: {{milestone_2_id}})

{{workflow_summary_2}}

Reference: `docs/retrospective/{{workflow_identifier_2}}.md`

<!-- Repeat for the number of underlying cycles -->

## Improvement proposals specific to the roadmap layer

{{roadmap_specific_improvements}}

Improvement proposals for the roadmap layer (the `roadmap` skill / the `progress.yaml` schema / milestone decomposition granularity, etc.). Improvement proposals that are self-contained inside an underlying cycle are already written in that cycle's `retrospective.md`, so this section contains only the strategic-level improvements derived from aggregating those.

### Proposed `progress.yaml` schema extensions

- {{schema_improvement_1}}
- {{schema_improvement_2}}

### Retrospective on milestone decomposition granularity

- {{decomposition_review_1}}
- {{decomposition_review_2}}

### Reassessment of the "step-level reflection" scope-out (re-evaluation of the current version's scope policy)

{{step_level_progress_review}}

In the current version, "(b) reflecting per-step progress summaries" was scoped out of `progress.yaml`. After running real workloads, evaluate whether this policy was sound or whether an extension is needed. If needed, draft a schema extension proposal (`events` array / `last_step` field, etc.) for the next roadmap.

### Retrospective on the `roadmap` ↔ `totto2727-dev-flow` integration protocol

- {{coupling_review_1}}
- {{coupling_review_2}}

## Handoff to the next roadmap

{{handoff_to_next_roadmap}}

Insights that may help when launching a similar roadmap next, reusable milestone patterns, and pitfalls to avoid.

## Retrospective on user approval gates

{{gate_retrospective}}

Look back at the approve / reject record at each approval gate (Step 1: Roadmap Intent / Step 2: Milestone Decomposition / Step 4: Roadmap Retrospective) and the cause of any rejections.

- Step 1 (Roadmap Intent): {{gate_1_summary}}
- Step 2 (Milestone Decomposition): {{gate_2_summary}}
- Step 4 (Roadmap Retrospective): {{gate_4_summary}}

## Cost / time

{{cost_time}}

- Total elapsed days for the roadmap: {{total_duration}}
- Number of underlying oh-my-codingagent execution cycles: {{workflow_count}}
- Effective parallelism: {{effective_parallelism}}
- Number of Specialist launches (roadmap-related only): {{roadmap_specialist_launch_count}}
