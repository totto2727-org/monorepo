# ADR References

> Document type: concrete ADR reference policy.

## Before implementation

- For independent work, read applicable ADRs in `docs/adr/`.
- For work under a roadmap, read applicable ADRs in both `docs/adr/` and `docs/roadmap/<roadmap-id>/adr/`.
- Do not implement a design that contradicts a `confirmed: true` ADR. File a superseding ADR before changing the established decision.

## Linking

- Link an ADR from the design, roadmap, or milestone that depends on it.
- When roadmap state tracks ADR paths, update that state through its owning CLI.
- During roadmap definition or milestone decomposition, file a Roadmap ADR for a durable premise shared within that roadmap.
- During a retrospective, extract a durable cross-effort decision into an ADR; keep observations and improvement ideas in the retrospective.

## Boundary with retrospectives

| Artifact      | Content                                                 | Lifecycle                                                                    |
| ------------- | ------------------------------------------------------- | ---------------------------------------------------------------------------- |
| ADR           | A decision, its context, alternatives, and consequences | Persistent; immutable after confirmation except for a supersession addendum. |
| Retrospective | Observations, causes, and proposed improvements         | Retained only as long as its findings remain useful.                         |
