---
confirmed: true
---

# ADR: rename `ai-dlc` plugin to `dev-workflow` and flatten phases into a step list

## Context

The plugin currently published as `plugins/ai-dlc/` borrows the term "AI-DLC" and the three-phase shape (`Inception` → `Construction` → _third phase_) from Raja SP / AWS's _AI-Driven Development Lifecycle_ paper. A prior draft ADR attempted to reconcile this by positioning the plugin as a "derivative" of AWS AI-DLC, but on inspection the divergences are too large for that framing to be useful:

- **Operations** phase replaced with **Verification** (deployment / observability / SLA prediction / runbook integration are entirely absent).
- **Mob Elaboration / Mob Construction** rituals replaced with parallel specialist subagent invocation.
- **Bolt** iteration concept, **Unit** artifact, and **Domain Design / Logical Design** separation all dropped.
- **Deployment Units** artifact dropped.
- **DDD / BDD / TDD flavor** selection mechanism dropped.
- **Role consolidation under principle 8** inverted: nine specialist agents instead of consolidated Product Owner + Developer.
- **Recursive Level 1 → Level N decomposition** flattened to a single Task Decomposition step.
- **Steps original to the plugin** with no source counterpart: Research, Self-Review, External Review, Retrospective.

Two additional structural problems surfaced when applying the plugin in practice:

1. **The phase concept (Inception / Construction / Verification) adds friction** in an AI-specialist-parallel execution model. Phases were originally a human-team coordination mechanism (handoffs, ceremonies, schedule milestones). The plugin's specialists are stateless subagents that finish their step and terminate; the natural coordination unit is **the step**, not the phase. Phase-level exit checklists, phase-level approval gates, and the three `main-inception` / `main-construction` / `main-verification` skills are coordination overhead that does not pay for itself.
2. **The "AI-DLC" brand keeps inviting parity questions** that don't apply (e.g. "where is the Operations phase?", "where is Mob Elaboration?"). Maintaining the name forces continuous explanation of what is and isn't borrowed.

## Decision

Two coupled decisions are recorded here. They are taken together because either one alone leaves the other in an awkward state.

### 1. Rename `ai-dlc` plugin to `dev-workflow`

- Plugin directory: `plugins/ai-dlc/` → `plugins/dev-workflow/`
- Marketplace entry: `ai-dlc` → `dev-workflow` in `.claude-plugin/marketplace.json`
- Enabled-plugins entry: `ai-dlc@totto2727` → `dev-workflow@totto2727` in `.claude/settings.json`
- All cross-references inside skills, agents, and templates updated to the new name
- No "successor of AI-DLC" or "derivative of AI-DLC" claim is published. AWS AI-DLC may be cited as one of several inspirations in a single sentence in the plugin description, but the plugin is **not** positioned as an AI-DLC implementation, derivative, or variant.

### 2. Flatten the three-phase model into a single step list

The phase concept (`Phase 1 Inception` / `Phase 2 Construction` / `Phase 3 Verification`) is removed. The workflow is expressed as a **flat sequence of nine steps** with explicit predecessor / successor / rollback relationships.

#### Step list (post-flatten)

| Step | Name                 | Specialist                 | Approval gate | Output (committed)      |
| ---- | -------------------- | -------------------------- | ------------- | ----------------------- |
| 1    | Intent Clarification | `intent-analyst`           | User          | `intent-spec.md`        |
| 2    | Research             | `researcher` (parallel N)  | Main          | `research/<topic>.md`   |
| 3    | Design               | `architect`                | User          | `design.md`             |
| 4    | Task Decomposition   | `planner`                  | User          | `task-plan.md`          |
| 5    | Implementation       | `implementer` (parallel N) | Main          | code diffs + `TODO.md`  |
| 6    | Self-Review          | `self-reviewer`            | Main          | `self-review-report.md` |
| 7    | External Review      | `reviewer` (parallel N)    | User          | `review/<aspect>.md`    |
| 8    | Validation           | `validator`                | User          | `validation-report.md`  |
| 9    | Retrospective        | `retrospective-writer`     | Main          | `retrospective.md`      |

Each step carries its own:

- Pre-conditions (which prior steps must be `completed`).
- Exit criteria (formerly "phase exit checklist", now scoped per step).
- Approval gate (User or Main, no longer aggregated at phase level).
- Rollback rules (which prior step a failure routes back to — e.g. Step 6 High finding → Step 5; Step 8 design defect → Step 3; Step 8 success-criterion defect → Step 1).

#### Skill restructuring

- **Removed**: `main-inception`, `main-construction`, `main-verification` skills.
- **Renamed and expanded**: `main-workflow` skill is renamed to `dev-workflow` and becomes the single workflow definition, listing the nine steps with cross-step rules (rollback graph, parallelism guidance, commit boundaries, TODO.md / progress.yaml maintenance). The plugin now exposes a single top-level workflow skill whose name matches the plugin name.
- **Specialist skills (`specialist-*`) are unchanged structurally**, but their internal references to "Phase 1" / "Phase 2" / "Phase 3" are rewritten as "Step N", and references to `main-workflow` / `main-inception` / `main-construction` / `main-verification` are rewritten to point at `dev-workflow`.
- **Shared artifacts (`shared-artifacts`)** unchanged in content; references to phases or to the old `main-*` skills are rewritten.

### What is _not_ changed by this ADR

- The nine specialist agents and their responsibilities (no consolidation under principle 8 — that remains a deliberate non-goal).
- The artifact set (`intent-spec` / `research/*` / `design` / `task-plan` / `self-review-report` / `review/*` / `validation-report` / `retrospective` / `TODO` / `progress.yaml`).
- The approval-gate locations (the same four user-approval points are retained, just no longer described as "phase gates").
- The commit-per-step convention.
- Project-specific skill integration (`effect-layer`, `effect-runtime`, `effect-hono`, `totto2727-fp`, `git-workflow`, etc.).
- The `adr` skill remains the home for project-wide decisions discovered during a workflow cycle.

## Impact

### Implementation work required (separate task, not in this ADR)

1. **Directory rename**: `plugins/ai-dlc/` → `plugins/dev-workflow/`.
2. **Manifest updates**: `.claude-plugin/marketplace.json`, `.claude/settings.json`.
3. **Skill files**: delete `main-inception` / `main-construction` / `main-verification`; rename `main-workflow` skill directory to `dev-workflow` and rewrite it to host the nine-step definition; rewrite all `specialist-*` skills to remove phase references and update `main-workflow` references to `dev-workflow`.
4. **Agent files** (`plugins/dev-workflow/agents/*.md`): remove phase references in agent descriptions.
5. **Shared artifact references and templates**: scrub `Phase 1` / `Phase 2` / `Phase 3` references; leave artifact content unchanged.
6. **Plugin manifest** (`plugins/dev-workflow/.claude-plugin/plugin.json` if present): name field update.

### Communication / governance

- Future contributors must not reintroduce the phase concept without superseding this ADR.
- AWS AI-DLC may be cited as historical inspiration but **must not** be cited as a specification the plugin conforms to.
- Existing `docs/ai-dlc/<identifier>/` artifact storage paths (referenced inside skills) should also migrate to `docs/dev-workflow/<identifier>/`. Any in-flight cycles using the old path complete on the old path; new cycles use the new path.

### What this ADR does not commit to

- **Migration of the directory `docs/ai-dlc/` if it already contains real artifacts** in any consumer repository — that is a per-consumer decision, not a plugin decision.
- **Backward-compatible alias** (`ai-dlc` redirecting to `dev-workflow`): not provided. Consumers update enabled-plugins entries directly.
- **A separate ADR per skill rewrite**: the implementation is one coordinated change tracked under this single ADR.
