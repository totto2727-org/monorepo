---
confirmed: false
scope: { { scope } } # general | roadmap:<roadmap-id>
---

# ADR: {{title}}

- **Filed at:** {{filed_at}} <!-- YYYY-MM-DD -->
- **Filer:** {{filer}} <!-- Main / architect / roadmap-analyst / etc. -->
- **Originating step:** {{originating_step}} <!-- e.g. totto2727-dev-flow Step 3 / roadmap Step 2 -->
- **Storage path:** {{storage_path}} <!-- docs/adr/<file>.md or docs/roadmap/<roadmap-id>/adr/<file>.md -->

## Context

{{context}}

State why this decision is needed. **Make the scope range explicit**: which roadmap, which workflows, or which project-wide norm it applies to. Quote any pre-existing constraints (Intent Spec, prior ADRs, external requirements) that frame the decision.

## Decision

{{decision}}

State the specific decision (table design / API design / route design / library adoption / policy declaration / etc.). Compare 2-3 alternatives in table form to back the rationale.

| Option       | Summary              | Adopted / Rejected | Rationale              |
| ------------ | -------------------- | ------------------ | ---------------------- |
| {{option_a}} | {{option_a_summary}} | Adopted            | {{option_a_rationale}} |
| {{option_b}} | {{option_b_summary}} | Rejected           | {{option_b_rationale}} |
| {{option_c}} | {{option_c_summary}} | Rejected           | {{option_c_rationale}} |

## Consequences

{{consequences}}

The scope of impact arising from this decision.

- **Newly added:** {{newly_added}} <!-- new tables / modules / routes / conventions -->
- **Existing impact:** {{existing_impact}} <!-- existing code / operations that must change -->
- **Constraints going forward:** {{constraints_going_forward}} <!-- invariants future cycles must respect -->

## Related

{{related}}

Bullet list of links to related existing ADRs, `roadmap.md`, `milestones/<id>.md`, or `design.md`. Omit the section if not applicable.

- [{{related_title}}]({{related_path}})

<!--
  Supersession addendum (only allowed change to a `confirmed: true` ADR):
  > Superseded by [<new ADR title>](<path-to-new-adr>)
  Append a single line at the very bottom; do not edit any other content.
-->
