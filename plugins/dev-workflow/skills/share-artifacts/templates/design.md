# Design Document: {{title}}

- **Identifier:** {{identifier}}
- **Author:** {{architect_instance_id}}
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}
- **Status:** {{status}} <!-- draft | approved -->

## Design goals and constraints

{{goals_and_constraints}}

Bring in the purpose, success criteria, and constraints from the Intent Spec to make the premises behind every design decision explicit.

- **Purpose (from Intent Spec):** {{purpose_quote}}
- **Success criteria:** {{success_criteria_quote}}
- **Key constraints:** {{constraints_quote}}

## Approach overview

{{approach_overview}}

Describe the overall shape of the chosen approach in 1-3 paragraphs. Include the core reason this approach was selected.

## Component breakdown

{{components}}

List the major components, modules, and layers, and describe their responsibilities. Embed diagrams (Mermaid, etc.) where helpful.

```mermaid
{{component_diagram}}
```

### Key types and interfaces

{{key_types}}

```typescript
{
  {
    type_definitions_example
  }
}
```

## Data flow / API design

{{data_flow}}

Describe the request paths, data transformations, and API signatures.

### API endpoints

| Method | Path     | Description | Request | Response |
| ------ | -------- | ----------- | ------- | -------- |
| {{m}}  | {{path}} | {{desc}}    | {{req}} | {{resp}} |

## Alternatives and rationale for the chosen approach

{{alternatives}}

State the alternatives that were considered and the reason each one was rejected, in table form.

| Option       | Summary              | Adopted / Rejected | Rationale              |
| ------------ | -------------------- | ------------------ | ---------------------- |
| {{option_a}} | {{option_a_summary}} | Adopted            | {{option_a_rationale}} |
| {{option_b}} | {{option_b_summary}} | Rejected           | {{option_b_rationale}} |
| {{option_c}} | {{option_c_summary}} | Rejected           | {{option_c_rationale}} |

## Anticipated extension points

{{extension_points}}

Describe areas where future extension is anticipated, along with the interfaces and abstractions reserved in the current design to make those extensions feasible.

## Operational considerations

{{operational_considerations}}

- **Monitoring / observability:** {{observability}}
- **Migration / cutover:** {{migration_strategy}}
- **Rollout:** {{rollout_plan}}
- **Rollback:** {{rollback_strategy}}
- **Security:** {{security_considerations}}
- **Performance expectations:** {{performance_expectations}}

## References to ADRs that span beyond this cycle

{{external_adrs}}

Link to any ADRs filed during this cycle or any pre-existing ADRs (General mode `docs/adr/` / Roadmap mode `docs/roadmap/<roadmap-id>/adr/`). Cycle-local decisions should remain self-contained inside this document (see `share-adr/SKILL.md` "Mode determination flow" for details).

- [{{adr_title}}]({{adr_path}})

## Handoff notes for Task Decomposition

{{handoff_notes}}

Spell out the design decisions that the `planner` should consult during Step 4 (Task Decomposition). Include hints about task granularity and parallelism opportunities.
