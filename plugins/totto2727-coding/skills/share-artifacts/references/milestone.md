# Milestone Authoring Guide

> Document type: concrete artifact authoring guide.

## Purpose

A milestone defines one independently reviewable part of a roadmap. It translates roadmap strategy into a bounded outcome that can be expanded into an implementation plan with executable verification criteria.

## Location

Write one file per milestone at `docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md`. The milestone ID must match both the roadmap milestone list and `progress.yaml.milestones[].id`.

## Content

### Purpose

Describe the state this milestone is intended to reach in one or two sentences. Do not prescribe implementation details.

### Outcomes

List qualitative observations that allow a reviewer to judge whether the intended state was reached. Concrete test commands and measurable acceptance criteria belong to the implementation plan.

### Scope

Name the modules, features, users, and environments that the implementation may change. List exclusions explicitly, including work owned by another milestone.

### Dependencies

List every milestone that must complete first and give a short reason. Use `(none)` for a root milestone. Keep the IDs identical to `progress.yaml.milestones[].depends_on[]`.

### Implementation links

`progress.yaml.milestones[].workflow_identifiers[]` is the primary record for linked implementation efforts. A milestone may repeat those identifiers as a human-readable aid, but must not contradict the CLI-managed state.

### Estimated effort count

Record how many independent implementation efforts are expected. One is preferred. Explain any split and reconsider the milestone boundary when four or more efforts are expected.

### Notes

Include only milestone-specific context that is not represented in `progress.yaml`. Do not duplicate machine-managed state.

## Integration milestone

A roadmap may use its final milestone for integration verification across earlier milestones. Define it as a normal milestone with explicit dependencies, scope, outcomes, and implementation ownership. Use this pattern only when cross-milestone behavior requires verification beyond the checks owned by each preceding milestone.

## Quality criteria

- The purpose is qualitative and implementation-neutral.
- Scope and exclusions prevent overlap with sibling milestones.
- Dependency IDs match the roadmap and CLI-managed state.
- One file describes exactly one milestone.
- Any multi-effort split has a concrete rationale.

## Related documents

- [Roadmap Authoring Guide](roadmap.md)
- [Roadmap Retrospective Authoring Guide](roadmap-retrospective.md)
