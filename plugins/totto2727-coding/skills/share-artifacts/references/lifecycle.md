# Shared Artifact Lifecycle

> Document type: concrete artifact lifecycle policy.

## Creation

1. Select the guide and same-named template from `share-artifacts`.
2. Copy the template to the location specified by the guide.
3. Replace every placeholder or mark it explicitly as not applicable.
4. Review the artifact against the guide's quality criteria.
5. When approval is required, present the artifact itself for review.

## Persistence

Commit an approved artifact with the work that establishes it. Use the owning CLI for machine-managed state such as `progress.yaml`.

When resuming roadmap work, restore context from `roadmap.md`, `milestones/`, applicable ADRs, the roadmap retrospective when present, and CLI-managed state.
