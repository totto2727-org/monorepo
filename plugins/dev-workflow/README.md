# dev-workflow

Multi-agent development workflow plugin for Claude Code.

A Main coordinator orchestrates nine specialist subagents (`intent-analyst`, `researcher`, `architect`, `qa-analyst`, `planner`, `implementer`, `reviewer`, `validator`, `retrospective-writer`) through a flat 9-step lifecycle:

1. Intent Clarification → 2. Research → 3. Design → 4. QA Design → 5. Task Decomposition → 6. Implementation → 7. External Review → 8. Validation → 9. Retrospective

External Review runs the `reviewer` specialist in parallel across six aspects (`security`, `performance`, `readability`, `test-quality`, `api-design`, `holistic`). The `holistic` aspect carries the whole-cycle integrity check (Task Plan completion, design alignment, intent satisfiability, obvious bugs).

Each step has its own approval gate, exit criteria, and explicit rollback rules. There is no "phase" abstraction above steps.

## How to use

Trigger the workflow by asking Claude Code to start a development cycle (e.g. "新機能を dev-workflow で進めたい"). The Main coordinator handles step progression, specialist invocation, and user approval gates.

Workflow execution rules live in `skills/dev-workflow/SKILL.md`. Specialist behavior is defined in `skills/specialist-*/SKILL.md`. Artifact formats and templates are in `skills/shared-artifacts/`.

## Origin

This plugin draws inspiration from several multi-agent development methodologies, most notably AWS Raja SP's _AI-Driven Development Lifecycle (AI-DLC)_. It is **not** an implementation, derivative, or variant of AI-DLC. The plugin omits AI-DLC's central elements — Mob Elaboration / Mob Construction rituals, the Bolt iteration concept, the Domain Design / Logical Design split, the DDD / BDD / TDD flavor selection, role consolidation under principle 8, and the Operations phase. It also adds steps with no AI-DLC counterpart: Research, QA Design, External Review, and Retrospective.

The rationale for positioning the plugin as an independent method (rather than an AI-DLC derivative) is recorded in `docs/adr/2026-04-26-dev-workflow-rename-and-flatten.md`.

## Non-goals

- Implementing AI-DLC compatibility or parity.
- Covering deployment, observability, SLA prediction, or runbook execution (workflow scope ends at code completion + reviewed + validated against the intent).
- Selecting design flavors at the framework level (project-specific design conventions live in skills like `effect-layer`, `effect-runtime`, `effect-hono`, `totto2727-fp`).
