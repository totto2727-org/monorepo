---
name: step-roadmap-intent
description: >
  [Main only] dev-roadmap Step 1 (Roadmap Intent). Capture the worldview, scope, success
  picture, and exclusions of the entire roadmap as the Intent section of `roadmap.md`,
  and initialise `roadmap-progress.yaml`. Main runs the dialogue with the user directly;
  no specialist subagent is invoked.
  Activation triggers: "Roadmap Intent", "roadmap intent clarification", "create roadmap.md",
  "initialise roadmap-progress.yaml", "dev-roadmap Step 1".
  Do NOT use for: milestone decomposition (`step-roadmap-decomposition`), roadmap retrospective
  (`step-roadmap-retrospective`), single-cycle development (`dev-workflow` directly), artifact
  format reference only (`share-artifacts`), `dev-workflow` cycle invocation (asymmetric coupling
  rule: `dev-roadmap` never auto-launches `dev-workflow`).
---

# Roadmap Step 1: Roadmap Intent

## Purpose

Articulate the worldview, problem scope, success picture, and exclusions for the entire
roadmap, and finalise them as the Intent section of `roadmap.md`. At the same time, initialise
`roadmap-progress.yaml` with the minimal skeleton (`roadmap_id`, `title`, `status: planned`,
empty `milestones: []`).

## Invocation: Main only

This step is **Main-only**: no specialist subagent is invoked. The justification is:

- **Dialogue work**: Step 1 is a dialogue with the user (eliciting intent, narrowing scope,
  iterating on the success picture). Main is best positioned to handle this directly because
  the user expects a single coherent counterpart.
- **No parallelism**: there is one Intent per roadmap. There is nothing to fan out.
- **No context-isolation justification**: the inputs (initial user request, repository
  summary) are small and fit comfortably in Main's window.
- **No independent-viewpoint justification**: this is the first step; there is no prior
  artifact to evaluate against.

Main therefore performs all the procedure below directly. No `agents/<role>.md` wrapper
exists for this step.

## Required inputs from Main

When Main begins this step, the following must be available:

- `<roadmap-id>` agreed with the user (kebab-case, may omit date prefix; see
  `dev-roadmap/SKILL.md` "Storage structure" for the naming rule).
- The initial user request (free-form description of the multi-cycle problem to solve).
- A short summary of the current repository state (existing related code paths, related
  ADRs, related project-specific skills).
- Path of `share-artifacts/templates/roadmap.md` and
  `share-artifacts/references/roadmap.md` (writing guide) — needed to fill the Intent
  section.
- Path of `share-artifacts/templates/roadmap-progress.yaml` and
  `share-artifacts/references/roadmap-progress-yaml.md` — needed to initialise the YAML.

If any item is missing, Main confirms with the user before starting work.

## Procedure

1. Confirm the `<roadmap-id>` does not collide with an existing
   `docs/roadmap/<roadmap-id>/` directory.
2. Create `docs/roadmap/<roadmap-id>/` and copy the templates into place
   (`roadmap.md` from `share-artifacts/templates/roadmap.md`,
   `roadmap-progress.yaml` from `share-artifacts/templates/roadmap-progress.yaml`).
3. Hold a dialogue with the user to elicit:
   - Background and motivation of the roadmap.
   - Strategic objective.
   - In-scope items (what the roadmap will tackle).
   - Out-of-scope items (what is explicitly excluded).
   - Success picture in observable form ("when does the roadmap count as done?").
   - Long-lived constraints that span multiple downstream cycles.
4. Fill in the Intent section of `roadmap.md` following
   `share-artifacts/references/roadmap.md`.
5. Initialise `roadmap-progress.yaml` with `roadmap_id`, `title`, `status: planned`,
   `created_at`, `updated_at` (ISO 8601 to-the-second), and an empty `milestones: []`.
6. If long-lived premises or constraints shared by multiple downstream `dev-workflow`
   cycles surface during the dialogue, file a **Roadmap mode ADR**
   (`docs/roadmap/<roadmap-id>/adr/<YYYY-MM-DD>-<title>.md`) per Main's judgment;
   see `share-adr/SKILL.md` "Mode decision flow". Link from `roadmap.md` to the new ADR.
7. Present the **finalised Intent section of `roadmap.md` itself** to the user (no
   temporary report — Artifact-as-Gate-Review). Verbally summarise how the Exit Criteria
   are satisfied.
8. After user approval, commit the artifacts.

## Expected artifacts

- `docs/roadmap/<roadmap-id>/roadmap.md` — Intent section (background / objective / scope /
  non-scope / success picture / constraints).
  Template: `share-artifacts/templates/roadmap.md`.
  Reference: `share-artifacts/references/roadmap.md`.
- `docs/roadmap/<roadmap-id>/roadmap-progress.yaml` — initialised with
  `status: planned` and empty `milestones: []`.
  Template: `share-artifacts/templates/roadmap-progress.yaml`.
  Reference: `share-artifacts/references/roadmap-progress-yaml.md`.
- (Optional) `docs/roadmap/<roadmap-id>/adr/<YYYY-MM-DD>-<title>.md` — Roadmap mode ADR
  if a long-lived shared premise was discovered. See `share-adr/SKILL.md`.

## Exit criteria

- The roadmap-wide scope and non-scope are written explicitly.
- The success picture is recorded in an observable form (i.e. a future reader can decide
  "yes, the roadmap is done").
- The user has agreed to the Intent section.
- `roadmap.md` and `roadmap-progress.yaml` are committed.
- **The CI run associated with this step's completion commit has PASSed** (on failure,
  retry up to 2 times by pushing fix commits → otherwise escalate to a Blocker; details
  in `share-ci-monitoring/SKILL.md`).

## Gate

**User approval required.** The user is shown the finalised Intent section of `roadmap.md`
itself; no separate temporary report is created (Artifact-as-Gate-Review).

## Failure modes / Rollback

These rollbacks originate from this step:

- **User answers stay ambiguous and the Intent will not converge** → Main continues the
  dialogue with the user (no specialist to "send back to"; Main owns the conversation).
- **The success picture is not observable** → Main consults the user to find a
  measurement angle and re-defines it.
- **Scope turns out to fit a single cycle** → Withdraw the roadmap and switch to a
  standalone `dev-workflow` cycle. Main proposes this to the user; the roadmap exits
  this skill entirely.

Cross-step rollbacks (e.g. issues discovered later that point back to Step 1) are
handled in the originating step; this section does not enumerate them.

## Commit conventions

One commit per step, including all Step 1 artifacts. Recommended message format
(project-specific commit conventions take precedence):

```
docs(dev-roadmap/<roadmap-id>): initialize roadmap
docs(dev-roadmap/<roadmap-id>): complete Step 1 (Roadmap Intent)
```

Stage files explicitly by path. Do **not** use `git add .` or `git add -A`
(`specialist-common` Git guardrail; the same rule applies to Main here).

## Sub-agent invocation reminder

This step is Main-only. **Main does the work directly without launching a `specialist-*`
subagent.** Main may freely orchestrate other specialists in subsequent steps (per the
plugin-wide sub-agent invocation rules in `README.md`), but inside this step there is no
nested specialist work.
