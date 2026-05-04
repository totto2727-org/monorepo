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

- [x] **T1** — Create new plugin manifest `plugins/totto2727-coding/.claude-plugin/plugin.json`
  - status: completed
  - dependencies: none
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: 233ebea
  - implementer: W1-implementer-T1
  - re_activations: 0
  - notes: -

- [x] **T2** — Edit `.claude-plugin/marketplace.json` — add `totto2727-coding`, drop `moonbit` and `components-build`
  - status: completed
  - dependencies: none
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: f937572
  - implementer: W1-implementer-T2
  - re_activations: 0
  - notes: -

- [x] **T3** — Update `.claude/settings.json` `enabledPlugins`
  - status: completed
  - dependencies: none
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: 66183be
  - implementer: W1-implementer-T3
  - re_activations: 0
  - notes: 'Pre-existing vp check 14 errors in saas-example (codegen files unrelated to this cycle); SC-10 may need vp run --filter saas-example prebuild before Step 8 validation.'

- [x] **T4** — Move + rename `moonbit-docs/` SKILL.md and references → `docs-moonbit/`
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: 0131355
  - implementer: W2-implementer-T4
  - re_activations: 0
  - notes: A8 lockstep with T5; 27 files copied verbatim

- [x] **T5** — Move + rename + edit `process-moonbit-docs.ts` → `generate-docs-moonbit.ts`
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: fc13858
  - implementer: W2-implementer-T5
  - re_activations: 0
  - notes: A8 lockstep with T4; 4 edits applied (output dir + name template + Related Skills template + null guard); deno check exit 0

- [x] **T6** — Move + rename slash command `update-moonbit-docs.md` → `update-docs-moonbit.md`
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: 635ac14
  - implementer: W2-implementer-T6
  - re_activations: 0
  - notes: 'Race condition: T6 file got merged into T7 commit (635ac14, T7 主題). File content correct, deno run path updated. See progress.yaml.notes for retrospective candidate.'

- [x] **T7** — Move + rename `components-build-docs/` SKILL.md → `docs-components-build/`
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: 635ac14
  - implementer: W2-implementer-T7
  - re_activations: 0
  - notes: 'A8 lockstep with T8; commit 635ac14 also contains T6 file due to race condition.'

- [x] **T8** — Move + rename + edit `generate-skill.ts` → `generate-docs-components-build.ts`
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: 347d5c6
  - implementer: W2-implementer-T8
  - re_activations: 0
  - notes: A8 lockstep with T7; 4 edits applied; deno check exit 0

- [x] **T9** — Move + rename slash command `update-components-build-docs.md` → `update-docs-components-build.md`
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: e73bd57
  - implementer: W2-implementer-T9
  - re_activations: 0
  - notes: -

- [x] **T10** — Migrate `effect-layer/SKILL.md` → `coding/references/ts-effect-layer.md`
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: 35e307c
  - implementer: W3-implementer-T10
  - re_activations: 0
  - notes: 'Race condition: original 6a2a2bb (T10 message) actually contained T13 file (ts-totto2727-fp.md). T10 file (ts-effect-layer.md) committed in follow-up 35e307c.'

- [x] **T11** — Migrate `effect-runtime/SKILL.md` → `coding/references/ts-effect-runtime.md`
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: 9c6c4be
  - implementer: W3-implementer-T11
  - re_activations: 0
  - notes: 'Race condition: T11 file (ts-effect-runtime.md) was swept into 9c6c4be (T12 message). Content correct per R-2.'

- [x] **T12** — Migrate `effect-hono/SKILL.md` → `coding/references/ts-effect-hono.md`
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: 9c6c4be
  - implementer: W3-implementer-T12
  - re_activations: 0
  - notes: 'Commit 9c6c4be also contains T11 file due to race condition.'

- [x] **T13** — Migrate `totto2727-fp/SKILL.md` → `coding/references/ts-totto2727-fp.md`
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: 6a2a2bb
  - implementer: W3-implementer-T13
  - re_activations: 0
  - notes: 'Race condition: T13 file got committed under "T10" commit message (6a2a2bb). Content correct per R-4.'

- [x] **T14** — Migrate `moonbit-bestpractice/SKILL.md` → `coding/references/mbt-bestpractice.md`
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: df9931f
  - implementer: W3-implementer-T14
  - re_activations: 0
  - notes: 'A7(a) cross-skill link applied; R-5 references skill-content-migration.md is stale re docs-\* rename, implementer correctly applied design A8 instead.'

- [x] **T15** — Migrate `moonbit-bestpractice/references/moonbit-test.md` → `test/references/mbt-bestpractice.md`
  - status: completed
  - dependencies: T1
  - started_at: 2026-05-04
  - completed_at: 2026-05-04
  - commit: 6ce3ba4
  - implementer: W3-implementer-T15
  - re_activations: 0
  - notes: -

- [ ] **T16** — Author `coding/SKILL.md` (≤300 lines, language-agnostic + language index + external spec section)
  - status: in_progress
  - dependencies: T10, T11, T12, T13, T14, T15, T1
  - started_at: 2026-05-04
  - completed_at: -
  - commit: -
  - implementer: W4-implementer-T16
  - re_activations: 0
  - notes: 'Author file only; Main commits sequentially to avoid W2/W3 race condition. SC-3 hard cap.'

- [ ] **T17** — Author `coding/references/ts-skill.md` (in-plugin TS detail + external skill refs vite-plus / remix per A10)
  - status: in_progress
  - dependencies: T10, T11, T12, T13, T1
  - started_at: 2026-05-04
  - completed_at: -
  - commit: -
  - implementer: W4-implementer-T17
  - re_activations: 0
  - notes: 'Author file only; Main commits sequentially. A10 external skill refs.'

- [ ] **T18** — Author `coding/references/mbt-skill.md`
  - status: in_progress
  - dependencies: T14, T1
  - started_at: 2026-05-04
  - completed_at: -
  - commit: -
  - implementer: W4-implementer-T18
  - re_activations: 0
  - notes: 'Author file only; Main commits sequentially.'

- [ ] **T19** — Author `test/SKILL.md` (≤300 lines, TS + MoonBit indexes per Q4 revised)
  - status: in_progress
  - dependencies: T15, T1
  - started_at: 2026-05-04
  - completed_at: -
  - commit: -
  - implementer: W4-implementer-T19
  - re_activations: 0
  - notes: 'Author file only; Main commits sequentially. SC-3 hard cap.'

- [ ] **T20** — Author `test/references/ts-skill.md` (external skill ref vite-plus only per A10)
  - status: in_progress
  - dependencies: T1
  - started_at: 2026-05-04
  - completed_at: -
  - commit: -
  - implementer: W4-implementer-T20
  - re_activations: 0
  - notes: 'Author file only; Main commits sequentially. A10 external skill refs.'

- [ ] **T21** — Author `test/references/mbt-skill.md`
  - status: in_progress
  - dependencies: T15
  - started_at: 2026-05-04
  - completed_at: -
  - commit: -
  - implementer: W4-implementer-T21
  - re_activations: 0
  - notes: 'Author file only; Main commits sequentially.'

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
