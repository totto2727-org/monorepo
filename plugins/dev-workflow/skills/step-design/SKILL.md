---
name: step-design
description: >
  [Main coordinator] Detail skill for dev-workflow Step 3 (Design). Read this
  when starting Step 3 of dev-workflow, when the user asks to "produce a design
  document", or when Main needs to launch the `architect` specialist. Defines
  how Main launches `architect` × 1 and integrates project-specific design
  skills (e.g. `effect-layer`, `effect-runtime`, `effect-hono`, `totto2727-fp`)
  into the design output. Includes the ADR escalation rule for decisions that
  cross the cycle boundary. Trigger phrases: "starting Step 3 of dev-workflow",
  "design step", "produce design.md".
  Do NOT use for: research (`step-research`), task decomposition
  (`step-task-decomposition`), specialist internals (`specialist-architect`),
  ADR format itself (`share-adr/SKILL.md`).
---

# Step 3: Design

## Purpose

Translate the Intent Spec and Research Notes into a coherent architecture, component layout, and implementation approach captured in `design.md`, escalating to an ADR only when the decision crosses the cycle boundary.

## Invocation

**Specialist:** `architect` × 1.

**Justification:**

- **Context isolation (C):** the combined Intent Spec + Research Notes + project-specific design skills form a large input set best handled in a dedicated specialist context. A single instance preserves design coherence (parallel architects would drift).

## Required inputs from Main

- `docs/workflow/<identifier>/intent-spec.md`.
- All `docs/workflow/<identifier>/research/*.md` from Step 2.
- Paths of relevant project-specific design skills (e.g. `effect-layer`, `effect-runtime`, `effect-hono`, `totto2727-fp`) — passed by Main as inputs to the specialist.
- `share-artifacts/references/design.md` and `share-artifacts/templates/design.md`.
- `share-adr/SKILL.md` (for cycle-crossing decisions).

## Procedure

1. Launch `architect` × 1 with the inputs above. Be explicit that project-specific skills override workflow defaults for design conventions (functional vs OOP, error model, dependency injection style, etc.) per `dev-workflow/SKILL.md` "Project-Rule Precedence".
2. Receive the draft `design.md`. Present it directly to the user (Artifact-as-Gate-Review). Do not produce a temporary summary.
3. Pass user feedback back to the **same** `architect` instance (no replacement) and iterate.
4. When a contested decision needs user judgment, raise an In-Progress inquiry (`$TMPDIR/dev-workflow/step3-*.md`) listing 3-5 alternatives.
5. If a decision crosses the cycle boundary (affects other cycles, other roadmaps, or the project as a whole), file an ADR via `share-adr` (General mode under `docs/adr/` or Roadmap mode under `docs/roadmap/<roadmap-id>/adr/` per the mode-decision flow in `share-adr/SKILL.md`).
6. Save the final `design.md` to `docs/workflow/<identifier>/design.md` and commit together with `progress.yaml` (and any newly filed ADR).

## Expected artifacts

- `docs/workflow/<identifier>/design.md` — populated from `share-artifacts/templates/design.md`, following `share-artifacts/references/design.md`.
- (Conditional) `docs/adr/<YYYY-MM-DD-title>.md` or `docs/roadmap/<roadmap-id>/adr/<YYYY-MM-DD-title>.md` per `share-adr/SKILL.md`.
- `docs/workflow/<identifier>/progress.yaml` — `completed_steps`, `artifacts.design`, `artifacts.external_adrs[]` updated.

### When to file an ADR

File an ADR only for decisions that **do not complete inside this cycle** — that is, decisions affecting other cycles, other roadmaps, or the project as a whole, or shared norms across cycles inside one roadmap.

| File an ADR (cycle-crossing) | Do not file (cycle-internal) |
| ---------------------------- | ---------------------------- |
| "Adopt Effect for the whole project" (General) | "Use LRU as the cache strategy for this feature" |
| "Use gRPC across all services" (General) | "Use cursor-based pagination for this API" |
| "Standardize authorization on OpenFGA" (General) | "Use zod for validation on this screen" |
| "Cache-layer separation policy shared by independent dev-workflow cycles" (General) | "Naming convention for transient keys inside this cycle" |
| "`AuthSession` type definition shared across the `oauth-rollout` roadmap" (Roadmap) | "Wording of the session guard message for this cycle" |

Mode quick reference:

- **General mode** (`docs/adr/<YYYY-MM-DD-title>.md`): no roadmap context, or applies to multiple roadmaps / independent cycles / the whole project.
- **Roadmap mode** (`docs/roadmap/<roadmap-id>/adr/<YYYY-MM-DD-title>.md`): shared norm across cycles inside a single roadmap (use when `progress.yaml.roadmap.id` is set and the decision applies only inside that roadmap).

When an ADR is filed: list its path under `progress.yaml.artifacts.external_adrs` (General and Roadmap modes are listed in the same array; the ADR's frontmatter identifies the scope) and link from `design.md` to the ADR.

## Exit criteria

- `design.md` and the updated `progress.yaml` are committed (any newly filed ADR ships in the same commit).
- For each major design decision, alternatives considered and rationale are recorded.
- The user has approved the design direction.
- The CI run linked to this step's completion commit has passed (with up to 2 retry attempts; otherwise the failure is escalated to a Blocker per `share-ci-monitoring`).

## Gate

User approval (mandatory). The user reviews `design.md` directly.

## Failure modes / Rollback

| Cause | Action / Target step |
| ----- | -------------------- |
| Design diverges from intent | Send feedback to the same `architect` instance to revise. If divergence is fundamental, roll back to Step 1. |
| Research Notes cannot support the design | Roll back to Step 2; keep the current `architect` instance alive while additional Research returns. |
| Project-specific rule conflicts with workflow defaults | Halt and raise an In-Progress user inquiry — never resolve unilaterally. |

## Commit conventions

- `docs(dev-workflow/<identifier>): complete Step 3 (Design)` — `design.md` + `progress.yaml` in one commit; if an ADR is filed in the same step it ships in the same commit.

## Parallelism notes

Single instance only. Design coherence is the priority; parallel architects would diverge and require manual reconciliation.

## Sub-agent invocation rule reminder

Per the README "Sub-agent invocation rules", only Main launches additional or replacement specialists. The running `architect` reports a Blocker rather than spawning a peer. ADR filing is a documentation step performed under Main's coordination; it is not a sub-agent invocation.
