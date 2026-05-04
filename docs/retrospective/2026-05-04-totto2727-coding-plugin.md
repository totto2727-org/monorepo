# Retrospective: 2026-05-04-totto2727-coding-plugin

- **Identifier:** 2026-05-04-totto2727-coding-plugin
- **Writer:** retrospective-writer (single instance, dev-workflow Step 9)
- **Created at:** 2026-05-04
- **Cycle started at:** 2026-05-04 (initialize commit `b84125f`)
- **Cycle completed at:** 2026-05-04 (Step 8 approval `5f06b5a`)
- **Duration:** Single calendar day (Step 1 → Step 8 approval). 50+ commits across `b84125f..5f06b5a`.

## Cycle overview

This cycle consolidated four pre-existing skill / plugin assets (`plugins/moonbit/`, `plugins/components-build/`, four
`.agents/skills/effect-*` directories, and `.agents/skills/totto2727-fp/`) into a single `plugins/totto2727-coding/`
plugin reorganized as four sibling skills (`coding`, `test`, `docs-moonbit`, `docs-components-build`). The Intent Spec
declared 10 success criteria covering path deletion, path creation, line-cap (300 lines for `coding/SKILL.md` and
`test/SKILL.md`), 3-tier link integrity, 3-marketplace.json parity, repository-wide grep cleanliness, `deno check`
exit 0 on the renamed scripts, 3-plugin.json parity, `enabledPlugins` settings update, and `vp check` exit 0.

All 10 SCs passed at Step 8 (`SC-10` was deferred during the validator's sandboxed run because Go module fetch over
TLS was blocked, and Main reran `vp run --filter saas-example prebuild` outside the sandbox to confirm cycle-clean
PASS). `TC-022` (post-merge plugin discovery smoke test) remains a `manual × scenario` deferral by design, because
Claude Code resolves directory-source plugins against the main checkout, not the worktree.

A notable mid-cycle event: a rebase brought in upstream commit `5e92483` (deletion of `.agents/skills-lock.json`,
addition of three `*-plugin/marketplace.json` manifests) which collapsed one of the Intent Spec's premises. Step 2
researchers detected this concurrently, and Main applied an increment-style Intent Spec update (no rollback to
Step 1) — the first known cross-step "premise drift mid-cycle" that the dev-workflow handled without a structured
rollback.

## What went well (patterns that worked)

- **Step 1 dialogue depth (3 rounds, 9 questions A–I) absorbed a mid-cycle premise drift.** When Step 2 surfaced
  upstream `5e92483` (removed `.agents/skills-lock.json`, added 3 manifests), the Intent Spec only needed an
  increment — Scope §4/§5, SC-5, SC-8/9/10, and Open Questions — instead of a full Step-1 rollback. The depth of
  prior intent clarification carried the cycle through the drift.
- **Parallel `researcher` independence overturned a prior Blocker conclusion.** `plugin-discovery-mechanism.md` (run
  in parallel with `skills-lock-registry.md`) demonstrated empirically that Claude Code reads the in-repo
  `marketplace.json` via `extraKnownMarketplaces`, which inverted the earlier "must update dotfiles" conclusion. The
  win is that Step 2 isn't a single hypothesis confirmation — multiple researchers checking from different angles
  caught and corrected an early assumption.
- **Step 4 explicit `manual × scenario` classification of TC-022.** By tagging the post-merge plugin-discovery smoke
  test as deliberately deferred at qa-design time (`qa-design.md` L31, L82) and recording the worktree-vs-main-checkout
  reason as a design fact, Validator could record the deferral without re-debating its scope at Step 8.
- **W4 / W5 / W6 pivot to "implementer creates files only, Main commits sequentially".** After W2 / W3 race conditions
  (see Issues), Main switched the operational convention. Zero race conditions occurred in W4–W6 across 14 tasks
  (T16–T30), all clean. The pivot itself is reusable for any future cycle that needs parallel implementer work.
- **`design.md` A8 lockstep notation directly drove correct concurrent edits.** The "script template ↔ generated
  SKILL.md frontmatter" lockstep paragraph in design.md A8 was a single source that T5 / T8 implementers both read,
  resulting in synchronised template-string + filename + slash-command updates without coordination overhead.
- **Step 7 Round-trip discipline (Round 1 → 2 → 3) caught latent test-quality regressions.** Round 2's M-4 finding
  (TC-018 grep matched the new `ts-effect-*` filenames because `-` is not a POSIX-ERE word character) was only
  observable AFTER Round 1's M-2 fix removed the docs-moonbit upstream-URL noise — a textbook case where one fix
  reveals another defect. The strict 1-aspect = 1 review file with append-only Round history captured the causal
  chain and made the gate decision auditable.

## Issues (what did not work well)

### Loop count analysis

| Loop between steps | Count                                                                                                                                                                               | Root cause                                                                                                                                                                                                                                                                          |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Step 6 ↔ Step 7    | 3 rounds (test-quality only); 2 rounds (4 other aspects)                                                                                                                            | Round 1 surfaced TC-018 grep recipe defects (M-2 / M-3) and Tier-2 mixed JP/EN (M-2). Round 2's M-2 fix exposed Round 2's M-4 (latent regression). Round 3 confirmed M-4 fix only. Other aspects approved at Round 1 (security / performance) or 2.                                 |
| Step 7 → Step 6    | 2 re-activations recorded (T5-r2 = `70e19f7`, T28-r2 = `309a84c`); plus T18/T20/T21-r2 (`1cbdd8f`) for translation, qa-design TC-013/014/018 amendments (`784324d`, `18187bf`)      | T28 grep target was scoped narrowly and missed `moonbit-bestpractice` placeholder occurrences in 4 dev-workflow files. T5 implementer left old script name in header comment + Usage error message because task-plan.md T5 enumerated only 4 edit categories.                       |
| Step 8 → Step 6    | 0 (re-activation); 3 in-cycle additions during Step 8 (U1 sibling-skill links commit `cea1f2b`; U2 English-only commit `e776623`; readability polish commits `a2f69b6` / `5552425`) | User added new directives at validation stage: U1 (sibling-skill link policy), U2 (English-only skill content), plus follow-up readability polish (R4 inline-code wrapping, Related references unification, unimplemented mention removal). Not a Step-6 rollback — added in-cycle. |

### Blocker history

- None. `progress.yaml.blockers` is empty across the cycle.

### Specific issue catalogue

- **W2 / W3 race-condition (commit-content mismatch).** Parallel implementers running in the same worktree shared a
  single git index; T6 file landed in T7 commit `635ac14`, T11 file in T12 commit `9c6c4be`, T13 file in T10 commit
  `6a2a2bb`. Files on disk were correct; only the commit message ↔ file mapping was muddled. Resolution: from W4
  onward, implementers create files only and Main commits sequentially. Recorded in `TODO.md` per-task `notes:` field
  and `progress.yaml.notes`.
- **TC-018 grep recipe defects required 3 rounds to stabilize.** In sequence: (M-2) `--exclude-dir=docs/adr` matched
  by basename only (GNU grep semantics, not the path semantics implied by the task plan); (M-3) script body wasn't
  covered by TC-018 / TC-025; (M-4) POSIX ERE `\b` succeeds at `s|-` boundaries because `-` is not a word character,
  so `\beffect-layer\b` matched the new `ts-effect-layer.md` filename. Three Step-6 ↔ Step-7 round-trips just to
  stabilize one TC's grep recipe.
- **T28 grep target was incomplete.** task-plan.md T28 enumerated `effect-layer / effect-runtime / effect-hono /
totto2727-fp` placeholder strings but missed `moonbit-bestpractice` (still present in 4 dev-workflow files at
  `qa-analyst.md:46`, `specialist-implementer/SKILL.md:52`, `specialist-qa-analyst/SKILL.md:60`,
  `step-qa-design/SKILL.md:29` — plus `effect-*` glob in the last). T28 needed re-activation (T28-r2 = `309a84c`) to
  fix.
- **Validator could not run `vp run --filter saas-example prebuild` in sandbox** because `proxy.golang.org` Go module
  fetch failed TLS verification (`OSStatus -26276`). Validation environment constraints were not pre-declared as a
  design fact. SC-10 was first marked Deferred, then re-classified PASS after Main ran prebuild outside sandbox.
- **In-Progress user-inquiry temp reports: 2 (`step2-intent-update.md` v1 + `step2-intent-update-v2.md`).** Both
  during Step 2, both about the same topic (how to fold `5e92483` rebase + user clarification on `c-plugin dev
marketplace sync` into the Intent Spec). One Intent Spec increment cycle would have been sufficient if Main had
  proposed both updates jointly the first time.

## Improvements for the next cycle

The user established two operational rules during this cycle. Both apply to all future dev-workflow cycles, and
candidates for reflection into `dev-workflow` plugin skills are flagged below.

### A. Review response policy (cross-cycle rule, established during this cycle)

- **For findings about the cycle's own modified files, fix regardless of severity** (including Minor / typo). Findings
  about a file the cycle changed are part of the cycle's quality contract.
- **Findings about the dev-workflow itself or about other (already-shipped) work belong in the Retrospective**, not in
  the cycle's review-fix loop. Such findings should be captured here for a separate cycle to consume.
  - Action: dev-workflow reflection candidate — see `Skill improvements` below for the proposed `specialist-reviewer`
    SKILL.md and `share-artifacts/references/review-report.md` updates.

### B. Retrospective scoping policy (cross-cycle rule, established during this cycle)

- **A cycle-specific learning that would be useful as an independent skill should be raised in the Retrospective** as
  a candidate for the next cycle to extract.
- **Recurring frictions that are NOT generalisable should be marked "rejected as non-general"** rather than carried
  forward indefinitely. This keeps the retro list curated.
- **The default proposal is "would this help other work?"** — every retro item must demonstrate cross-cycle value.
- **Do NOT add every friction to the retro.** Triage aggressively.
  - Action: dev-workflow reflection candidate — `share-artifacts/references/retrospective.md` should record this
    scoping discipline as part of the "What to write" guidance.

### Process improvements

- **PR-1 (parallel implementer mode) — When launching parallel implementers in the same worktree, switch by default
  to "implementer creates files only; Main commits sequentially" to prevent git-index race.** This was confirmed
  successful across W4–W6 (14 tasks, zero race). The only situations where parallel commits are safe are when
  implementers operate in isolated worktrees per task.
  - Action: dev-workflow reflection — `step-implementation/SKILL.md` and `specialist-implementer/SKILL.md` should
    state the file-only convention as the default for parallel implementer launches inside one worktree.
- **PR-2 (grep recipe verification) — When `qa-design.md` includes a grep / awk / sed recipe inside a Pass criterion,
  the qa-analyst must run the recipe against the post-implementation tree before committing the qa-design.** Round 2
  / Round 3 of test-quality review showed three independent grep recipe defects (basename `--exclude-dir`, missing
  script-body coverage, POSIX ERE `\b` semantics), all of which would have been caught at qa-design authoring if the
  recipe had been dry-run.
  - Action: dev-workflow reflection — `specialist-qa-analyst/SKILL.md` "Procedure" should require recipe dry-run on
    the actual repo before commit.
- **PR-3 (T28-style grep targets are immutable to placement) — When a task's success depends on a grep over the
  repository, the task plan must enumerate the grep target list explicitly and require the implementer to re-run the
  grep against the post-edit tree as the task-completion check** (vs. relying on a verification commit). T28 omitted
  `moonbit-bestpractice` from its target list and the omission was caught only at Step 7.
  - Action: dev-workflow reflection — `step-task-decomposition/SKILL.md` should describe the "explicit grep target
    list + post-edit re-run" pattern for grep-driven tasks.
- **PR-4 (validator environment is a design fact) — When the validator's environment differs from CI in
  consequential ways (sandboxed network, missing codegen artifacts), `design.md` "Operational considerations" should
  state the constraint at design time, so SC measurement plans don't depend on something the validator can't run.**
  SC-10 was Deferred at first measurement because of a sandbox TLS limitation that wasn't recorded as a design fact.
  - Action: dev-workflow reflection — `step-design/SKILL.md` and `share-artifacts/references/design.md` should add
    a "Validation environment constraints" subsection.
- **PR-5 (in-cycle user directives during Step 8) — When the user introduces new content directives (U1 / U2 in this
  cycle) during validation, treat them as in-cycle scope additions if the directive applies to files the cycle
  modified.** This cycle handled U1 / U2 cleanly via `cea1f2b` / `e776623`. Future cycles should record the same
  pattern (record as in-cycle commit, NOT as Step 6 re-activation).
  - Action: this is already common practice; no skill change needed. Record for retrospective continuity.

### Skill improvements

The following are concrete proposals for the dev-workflow plugin's skills, referenced from the User policies A / B
above and Process improvements PR-1 / PR-2 / PR-3 / PR-4:

- `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md`
  - Section: "Scope (per aspect)" — add explicit policy "If a finding pertains to files the cycle modified, treat as
    in-cycle and propose a fix regardless of severity. If the finding pertains to dev-workflow itself or other work
    outside this cycle, record under `accepted-as-is` with `Notes:` flagging it for retrospective." This formalises
    User policy A.
- `plugins/dev-workflow/skills/share-artifacts/references/retrospective.md`
  - Section: "How to write each section" → add subsection "Scoping discipline" — codify User policy B (default
    proposal is "would this help other work?", "rejected as non-general" is a valid disposition, do not add every
    friction).
- `plugins/dev-workflow/skills/step-implementation/SKILL.md` and
  `plugins/dev-workflow/skills/specialist-implementer/SKILL.md`
  - Add operational note: "Parallel implementers in the same worktree must produce files only; Main performs the
    sequential commits. Parallel commits are safe only across distinct worktrees per task." (PR-1.)
- `plugins/dev-workflow/skills/specialist-qa-analyst/SKILL.md`
  - Section: "Procedure" — require qa-analyst to dry-run any grep / awk / sed recipe in `qa-design.md` Pass criteria
    against the post-implementation tree (or a representative pre-implementation snapshot) before committing the
    qa-design. (PR-2.)
- `plugins/dev-workflow/skills/step-task-decomposition/SKILL.md`
  - Section: "Per-task content" — for grep-driven tasks, require: (a) explicit grep target list, (b) post-edit
    grep re-run as the task completion check, (c) commit message includes "grep target enumeration: [...]". (PR-3.)
- `plugins/dev-workflow/skills/step-design/SKILL.md` and
  `plugins/dev-workflow/skills/share-artifacts/references/design.md`
  - Section: "Operational considerations" → add subsection "Validation environment constraints" — record any
    sandbox / network / codegen / build prerequisites that the validator's environment may not satisfy. (PR-4.)

### Specialist prompt improvements

- `intent-analyst`: When a rebase or external commit merges in mid-cycle and changes a premise of the Intent Spec,
  prefer increment-style Intent Spec updates (record under "Last updated" + Open Questions resolved) over a Step-1
  rollback. This cycle's `5e92483` handling is the reusable example.
- `researcher`: Continue parallel multi-angle research; explicitly cross-reference between researchers when one
  researcher's finding overturns another's premise, so Main can detect the inversion early.
- `architect`: When an A-decision (e.g. A8 lockstep) coordinates two or more implementer-visible outputs, embed the
  exact phrase "lockstep with TX / TY" in the design fact. This cycle's A8 demonstrated the value.
- `qa-analyst`: Dry-run every grep / awk / sed recipe in Pass criteria against the actual repo (PR-2 above). When a
  TC is `manual × scenario`, record the worktree-vs-main-checkout (or sandbox-vs-CI) limitation explicitly as the
  reason, like TC-022 did.
- `planner`: For grep-driven tasks, enumerate the grep target list explicitly and require post-edit re-run (PR-3).
  Avoid scope-of-grep ambiguity (T28 missed `moonbit-bestpractice`).
- `implementer`: When parallel implementers operate in the same worktree, defer commit to Main (PR-1). Read all
  task-plan edit categories, but treat them as non-exhaustive — verify the task's stated success criterion holistically
  (T5 missed the script header / Usage strings because they were not on the 4-category list).
- `reviewer`: Apply User policy A (in-cycle for cycle-modified files; retrospective for dev-workflow / other work).
- `validator`: When the local validation environment cannot reproduce a CI-equivalent run (sandbox, codegen, network),
  record "Cause classification: out-of-scope environment / pre-existing error" and recommend Main re-run outside
  sandbox or delegate to PR CI. Do not block the Validation Report on environment limits.
- `retrospective-writer`: Apply User policy B (curate for cross-cycle value; mark "rejected as non-general" when
  applicable).

## Reusable insights

- **Increment-style Intent Spec updates absorb mid-cycle premise drift cheaply.** A rebase that changes upstream state
  doesn't necessitate a Step-1 rollback if the Intent Spec is structured to allow targeted edits to Scope / SC / Open
  Questions and a `Last updated:` line. (Memory candidate.)
- **Parallel implementers in one worktree share a git index.** This is a Git operational fact that applies wherever
  multiple agents commit concurrently. The clean solution — implementer-creates-files-only + Main-commits-sequentially
  — is portable across any orchestrated parallel work. (Memory candidate / CLAUDE.md candidate for project-level
  multi-agent guidance.)
- **POSIX ERE `\b` matches at `s|-` boundaries because `-` is not a word character.** Any grep recipe that mixes
  `\b<word>\b` with `-`-containing identifiers in adjacent files is a latent false-positive source. Either use
  `grep -P` (Perl regex with character-class lookbehind) or rewrite the regex with explicit non-alphanumeric boundary
  conditions, or replace bare-name greps with narrower checks (`name:`-frontmatter check + path check). (Memory
  candidate for grep / lint / regex skills.)
- **GNU `grep --exclude-dir=` matches by basename only, not by path.** `--exclude-dir=docs/adr` does NOT exclude
  `docs/adr/` — it excludes any directory named `adr` anywhere in the tree. Use `--exclude-dir=adr` (basename) or
  switch to `find -path` patterns when the path semantics matter. (Memory candidate.)
- **`manual × scenario` is a legitimate test classification when worktree-vs-main-checkout or sandbox-vs-CI prevents
  automated reproduction.** Recording the limitation at qa-design time (not at validation time) prevents wasted
  Step-8 debate. (Reusable as a qa-design pattern.)

## Retrospective on user approval gates

- **Step 1 (Intent Clarification):** Approved 2026-05-04. User said "PR作成", interpreted as Intent Spec approval +
  Draft PR creation request. No rejections.
- **Step 2 (Research):** Approved 2026-05-04. Main judgement gate. User added clarification "c-plugin dev marketplace
  sync で同期可能" mid-step, prompting an Intent Spec increment. CI fix request ("CIエラーを解決して") handled with
  `vp check --fix`.
- **Step 3 (Design):** Approved 2026-05-04. Pre-approval, two user directives folded in: (i) external skill refs
  policy (vite-plus / remix as name-only); (ii) `docs-*` naming convention.
- **Step 4 (QA Design):** Approved 2026-05-04 ("ok").
- **Step 5 (Task Decomposition):** Approved 2026-05-04 ("go"). TODO.md generated.
- **Step 6 (Implementation):** Main judgement gate. All 30 tasks complete. W2 / W3 race conditions resolved by W4
  pivot. No user rejection.
- **Step 7 (External Review):** Approved 2026-05-04 across all 6 aspects. 4 user-added retrospective candidates
  recorded for follow-up (sibling-skill ref policy, English unification, race-condition retro entry, `@SKILL.md`
  follow-up).
- **Step 8 (Validation):** Approved 2026-05-04. SC-1 through SC-10 all PASS after Main re-ran prebuild outside
  sandbox. In-cycle commits added: U1 sibling-skill link policy (`cea1f2b`), U2 English unification (`e776623`),
  R4 inline-code wrapping + Related references unification (`a2f69b6`), unimplemented mention removal (`5552425`).

No rejections at any gate. The closest to rejection was Step 7 Round 1 → Round 2 → Round 3 chain on test-quality, but
that is the gate operating as designed.

## Retrospective on in-progress user inquiries

- **Count:** 2 (`step2-intent-update.md` v1, `step2-intent-update-v2.md`).
- **Main topics:** Both at Step 2, both about how to fold the `5e92483` rebase + the user's clarification on
  `c-plugin dev marketplace sync` into the Intent Spec. v1 proposed an initial increment; v2 was the revised
  proposal after user feedback on v1.
- **Reflection:** A single inquiry could have been sufficient if Main had proposed both updates (rebase reflection +
  sync-tool clarification) jointly the first time. Future Step-2 inquiries should batch all premise-drift items into
  one proposal where possible.

## Cost / time

- **Wall-clock time per phase:** Single calendar day total. Step 1 (Intent + 3 rounds dialogue) and Step 2 (5
  parallel researchers + Intent increment) consumed roughly the morning. Step 3 / 4 / 5 ran in the afternoon.
  Implementation (W1–W6, 30 tasks) plus Step 7 (3 rounds for test-quality, 1–2 rounds for others) plus Step 8 ran
  through the evening.
- **Specialist launch counts:**
  - `intent-analyst` × 1
  - `researcher` × 5 (skills-lock-registry, plugin-discovery-mechanism, cross-references, skill-content-migration,
    scripts-and-slash-commands)
  - `architect` × 1
  - `qa-analyst` × 1
  - `implementer` × ≈30 (plus re-activations T5-r2, T18-T20-T21-r2, T28-r2)
  - `reviewer` × 6 (security, performance, holistic, readability, api-design, test-quality), plus re-runs:
    holistic Round 2, readability Round 2, api-design Round 2, test-quality Round 2 + Round 3
  - `validator` × 1
  - `retrospective-writer` × 1 (this report)
- **Effective parallelism:** High during Step 2 (5 researchers concurrent), Step 7 (6 reviewers concurrent), and W1
  / W2 / W3 / W4 / W5 implementer waves. Lower during Step 1 / 3 / 5 / 8 / 9 (Main-only or single-specialist
  phases).
- **Re-activation overhead:** 5 implementer re-activations across 2 commits (T5-r2 / T28-r2 being the canonical
  Step-7-driven cases; T18-T20-T21-r2 grouped as one translation pass). Minor cost relative to total work.

## dev-workflow reflection candidates (consolidated)

For convenience, the changes proposed under Process improvements + Skill improvements + Specialist prompt
improvements are summarised here as a single list. Each item is tagged with disposition:

| ID   | Proposal                                                                                                     | Action                                                                                       | Severity |
| ---- | ------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------- | -------- |
| U-A  | Review response policy (in-cycle fix for cycle files; retro for dev-workflow / other work)                   | dev-workflow reflection (`specialist-reviewer/SKILL.md`)                                     | Major    |
| U-B  | Retrospective scoping discipline (cross-cycle value default; "rejected as non-general" valid)                | dev-workflow reflection (`share-artifacts/references/retrospective.md`)                      | Major    |
| PR-1 | Parallel implementer in 1 worktree → file-only + Main sequential commit                                      | dev-workflow reflection (`step-implementation/SKILL.md` + `specialist-implementer/SKILL.md`) | Major    |
| PR-2 | qa-analyst must dry-run grep / awk / sed recipes against repo before commit                                  | dev-workflow reflection (`specialist-qa-analyst/SKILL.md`)                                   | Major    |
| PR-3 | grep-driven tasks → explicit grep target list + post-edit re-run check                                       | dev-workflow reflection (`step-task-decomposition/SKILL.md`)                                 | Minor    |
| PR-4 | design.md must record validation-environment constraints (sandbox / network / codegen / build prerequisites) | dev-workflow reflection (`step-design/SKILL.md` + `share-artifacts/references/design.md`)    | Minor    |
| PR-5 | In-cycle user directives at Step 8 → record as in-cycle commit, not Step-6 re-activation                     | Already common practice; no skill change                                                     | Info     |

### Cross-cycle retrospective candidates (not dev-workflow targets)

| ID  | Carryover item (from Step 7 reviews)                                                                                 | Source                               | Disposition                                                                                                                                                                                                                                                                                                                                                                                                        |
| --- | -------------------------------------------------------------------------------------------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| R1  | `mbt/package/geo/CLAUDE.md:35` `For MoonBit coding conventions, see @SKILL.md` (no `SKILL.md` exists at that path)   | holistic m-3 / api-design follow-up  | Separate cycle. Ask user for original intent of `@SKILL.md` (literal `@`-import? typo for `@<skillname>`?). Out of scope for this cycle's restructure.                                                                                                                                                                                                                                                             |
| R2  | `.agents/plugins/marketplace.json` `source.path` shows `././plugins/totto2727-coding` (double `./`)                  | holistic m-4                         | Separate cycle (target: `c-plugin` plugin). The double-`./` is from `marketplace-sync.ts:77`'s template literal over an already-`./`-prefixed source. Pre-existing.                                                                                                                                                                                                                                                |
| R3  | TC-IMPL-001 candidate: IDE-level Deno lib mismatch on `generate-docs-*.ts` (LSP TS2345 vs `deno check` exit 0)       | test-quality m-1                     | Rejected as non-general. The IDE / LSP lib mismatch is a project-environment issue specific to this repo's oxlint / TS lib config — would not generalise to other cycles. Worth resolving in a `c-plugin` / config-hygiene cycle, not as a TC-IMPL.                                                                                                                                                                |
| R4  | TC-022 partial automation feasible (manifest shape check)                                                            | test-quality m-2                     | Rejected as non-general. The split (automated-half + manual-half) only matters for plugins that depend on Claude-Code-session-level discovery; not a general dev-workflow pattern. Track as a one-off in this plugin's docs only.                                                                                                                                                                                  |
| R5  | TC-024 "subsumed by TC-013" comment in qa-design.md L84 is technically inaccurate                                    | test-quality m-3                     | Rejected as non-general. Single-sentence wording fix in qa-design.md only; not a workflow pattern.                                                                                                                                                                                                                                                                                                                 |
| R6  | `coding/SKILL.md` L161-164 hard-wraps `vp\ncheck` inline-code span                                                   | readability m-1                      | Resolved in `a2f69b6` during Step 8. (Confirmation only; no carryover.)                                                                                                                                                                                                                                                                                                                                            |
| R7  | Inconsistent linking discipline in `<lang>-skill.md` Related references (sibling skills without Markdown link)       | readability m-2                      | Resolved in `cea1f2b` (U1) during Step 8. (Confirmation only; no carryover.)                                                                                                                                                                                                                                                                                                                                       |
| R8  | `test/SKILL.md` L116-119 trailing "without any retroactive cleanup" reads as private memo                            | readability m-3                      | Resolved in `5552425` during Step 8. (Confirmation only.)                                                                                                                                                                                                                                                                                                                                                          |
| R9  | `docs-moonbit/SKILL.md` is 313 lines (above 300 cap; cap applies only to `coding/SKILL.md` / `test/SKILL.md`)        | performance m-3                      | Rejected as non-general for this cycle. The cap was deliberately scoped to entry SKILL.md in Intent Spec SC-3; auto-generated docs skills are explicitly exempt. Could be revisited if Tier-1 activation budget becomes a measured concern across the marketplace, in which case it becomes a project-wide policy ADR candidate.                                                                                   |
| R10 | `generate-docs-components-build.ts` N+1 sequential fetch (loop over slugs)                                           | performance m-1                      | Separate cycle (target: `totto2727-coding/.script/`). Pre-existing in source script; out of scope for this cycle ("移行はリネームと相対パス調整のみ"). Convert to `Promise.all` with concurrency cap when next touched.                                                                                                                                                                                            |
| R11 | `generate-docs-moonbit.ts` accepts arbitrary URLs from `Deno.args` and fetches them with no host allow-list          | security m-2                         | Separate cycle (target: `totto2727-coding/.script/`). Pre-existing posture; documented invocation always uses `docs.moonbitlang.com`. Optional hardening: add `new URL(url).hostname === 'docs.moonbitlang.com'` check.                                                                                                                                                                                            |
| R12 | `docs-moonbit` skill `description` is shorter than peers, weakening auto-discovery rank                              | api-design i-1                       | Separate cycle (target: `totto2727-coding/skills/docs-moonbit/SKILL.md`). Quick polish during the next time the file is regenerated.                                                                                                                                                                                                                                                                               |
| R13 | Slash command placement under `.claude-plugin/commands/` inconsistent with other plugins                             | api-design i-2                       | Rejected as non-general. Convention is mixed across the repo; not this cycle's job to unify. Track only if a project-wide ADR proposes a uniform layout.                                                                                                                                                                                                                                                           |
| R14 | `coding/SKILL.md` L150-153 path-based reference (vs skill-name-based external-reference policy)                      | api-design i-3                       | Resolved in `cea1f2b` (U1) during Step 8 for sibling-skill cases. The hard-coded path remained intentional for in-plugin index linkage. (Confirmation only.)                                                                                                                                                                                                                                                       |
| R15 | TC-022 post-merge plugin discovery smoke test                                                                        | qa-design.md L31 / Validation Case 2 | Post-merge follow-up. Open a fresh Claude Code session in `/Users/totto2727/proj/monorepo/` after PR merges to `main` and confirm `totto2727-coding:coding`, `totto2727-coding:test`, `totto2727-coding:docs-moonbit`, `totto2727-coding:docs-components-build` all appear in the available skills list. Record outcome as a comment on the PR or in a follow-up note. NOT a separate cycle — single manual check. |
| R16 | SC-10 `vp check` was Deferred during validator's sandboxed run; Main re-ran prebuild outside sandbox to confirm PASS | Validation Report Case 1             | dev-workflow reflection (PR-4 above): record validation-environment constraints in design.md so future cycles aren't surprised. Already covered.                                                                                                                                                                                                                                                                   |

## ADR migration candidates

The following retro insights could become ADRs (durable cross-cycle decisions). Each is a candidate, not yet
authored. The next cycle's intent-clarification should evaluate them:

- **ADR candidate #1: "Parallel implementers in single worktree → file-only convention"** (PR-1). Cross-cutting, applies
  whenever any future cycle uses parallel implementer launches in the cycle's worktree.
- **ADR candidate #2: "Review response policy"** (User policy A). Cross-cutting; applies to all dev-workflow cycles
  going forward.
- **ADR candidate #3: "Retrospective scoping discipline"** (User policy B). Same scope as #2.

These three should land as ADRs once the next cycle decides which to elevate (the current cycle's retrospective is
volatile by design).

<!--
Authoring guide: plugins/dev-workflow/skills/share-artifacts/references/retrospective.md
Lifecycle: this file is volatile; deleted once the next cycle digests the improvement items.
ADR escalation: items marked "ADR candidate" should be evaluated for `share-adr` migration before deletion.
-->
