# ADR Authoring Guide

> Document type: concrete artifact authoring guide.

## Purpose

An ADR preserves a durable decision that affects multiple implementation efforts, multiple milestones, or the project as a whole. Local design decisions remain in their implementation design artifact, and observations remain in retrospectives.

## Location

Use [ADR Modes](../../share-adr/references/modes.md) to choose one location:

- General: `docs/adr/<YYYY-MM-DD>-<title>.md`
- Roadmap: `docs/roadmap/<roadmap-id>/adr/<YYYY-MM-DD>-<title>.md`

Use a short kebab-case title. The `scope` frontmatter value must match the storage path.

## Frontmatter

```yaml
---
confirmed: false
scope: general | roadmap:<roadmap-id>
---
```

Set `confirmed: true` only after the decision owner approves the record.

## Content

### Context

Explain why the decision is needed, its applicable scope, existing constraints, and the forces that make a durable shared decision necessary.

### Decision

State the selected option precisely. Compare the viable alternatives and explain why each was accepted or rejected. Do not add placeholder alternatives merely to reach a fixed count.

### Consequences

Describe what is added, what existing work must change, and which constraints future work must respect. Include costs and limitations as well as benefits.

### Related records

Link prior ADRs and every roadmap, milestone, or implementation design that directly depends on this decision. Omit the section when no related record exists.

## Confirmation

A confirmed ADR is immutable except for a supersession addendum appended at the end:

```markdown
> Superseded by [<new ADR title>](path-to-new-adr)
```

The replacement ADR carries the active decision and links back to the superseded record.

## Quality criteria

- Context states the decision's scope explicitly.
- Alternatives are real and their tradeoffs are evidence-based.
- The decision is specific enough for later work to follow.
- Consequences include migration cost and future constraints.
- Filename, frontmatter scope, and storage location agree.
- Dependent artifacts link to the ADR.

## Related documents

- [ADR Filing](../../share-adr/references/filing.md)
- [ADR Immutability](../../share-adr/references/immutability.md)
- [ADR References](../../share-adr/references/references.md)
