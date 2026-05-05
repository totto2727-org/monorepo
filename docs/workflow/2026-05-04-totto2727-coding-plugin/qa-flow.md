# QA Flow: Consolidate coding/test/docs skills into `totto2727-coding` plugin

- **Identifier:** 2026-05-04-totto2727-coding-plugin
- **Author:** qa-analyst (dev-workflow Step 4, single instance)
- **Source:** `qa-design.md`
- **Created at:** 2026-05-04
- **Last updated:** 2026-05-04
- **Status:** draft

This document visualizes the test cases of `qa-design.md` as Mermaid flowcharts so coverage can be confirmed at a glance. See `share-artifacts/references/qa-flow.md` for authoring details.

## Overview

This cycle is a **documentation / plugin restructuring** cycle, so the "essential logic" being tested is the post-migration **filesystem and configuration state**, not runtime branching of code. The flow diagrams below are organized into five concerns following the data-flow direction of the migration: (1) old-path deletion, (2) new-path presence, (3) content invariants of the new files (line count + link integrity), (4) configuration consistency (three marketplace.json + three plugin.json + `enabledPlugins`), and (5) tooling validation (`deno check` + `vp check`). A sixth section captures the cross-cutting end-user smoke test (TC-022). Implementation-driven branches are intentionally left empty in Step 4 and will be appended by the implementer in Step 6 if discovered.

---

## 1. Old paths gone (cleanup verification)

Success criteria covered by this section: SC-1

```mermaid
flowchart TD
  Start([Begin SC-1 verification]) --> Q1{plugins/moonbit/ directory exists?}
  Q1 -->|yes| Fail1[skip: SC-1 fails - cleanup task W5-T1 not run]
  Q1 -->|no, absent| TC1[TC-001: plugins/moonbit removed]
  TC1 --> Q2{plugins/components-build/ directory exists?}
  Q2 -->|yes| Fail2[skip: SC-1 fails - cleanup task W5-T2 not run]
  Q2 -->|no, absent| TC2[TC-002: plugins/components-build removed]
  TC2 --> Q3{any of .agents/skills/{effect-layer,effect-runtime,effect-hono,totto2727-fp} present?}
  Q3 -->|any present| Fail3[skip: SC-1 fails - cleanup tasks W5-T3 to W5-T6 not run]
  Q3 -->|all absent| TC3[TC-003: four .agents/skills entries removed]
  TC3 --> EndCleanup([SC-1 satisfied])
```

---

## 2. New paths present (creation verification)

Success criteria covered by this section: SC-2

```mermaid
flowchart TD
  Start([Begin SC-2 verification]) --> Q1{plugin.json at plugins/totto2727-coding/.claude-plugin/ exists?}
  Q1 -->|no| Fail1[skip: SC-2 fails - W1-T1 not run]
  Q1 -->|yes| TC4[TC-004: manifest exists]
  TC4 --> Q2{four SKILL.md files present, one per skill?}
  Q2 -->|missing any of coding,test,docs-moonbit,docs-components-build| Fail2[skip: SC-2 fails - W2 or W4 not complete]
  Q2 -->|all four present| TC5[TC-005: 4 SKILL.md present]
  TC5 --> Q3{seven coding/references/*.md present?}
  Q3 -->|missing any| Fail3[skip: SC-2 fails - W3 or W4-T1b/T1c not complete]
  Q3 -->|all seven present| TC6[TC-006: 7 coding/references present]
  TC6 --> Q4{three test/references/*.md present?}
  Q4 -->|missing any| Fail4[skip: SC-2 fails - W3-T6 or W4-T2b/T2c not complete]
  Q4 -->|all three present| TC7[TC-007: 3 test/references present]
  TC7 --> Q5{both Deno scripts present?}
  Q5 -->|missing| Fail5[skip: SC-2 fails - W2-T2 or W2-T5 not complete]
  Q5 -->|both present| TC8[TC-008: 2 scripts present]
  TC8 --> Q6{both slash commands present?}
  Q6 -->|missing| Fail6[skip: SC-2 fails - W2-T3 or W2-T6 not complete]
  Q6 -->|both present| TC9[TC-009: 2 slash commands present]
  TC9 --> Q7{frontmatter name on docs-* SKILL.md correct?}
  Q7 -->|name still moonbit-docs or components-build-docs| Fail7[skip: SC-2 partial - A8 rename not applied]
  Q7 -->|both renamed to docs-*| TC26[TC-026: docs-* frontmatter renamed]
  TC26 --> EndPresent([SC-2 satisfied])
```

---

## 3. Content invariants (line cap + link integrity)

Success criteria covered by this section: SC-3, SC-4

```mermaid
flowchart TD
  Start([Begin SC-3 + SC-4 verification]) --> Q1{coding/SKILL.md line count?}
  Q1 -->|"> 300"| Fail1[skip: SC-3 fails - exceeds hard cap, W4-T1a refactor needed]
  Q1 -->|"<= 300"| TC10[TC-010: coding/SKILL.md within cap]
  TC10 --> Q2{test/SKILL.md line count?}
  Q2 -->|"> 300"| Fail2[skip: SC-3 fails - exceeds hard cap, W4-T2a refactor needed]
  Q2 -->|"<= 300"| TC11[TC-011: test/SKILL.md within cap]
  TC11 --> Q3{Tier-1 SKILL.md links resolve?}
  Q3 -->|any unresolved| Fail3[skip: SC-4 fails - relative-path arithmetic wrong, see research/skill-content-migration.md R-1..R-7]
  Q3 -->|all resolve| TC12[TC-012: Tier-1 links integral]
  TC12 --> Q4{Tier-2 coding/references/*-skill.md links resolve, excluding External skill references section per A10?}
  Q4 -->|any unresolved in scanned section| Fail4[skip: SC-4 fails - Tier-2 link broken]
  Q4 -->|all resolve in scanned section| TC13[TC-013: Tier-2 coding links integral]
  TC13 --> Q5{Tier-2 test/references/*-skill.md links resolve, with same A10 exclusion?}
  Q5 -->|any unresolved| Fail5[skip: SC-4 fails - test/references Tier-2 link broken]
  Q5 -->|all resolve, possibly empty after A10 exclusion| TC14[TC-014: Tier-2 test links integral]
  TC14 --> Q6{A7 cross-skill back-link from coding/references/mbt-bestpractice.md to test/references/mbt-bestpractice.md resolves?}
  Q6 -->|missing or wrong path| Fail6[skip: SC-4 partial - A7 specific link broken]
  Q6 -->|resolves| TC24[TC-024: A7 back-link resolves]
  TC24 --> EndContent([SC-3 + SC-4 satisfied])
```

---

## 4. Configuration consistency (marketplace.json + plugin.json + enabledPlugins)

Success criteria covered by this section: SC-5, SC-8, SC-9

```mermaid
flowchart TD
  Start([Begin SC-5 + SC-8 + SC-9 verification]) --> Pre{c-plugin dev marketplace sync executed in W6-T1?}
  Pre -->|no| Skip1[skip: SC-5 + SC-8 cannot be evaluated until sync runs]
  Pre -->|yes| Q1{.claude-plugin/marketplace.json contains totto2727-coding entry only, not moonbit/components-build?}
  Q1 -->|wrong contents| Fail1[skip: SC-5 fails - W1-T2 base edit incorrect]
  Q1 -->|correct| TC15[TC-015: base marketplace correct]
  TC15 --> Q2{.cursor-plugin/marketplace.json same predicate?}
  Q2 -->|wrong contents| Fail2[skip: SC-5 fails - sync did not regenerate cursor variant correctly]
  Q2 -->|correct| TC16[TC-016: cursor marketplace consistent]
  TC16 --> Q3{.agents/plugins/marketplace.json contains totto2727-coding in Codex schema, not old plugins?}
  Q3 -->|wrong schema or wrong contents| Fail3[skip: SC-5 fails - sync did not regenerate codex variant correctly]
  Q3 -->|correct| TC17[TC-017: codex marketplace consistent]
  TC17 --> Q4{three plugin.json variants under plugins/totto2727-coding/ have identical name/description/version/author?}
  Q4 -->|any drift| Fail4[skip: SC-8 fails - syncPluginJson did not copy verbatim, or base manifest edited after sync]
  Q4 -->|identical| TC20[TC-020: 3 plugin.json identical]
  TC20 --> Q5{.claude/settings.json enabledPlugins has totto2727-coding=true and lacks moonbit + components-build?}
  Q5 -->|wrong| Fail5[skip: SC-9 fails - W1-T3 not applied correctly]
  Q5 -->|correct| TC21[TC-021: enabledPlugins updated]
  TC21 --> EndConfig([SC-5 + SC-8 + SC-9 satisfied])
```

---

## 5. Tooling validation (deno check + vp check + grep no-leftover + slash command refs + script template name)

Success criteria covered by this section: SC-6, SC-7, SC-10

```mermaid
flowchart TD
  Start([Begin SC-6 + SC-7 + SC-10 verification]) --> Q1{deno check exits 0 on generate-docs-moonbit.ts?}
  Q1 -->|nonzero, e.g. TS2345| Fail1[skip: SC-7 fails - A6 null guard missing or syntax error]
  Q1 -->|exit 0| Q1b{deno check exits 0 on generate-docs-components-build.ts?}
  Q1b -->|nonzero| Fail1b[skip: SC-7 fails - second script's null guard missing]
  Q1b -->|exit 0| TC19[TC-019: both deno check pass]
  TC19 --> Q2{repo-wide grep for old skill names / paths returns zero matches outside immutable corpus?}
  Q2 -->|"any match outside docs/adr,docs/workflow,node_modules,.git"| Fail2[skip: SC-6 fails - W5-T7 dev-workflow placeholder rewrite incomplete or other leftover]
  Q2 -->|zero matches| TC18[TC-018: no leftover references]
  TC18 --> Q3{slash commands invoke the new Deno script names?}
  Q3 -->|references old process-moonbit-docs.ts or generate-skill.ts| Fail3[skip: SC-6 partial - slash command not updated, A8 / W2-T3 / W2-T6 incomplete]
  Q3 -->|references new generate-docs-*.ts| TC25[TC-025: slash commands point to new scripts]
  TC25 --> Q4{Deno script template strings emit new frontmatter name docs-*?}
  Q4 -->|template still emits moonbit-docs / components-build-docs| Fail4[skip: SC-6 partial - script template not updated, A8 step 2 incomplete; would silently revert TC-026 on next regeneration]
  Q4 -->|emits docs-moonbit / docs-components-build| TC27[TC-027: script templates renamed]
  TC27 --> Q5{vp check exits 0 from repo root?}
  Q5 -->|nonzero| Fail5[skip: SC-10 fails - oxfmt / oxlint / type errors must be resolved]
  Q5 -->|exit 0| TC23[TC-023: vp check passes]
  TC23 --> EndTooling([SC-6 + SC-7 + SC-10 satisfied])
```

---

## 6. End-user smoke test (cross-cutting, post-merge)

Success criteria covered by this section: (none) - this TC has Target SC = (none) per qa-design.md, but it is the operational acceptance gate.

```mermaid
flowchart TD
  Start([After PR merges to main]) --> Q1{Open fresh Claude Code session in main checkout: /Users/totto2727/proj/monorepo/}
  Q1 --> Q2{Available skills list contains totto2727-coding:coding?}
  Q2 -->|no| Fail1[skip: smoke fails - investigate marketplace.json registration, settings.json enabledPlugins, trust prompt; may need /plugin install]
  Q2 -->|yes| Q3{Available skills list also contains totto2727-coding:test, totto2727-coding:docs-moonbit, totto2727-coding:docs-components-build?}
  Q3 -->|partial| Fail2[skip: smoke partial - one or more skill SKILL.md frontmatter description may be unactivatable]
  Q3 -->|all four present| TC22[TC-022: plugin discoverable end-to-end]
  TC22 --> EndSmoke([User-facing acceptance achieved])
```

Note on TC-022 placement: this is a `manual × scenario` test that cannot run inside the worktree (per `research/plugin-discovery-mechanism.md` Implications #4: directory-source plugins resolve against the main checkout, not the worktree). The Step 8 validator records the result in `validation-report.md` after the PR merges. Until then, this branch leaf is a "deferred" success.

---

## Implementation-driven branches (optional)

Empty at the end of Step 4. The implementer in Step 6 appends a flowchart here for any `TC-IMPL-NNN` cases that cannot be naturally folded into sections 1-6 above.

```mermaid
flowchart TD
  Start([Reserved for Step 6 implementer]) --> TBD[TBD: TC-IMPL-NNN entries appended here when discovered]
```
