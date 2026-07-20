---
name: roadmap-decomposition
description: >
  [Main only] roadmap Step 2 (Milestone Decomposition). Split the roadmap into observable
  milestones, render the dependency graph in Mermaid, generate one `milestones/<milestone-id>.md`
  per milestone, and finalise `progress.yaml.milestones[]`. Main performs the
  decomposition directly; no specialist subagent is invoked.
  Activation triggers: "Milestone Decomposition", "milestone decomposition", "create milestones/*.md",
  "finalise progress.yaml.milestones[]", "roadmap Step 2".
  Do NOT use for: roadmap intent (`roadmap-intent`), roadmap retrospective
  (`roadmap-retrospective`), in-cycle task decomposition owned by a workflow-level agent,
  workflow-level execution invocation (asymmetric coupling rule),
  roadmap-of-roadmaps (out of scope), CI / external system integration.
---

# Roadmap Step 2: Milestone Decomposition

## Purpose

Split the roadmap into observable milestones, make the dependency graph explicit, and finalise the milestone-level entries inside `progress.yaml`. Each milestone should correspond roughly to one downstream workflow-level execution (1:N is allowed: one milestone may later have multiple executions attached).

## Invocation: Main only

This step is **Main-only**: no specialist subagent is invoked.

- **Aggregation work**: decomposition is a single-pass aggregation across the whole
  Intent. There is no parallelism to fan out.
- **No context-isolation justification**: the input (`roadmap.md` Intent + project-specific
  skills) fits comfortably in Main's window.
- **No independent-viewpoint justification**: Main both authors the decomposition and
  validates it with the user; there is no second evaluator role.
- **Iterative dialogue with the user**: refining milestone granularity, ordering, and
  dependencies is back-and-forth with the user, which Main handles directly.

Main therefore performs all the procedure below directly. No `agents/<role>.md` wrapper exists for this step.

## Required inputs from Main

- `<roadmap-id>` and `roadmap.md` Intent section (output of Step 1).
- `progress.yaml` initialised by Step 1 (`status: planned`, `milestones: []`).
- Paths of relevant project-specific skills (e.g. `coding`, `git-workflow`, etc.) so milestone granularity respects project implementation and test conventions (`specialist-common §0`: project-rule precedence).
- Path of `share-artifacts/templates/milestone.md` and `share-artifacts/references/milestone.md` (writing guide).
- Path of `share-artifacts/templates/roadmap.md` and `share-artifacts/references/roadmap.md` — for appending the milestone list and dependency graph to the existing `roadmap.md`.
- Roadmap CLI available for updating `progress.yaml.milestones[]`.

If any item is missing, Main confirms with the user before starting work.

## Procedure

1. Read `roadmap.md` Intent section and the listed project-specific skills.
2. Identify candidate milestones with each milestone roughly the size of one downstream workflow-level execution.
3. Define dependencies between milestones as a DAG. Render the graph in Mermaid (`graph LR`).
4. Identify which milestones can run in parallel.
5. For each milestone, generate `docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md` following `share-artifacts/references/milestone.md`. Each file states the completion criteria so a future reader can decide when the milestone transitions to `completed`.
6. Append the milestone list and the Mermaid dependency graph to `roadmap.md`.
7. Use the roadmap CLI to finalise `progress.yaml.milestones[]` with one entry per milestone:
   - `id`, `title`, `status: planned`
   - `depends_on: [<milestone-id>, ...]` (DAG edges)
   - `workflow_identifiers: []` (empty; downstream workflow-level executions will fill this)
   - `notes: null`
8. Transition the roadmap-wide `status` from `planned` to `active`.
9. If norms shared across multiple downstream executions surface during decomposition (e.g. a common API contract, a shared data model, a shared error-handling policy), file a **Roadmap mode ADR** (`docs/roadmap/<roadmap-id>/adr/`) per Main's judgment; see `share-adr/SKILL.md`. Link from the affected `milestones/<id>.md` to the ADR.
10. Present the **finalised `roadmap.md` (with milestones) and the `milestones/<milestone-id>.md` files themselves** to the user (no temporary report — Artifact-as-Gate-Review). The user's approval also constitutes agreement to start execution (Step 3).
11. After user approval, commit the artifacts.

## Expected artifacts

- `docs/roadmap/<roadmap-id>/roadmap.md` — milestone list and Mermaid dependency graph appended to the Step 1 output.
  Template: `share-artifacts/templates/roadmap.md`.
  Reference: `share-artifacts/references/roadmap.md`.
- `docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md` — one file per milestone.
  Template: `share-artifacts/templates/milestone.md`.
  Reference: `share-artifacts/references/milestone.md`.
- `docs/roadmap/<roadmap-id>/progress.yaml` — `milestones[]` finalised; roadmap `status: active`.
  Managed by the roadmap CLI.
- (Optional) `docs/roadmap/<roadmap-id>/adr/<YYYY-MM-DD>-<title>.md` — Roadmap mode ADR if a cross-execution shared norm was discovered.

## Exit criteria

- Each milestone is small enough to be completed by roughly one downstream `totto2727-dev-flow` cycle.
- Inter-milestone dependencies are an explicit DAG rendered in Mermaid (`graph LR`).
- Milestones eligible to run in parallel are identified.
- Each `milestones/<milestone-id>.md` records a completion criterion (when does it transition to `completed`?).
- The user has agreed to the decomposition (= execution-start agreement).
- `roadmap.md`, all `milestones/*.md`, and `progress.yaml` are committed.
- Any CI / PR verification required by the surrounding execution system has completed; detailed CI handling is delegated to that system.

## Gate

**User approval required** (= agreement to start execution).

## Failure modes / Rollback

These rollbacks originate from this step:

- **Milestone granularity is wrong** (too coarse / too fine) → Main re-decomposes within the step (no specialist to "send back to"); ask the user for the granularity criterion if needed.
- **Dependencies are unsolvable** → Roll back to Step 1 to revise the Intent's scope.
- **Only 1–2 milestones emerge** → Roll back to Step 1 to re-evaluate whether a roadmap is needed at all (a single workflow-level execution may suffice).

Cross-step rollbacks (e.g. issues discovered in Step 3 that point back here) are handled in the originating step.

## Commit conventions

One commit per step, including all Step 2 artifacts. Recommended message format (project-specific commit conventions take precedence):

```
docs(roadmap/<roadmap-id>): complete Step 2 (Milestone Decomposition)
```

Stage files explicitly by path (do not use `git add .` / `git add -A`).

## Sub-agent invocation reminder

This step is Main-only. **Main does the work directly without launching a `specialist-*` subagent.** Main may freely orchestrate other specialists in subsequent steps (per the plugin-wide sub-agent invocation rules in `README.md`), but inside this step there is no nested specialist work.
