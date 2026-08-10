# Roadmap Authoring Guide

> Document type: concrete artifact authoring guide.

## Purpose

A roadmap is a strategic agreement for work that must be divided into multiple milestones. It records why the work is too large for one implementation effort, what is in scope, the shared constraints, and the dependency order. Implementation details and executable success criteria belong to each milestone's implementation plan.

## Location

Write the artifact to `docs/roadmap/<roadmap-id>/roadmap.md`. Keep implementation-specific artifacts elsewhere and link them through stable roadmap, milestone, or workflow identifiers.

## Content

### Background

Explain why the roadmap is needed now and why one implementation effort is insufficient.

### Purpose

State the desired end state in one to three sentences. Keep it qualitative; milestone owners define observable verification criteria when planning implementation.

### Scope

Name the modules, features, users, and environments covered by the roadmap. State exclusions explicitly so later milestones cannot silently expand the boundary.

### Constraints

Include only constraints shared by multiple milestones, such as compatibility requirements, deadlines, capacity limits, security policy, or applicable ADRs. Keep milestone-local constraints in the milestone or its implementation plan.

### Milestones

Use one row per milestone with these fields:

- Stable ID matching `progress.yaml.milestones[].id`.
- One-line title.
- Estimated implementation-effort count.
- Dependency IDs.
- Relative link to `milestones/<milestone-id>.md`.

Keep each milestone's details in its own file.

### Dependency graph

Use a Mermaid `graph LR` that contains the same milestone IDs and edges as the milestone list. The graph must be acyclic. Split a graph that is too dense to review reliably.

```mermaid
graph LR
  ms-01[ms-01 foundation]
  ms-02[ms-02 feature]
  ms-03[ms-03 integration]
  ms-01 --> ms-02
  ms-02 --> ms-03
```

### Links

Link applicable ADRs, issues, product plans, and prior work. Keep unresolved strategic questions here; move implementation questions to the owning milestone.

## Quality criteria

- The background explains why multiple milestones are necessary.
- Scope and exclusions establish a clear boundary.
- The milestone list and dependency graph agree.
- Shared constraints are separated from implementation details.
- Every milestone links to one independently reviewable milestone file.

## Related documents

- [Milestone Authoring Guide](milestone.md)
- [Roadmap Retrospective Authoring Guide](roadmap-retrospective.md)
- [Shared Artifact Storage](storage.md)
