# Task List: 2026-05-04-totto2727-coding-plugin

- **Source:** `task-plan.md`
- **Active Steps:** Step 6-7 (Implementation / External Review)
- **Created at:** 2026-05-04
- **Last updated:** 2026-05-04

This file holds the **persisted task state**. It is kept in sync with the `TaskCreate` task list inside Main, but **this file is the source of truth**. On every state change, update TODO.md first, then commit, then run `TaskUpdate` (in that order).

## Tasks added later (after `task-plan.md` was finalized)

Following the rule that `task-plan.md` is immutable, any additional tasks discovered during Steps 6-7 are recorded here. Always state the reason the task was added.

- None (default)

## Tasks

- [ ] **T1** — Create new plugin manifest `plugins/totto2727-coding/.claude-plugin/plugin.json`
  - status: in_progress
  - dependencies: none
  - started_at: 2026-05-04
  - completed_at: -
  - commit: -
  - implementer: W1-implementer-T1
  - re_activations: 0
  - notes: -

- [ ] **T2** — Edit `.claude-plugin/marketplace.json` — add `totto2727-coding`, drop `moonbit` and `components-build`
  - status: in_progress
  - dependencies: none
  - started_at: 2026-05-04
  - completed_at: -
  - commit: -
  - implementer: W1-implementer-T2
  - re_activations: 0
  - notes: -

- [ ] **T3** — Update `.claude/settings.json` `enabledPlugins`
  - status: in_progress
  - dependencies: none
  - started_at: 2026-05-04
  - completed_at: -
  - commit: -
  - implementer: W1-implementer-T3
  - re_activations: 0
  - notes: -

- [ ] **T4** — Move + rename `moonbit-docs/` SKILL.md and references → `docs-moonbit/`
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: A8 lockstep with T5

- [ ] **T5** — Move + rename + edit `process-moonbit-docs.ts` → `generate-docs-moonbit.ts`
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: A8 lockstep with T4 (script template + null guard + output dir)

- [ ] **T6** — Move + rename slash command `update-moonbit-docs.md` → `update-docs-moonbit.md`
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T7** — Move + rename `components-build-docs/` SKILL.md → `docs-components-build/`
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: A8 lockstep with T8

- [ ] **T8** — Move + rename + edit `generate-skill.ts` → `generate-docs-components-build.ts`
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: A8 lockstep with T7

- [ ] **T9** — Move + rename slash command `update-components-build-docs.md` → `update-docs-components-build.md`
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T10** — Migrate `effect-layer/SKILL.md` → `coding/references/ts-effect-layer.md`
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: Strip frontmatter (A5)

- [ ] **T11** — Migrate `effect-runtime/SKILL.md` → `coding/references/ts-effect-runtime.md`
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: Strip frontmatter

- [ ] **T12** — Migrate `effect-hono/SKILL.md` → `coding/references/ts-effect-hono.md`
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: Strip frontmatter

- [ ] **T13** — Migrate `totto2727-fp/SKILL.md` → `coding/references/ts-totto2727-fp.md`
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: Strip frontmatter

- [ ] **T14** — Migrate `moonbit-bestpractice/SKILL.md` → `coding/references/mbt-bestpractice.md`
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: Strip frontmatter; rewrite L311 cross-skill link per A7(a)

- [ ] **T15** — Migrate `moonbit-bestpractice/references/moonbit-test.md` → `test/references/mbt-bestpractice.md`
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: No frontmatter to strip (already none per R-6)

- [ ] **T16** — Author `coding/SKILL.md` (≤300 lines, language-agnostic + language index + external spec section)
  - status: pending
  - dependencies: T10, T11, T12, T13, T14, T15, T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: 300-line hard cap (SC-3); external spec links to ../docs-moonbit/SKILL.md and ../docs-components-build/SKILL.md

- [ ] **T17** — Author `coding/references/ts-skill.md` (in-plugin TS detail + external skill refs vite-plus / remix per A10)
  - status: pending
  - dependencies: T10, T11, T12, T13, T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: A10 — `## External skill references` section, name-only no Markdown link

- [ ] **T18** — Author `coding/references/mbt-skill.md`
  - status: pending
  - dependencies: T14, T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T19** — Author `test/SKILL.md` (≤300 lines, TS + MoonBit indexes per Q4 revised)
  - status: pending
  - dependencies: T15, T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: 300-line hard cap (SC-3)

- [ ] **T20** — Author `test/references/ts-skill.md` (external skill ref vite-plus only per A10)
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: A10 — `## External skill references` section, no in-plugin detail files

- [ ] **T21** — Author `test/references/mbt-skill.md`
  - status: pending
  - dependencies: T15
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T22** — Delete `plugins/moonbit/` (entire directory)
  - status: pending
  - dependencies: T4, T5, T6, T14, T15
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: Move-and-rename ordering rule: only run after all source-file migrations are committed

- [ ] **T23** — Delete `plugins/components-build/` (entire directory)
  - status: pending
  - dependencies: T7, T8, T9
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: Move-and-rename ordering rule

- [ ] **T24** — Delete `.agents/skills/effect-layer/`
  - status: pending
  - dependencies: T10
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T25** — Delete `.agents/skills/effect-runtime/`
  - status: pending
  - dependencies: T11
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T26** — Delete `.agents/skills/effect-hono/`
  - status: pending
  - dependencies: T12
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T27** — Delete `.agents/skills/totto2727-fp/`
  - status: pending
  - dependencies: T13
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T28** — Rewrite 12 dev-workflow placeholder occurrences (per cross-references UQ-1 / A4)
  - status: pending
  - dependencies: T1
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: 12 sites enumerated in design.md A4 paragraph

- [ ] **T29** — Update `js/package/fp/README.md:5` and `js/package/fp/CLAUDE.md:3` cross-references
  - status: pending
  - dependencies: T13
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: -

- [ ] **T30** — Run `c-plugin dev marketplace sync` and commit derivatives
  - status: pending
  - dependencies: T1-T29 (every other task)
  - started_at: -
  - completed_at: -
  - commit: -
  - implementer: -
  - re_activations: 0
  - notes: HARD SERIALIZATION POINT — must run last; produces `.codex-plugin/plugin.json`, `.cursor-plugin/plugin.json`, `.cursor-plugin/marketplace.json`, `.agents/plugins/marketplace.json`

## State transition guide

- `pending`: Not started. Rendered as `[ ]`.
- `in_progress`: An `implementer` is running. Rendered as `[ ]`; record `started_at` and `implementer`.
- `completed`: Finished. Rendered as `[x]`; record `completed_at` and the `commit` SHA.
- When an External Review Blocker forces a rollback: change `completed` back to `in_progress` and increment `re_activations`.

## Commit conventions

- One commit per task state change (commit frequently).
- Example commit messages:
  - `docs(dev-workflow/2026-05-04-totto2727-coding-plugin): start task T1`
  - `docs(dev-workflow/2026-05-04-totto2727-coding-plugin): complete task T1`
  - `docs(dev-workflow/2026-05-04-totto2727-coding-plugin): re-activate task T1 (external-review feedback)`
