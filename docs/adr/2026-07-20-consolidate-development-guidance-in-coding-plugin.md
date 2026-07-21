---
confirmed: true
scope: general
---

# ADR: consolidate durable development guidance in totto2727-coding

- **Filed at:** 2026-07-20
- **Decision owner:** repository owner
- **Origin:** plugin inventory and documentation audit
- **Storage path:** `docs/adr/2026-07-20-consolidate-development-guidance-in-coding-plugin.md`

## Context

`totto2727-dev-flow` combined durable document formats with roadmap orchestration that is no longer maintained in this repository. `totto2727-coding` also combined shared principles, language-specific implementation rules, and test-design reporting behind broad skill entrypoints. These boundaries made skill activation imprecise and allowed deleted workflow roles, step numbers, and cross-document section references to leak into otherwise reusable documents.

## Decision

Delete `totto2727-dev-flow`. Move only its reusable ADR and artifact guidance into `totto2727-coding`, and keep roadmap execution orchestration outside both plugins. Split coding and testing guidance by responsibility:

- `share-coding` and `share-test` own language-independent principles in their `SKILL.md` files.
- `js-coding`, `mbt-coding`, `js-test`, and `mbt-test` index concrete language-specific practices.
- `share-test-design-flow` owns concrete test design and human-facing reports.
- `share-adr` owns ADR policy, while `share-artifacts` owns artifact authoring guides and templates.
- `docs-moonbit` and `docs-components-build` remain generated specification skills.

| Option                              | Summary                                                                         | Result   | Rationale                                                                                                                   |
| ----------------------------------- | ------------------------------------------------------------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------- |
| Keep a separate workflow plugin     | Retain roadmap roles, steps, and artifact ownership in `totto2727-dev-flow`.    | Rejected | The orchestration layer is being removed, and its role vocabulary makes reusable documents dependent on a deleted workflow. |
| Consolidate durable guidance        | Move reusable policies and templates into focused `totto2727-coding` skills.    | Adopted  | Each skill has a discoverable responsibility without importing an execution system.                                         |
| Delete all workflow-owned documents | Remove ADR, roadmap, milestone, retrospective, and QA guidance with the plugin. | Rejected | The document formats remain useful independently of the removed orchestration.                                              |

## Consequences

- **Added:** focused shared, JavaScript, MoonBit, test-design, ADR, and artifact skill entrypoints.
- **Existing impact:** marketplace entries and repository links now target `totto2727-coding`; old broad skill names and workflow-specific roles are removed from current guidance.
- **Future constraints:** conceptual guidance and concrete procedures remain distinct; documents reference another document by skill or filename and title rather than cross-file chapter numbers.
- **Costs and limitations:** historical workflow ADRs remain as immutable records and require supersession links; roadmap execution itself has no replacement skill in this plugin.

## Related records

- [Coding plugin consolidation](2026-05-04-totto2727-coding-plugin-consolidation.md)
- [Artifact-driven workflow plugin](2026-04-24-artifact-driven-agent-workflow-plugin.md)
- [QA design workflow boundary](2026-04-26-dev-workflow-qa-design-step.md)
- [Roadmap strategic layer](2026-04-29-roadmap-strategic-layer.md)
- [External review responsibility](2026-04-29-external-review-absorbs-self-review.md)
- [Roadmap PR and CI observability](2026-05-03-pr-and-ci-roadmap-observability.md)
