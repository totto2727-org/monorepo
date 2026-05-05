# Review Report: Readability

- **Cycle:** 2026-05-04-totto2727-coding-plugin
- **Aspect:** readability — naming, structure, separation of responsibilities, comment quality, language consistency
- **First reviewed:** 2026-05-04
- **Last updated:** 2026-05-04
- **Final Gate:** approved
- **Round count:** 2

## Findings list

| ID  | Severity | Finding                                                                                                                                                                                                                                                                                                                                                                                     | State               | First Round | Resolution commit | Notes                                                                                                           |
| --- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ----------- | ----------------- | --------------------------------------------------------------------------------------------------------------- |
| M-1 | Major    | `generate-docs-moonbit.ts` retains the old script name `process-moonbit-docs.ts` in the file-header comment and in the Usage error message                                                                                                                                                                                                                                                  | fixed               | 1           | 70e19f7           | See M-1 detail + Round 2 verification. Conflicts with intent-spec.md L165-167; resolved in Round 2.             |
| M-2 | Major    | Three of the four `<lang>-skill.md` intermediate index files mix Japanese narrative with English bullets, violating the global "Markdown Output: Always output documentation in English" rule                                                                                                                                                                                               | fixed               | 1           | 1cbdd8f           | See M-2 detail + Round 2 verification. All three files rewritten to English; resolved in Round 2.               |
| m-1 | Minor    | `coding/SKILL.md` L163-164 hard-wraps an inline-code span across a line break (`` `vp\ncheck` ``), creating a visually broken token in the Related skills bullet for `vite-plus`                                                                                                                                                                                                            | pending             | 1           | -                 | See m-1 detail. Markdown will collapse the newline to a space at render time, but the source is awkward to read |
| m-2 | Minor    | `coding/references/mbt-skill.md` lists "MoonBit testing standards" as a `Related references` pointer using a name-only reference (`test` skill, `mbt-bestpractice` under `test/references/`) without a Markdown link, while the very next line links `docs-moonbit` with a Markdown link — inconsistent linking discipline within the same file                                             | pending             | 1           | -                 | See m-2 detail. The same inconsistency mirror-image appears in `test/references/mbt-skill.md`                   |
| m-3 | Minor    | `test/SKILL.md` L116-119 describes the TS index as "Currently lists external skill references only ... no in-plugin TS test detail files yet ... will be added ... without any retroactive cleanup" — the "without any retroactive cleanup" tail dangles without explaining what the cleanup would otherwise be, and reads as an incidental implementation note rather than reader guidance | pending             | 1           | -                 | See m-3 detail                                                                                                  |
| i-1 | Info     | `coding/SKILL.md` and `test/SKILL.md` frontmatter `description:` fields are well-shaped for auto-discovery (clear "Use when" + "Do NOT use for" + activation triggers); 300-line hard cap respected (181 / 128 lines)                                                                                                                                                                       | (consistency check) | 1           | -                 | No action required                                                                                              |
| i-2 | Info     | T28 (12 dev-workflow placeholder occurrences) all rewritten to representative-only example list using `coding`, `test`, `git-workflow`, `macos-cli-rules` consistently; no leftover `effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp` mentions found in the 12 listed sites                                                                                                | (consistency check) | 1           | -                 | Verified by grep on all 12 paths in design.md:303 / task-plan.md T28                                            |
| i-3 | Info     | All 7 migrated `references/*.md` files start with H1 (frontmatter strip applied as required by intent-spec.md Open question 6 / design.md A5)                                                                                                                                                                                                                                               | (consistency check) | 1           | -                 | Verified by `head -1` on every reference file under coding/references and test/references                       |
| i-4 | Info     | `update-docs-moonbit.md` and `update-docs-components-build.md` slash commands are syntactically clean, refer to the new script names (`generate-docs-moonbit.ts` / `generate-docs-components-build.ts`), and use bash code blocks consistently                                                                                                                                              | (consistency check) | 1           | -                 | Verified at L22 / L17 respectively                                                                              |

## Detailed sections

### M-1 detail: `generate-docs-moonbit.ts` retains old script name in comment + Usage line

`plugins/totto2727-coding/.script/generate-docs-moonbit.ts`:

```ts
//   sfw deno run --allow-net --allow-read --allow-write .script/process-moonbit-docs.ts \    // ← L8: stale name
//     https://docs.moonbitlang.com/en/latest/_downloads/.../summary.md \
//     https://docs.moonbitlang.com/en/latest/_downloads/.../summary.md
...
if (urls.length === 0) {
  console.error('Usage: deno run --allow-net --allow-read --allow-write .script/process-moonbit-docs.ts <URL> [URL...]')   // ← L16: stale name shown to script users on misuse
  Deno.exit(1)
}
```

These two occurrences contradict the rename spelled out in `intent-spec.md` L165-167 / `task-plan.md` T5. A reader trying to follow the file-header comment to actually run the script will type the wrong filename and get "module not found"; a user who misuses the CLI will see "Usage: ... process-moonbit-docs.ts ..." and waste time looking for a non-existent file. Sister script `generate-docs-components-build.ts` correctly uses the new name in both its comment and Usage line — the inconsistency between the two scripts is itself a readability defect.

**Recommended fix:** replace both occurrences with `generate-docs-moonbit.ts`. Single-commit change, no logic touched.

### M-2 detail: Mixed Japanese / English in `<lang>-skill.md` intermediate indexes

The four newly authored intermediate index files do not share a language register:

- `coding/references/ts-skill.md` — fully English.
- `coding/references/mbt-skill.md` — Japanese intro line ("このファイルは coding スキルの MoonBit 中間目次です。") + English bullets + Japanese parenthetical ("(本サイクル時点では MoonBit 関連の外部スキルなし。将来追加余地。)").
- `test/references/ts-skill.md` — Japanese intro line + Japanese parenthetical + English bullet.
- `test/references/mbt-skill.md` — Japanese intro line + Japanese parenthetical + English bullets.

This violates the user's global instruction "Markdown Output: Always output documentation in English" (per `~/.claude/CLAUDE.md`). It is also an internal inconsistency — `coding/SKILL.md` and `test/SKILL.md` (the parents) are uniformly English, and `ts-skill.md` (coding) shows the intended target register. Readers switching from `coding/SKILL.md` (English) into `mbt-skill.md` (mixed) hit a sudden language register change with no semantic justification.

**Recommended fix:** rewrite the three offending files in English to match `coding/references/ts-skill.md`'s register. Suggested phrasing:

- "This file is the Tier-2 MoonBit index for the `coding` skill." (replace "このファイルは coding スキルの MoonBit 中間目次です。")
- "(No external MoonBit skill references at this cycle; placeholder for future additions.)" (replace the Japanese parenthetical).

Roughly 10-line touch across three files.

### m-1 detail: Inline-code span hard-wrapped in `coding/SKILL.md` Related skills bullet

`coding/SKILL.md` L161-164:

```md
- **`vite-plus`** (external skill, npm-package-bundled) — the project's
  unified toolchain (Vite / Vitest / monorepo orchestration). Referenced
  from `references/ts-skill.md` for concrete `vp run` / `vp test` / `vp
check` usage.
```

The `vp check` token is split across L163-L164 inside backticks and the continuation line is also unindented (column 0 instead of the 2-space bullet continuation). Most renderers will still produce a single space between `vp` and `check` because the inline code spans the line break (Markdown spec collapses), but reading the source text is jarring and the de-indent makes the bullet look like the start of a new paragraph in editors that highlight by indent.

**Recommended fix:** move the entire inline-code list onto one line, accepting a slightly longer Related-skills bullet (still well under any 300-line cap). Pure cosmetic, no semantic change.

### m-2 detail: Inconsistent linking discipline in `<lang>-skill.md` Related references sections

`coding/references/mbt-skill.md` L13-16:

```md
## Related references

- For MoonBit language reference (syntax / types / functions / methods), see [docs-moonbit](../../docs-moonbit/SKILL.md).
- For MoonBit testing standards, see `test` skill (`mbt-bestpractice` under `test/references/`).
```

The first bullet uses a Markdown link to the sibling `docs-moonbit` skill (path stable, in the same plugin). The second bullet uses **name-only** reference for the sibling `test` skill (also path stable, also in the same plugin). The asymmetry is unjustified by intent-spec.md A10's "name-only for external skills" rule, because `test` is _not_ an external skill — it lives in this plugin at a stable path. The inconsistency hurts predictability: readers cannot tell at a glance whether to expect a clickable link or a name-only auto-discovery hint.

The same mirror-image asymmetry appears in `test/references/mbt-skill.md` (links to `coding` skill name-only despite the path being stable).

**Recommended fix:** in both files, replace the name-only `test` / `coding` references with a Markdown link to `../../<sibling>/SKILL.md` (sibling-skill, path-stable), keeping name-only purely for _external_ skills (`vite-plus`, `remix`).

### m-3 detail: `test/SKILL.md` Language index TS bullet ends with a meta-implementation note

`test/SKILL.md` L116-119:

```md
- **TypeScript** — see [ts-skill.md](references/ts-skill.md). Currently lists external skill
  references only (test runner via `vite-plus` / Vitest); no in-plugin TS test detail files yet.
  Future TS test conventions will be added as `ts-<topic>.md` files alongside this index without
  any retroactive cleanup.
```

The trailing "without any retroactive cleanup" reads as a private project memo rather than reader-facing guidance. The reader does not know what the "retroactive cleanup" alternative would have been (re-shape SKILL.md? rename existing files?), so the assurance is meaningless to them. The MoonBit bullet just below is concise and reader-focused; the TS bullet should mirror that shape.

**Recommended fix:** drop the "without any retroactive cleanup" clause. Suggested rewrite:

```md
- **TypeScript** — see [ts-skill.md](references/ts-skill.md). Currently lists external test-runner skills only (`vite-plus` for Vitest via `vp test`); per-language TS test detail files (`ts-<topic>.md`) will be added alongside this index as conventions emerge.
```

## Round 2 (2026-05-04)

Round 2 scope: re-verify the two Major findings (M-1, M-2) against the Round 2 fix commits. The three Minor findings (m-1, m-2, m-3) are accepted-as-is for this cycle and deferred to retrospective for future polish — they do not block Gate.

### Round 2 verification results

#### M-1 — fixed (commit `70e19f7`)

`grep -n "process-moonbit-docs" plugins/totto2727-coding/.script/generate-docs-moonbit.ts` returns no match. Re-read of the file confirms:

- L8 (file-header Usage example): now `sfw deno run --allow-net --allow-read --allow-write .script/generate-docs-moonbit.ts ...` — old name removed.
- L16-18 (runtime Usage error message): now `'Usage: deno run --allow-net --allow-read --allow-write .script/generate-docs-moonbit.ts <URL> [URL...]'` — old name removed.

The two scripts (`generate-docs-moonbit.ts` and `generate-docs-components-build.ts`) are now consistent in both file-header comment and Usage error message. Resolution matches the recommended fix from Round 1 detail (single-commit, comment-and-string-only change, no logic touched).

#### M-2 — fixed (commit `1cbdd8f`)

All three previously mixed-language Tier-2 index files now match `coding/references/ts-skill.md`'s English-only register:

- `plugins/totto2727-coding/skills/coding/references/mbt-skill.md`
  - L1 H1: `# MoonBit Conventions Index` (English).
  - L3 intro: `Tier-2 index for MoonBit conventions in the \`coding\` skill.` (English; replaces Japanese intro line).
  - L11 placeholder: `(None at this time. Future MoonBit-related external skills will be listed here by name only, per the external-reference policy.)` (English; replaces Japanese parenthetical).
- `plugins/totto2727-coding/skills/test/references/ts-skill.md`
  - L1 H1: `# TypeScript Test Conventions Index` (English).
  - L3 intro: `Tier-2 index for TypeScript test conventions in the \`test\` skill. This index currently holds only external skill references; in-plugin TS test conventions will be added in a future cycle.` (English).
  - L7 placeholder: `(None yet. Add \`ts-<topic>.md\` files here when TS test conventions are introduced.)` (English).
- `plugins/totto2727-coding/skills/test/references/mbt-skill.md`
  - L1 H1: `# MoonBit Test Conventions Index` (English).
  - L3 intro: `Tier-2 index for MoonBit test conventions in the \`test\` skill.` (English).
  - L11 placeholder: `(None at this time. Future MoonBit-test-related external skills will be listed here by name only.)` (English).

No residual Japanese narrative remains in any of the four `<lang>-skill.md` intermediate indexes. The global instruction "Markdown Output: Always output documentation in English" is now satisfied across the whole Tier-2 index set, and the language register no longer changes when readers descend from `coding/SKILL.md` / `test/SKILL.md` (English) into the per-language indexes.

#### Minor findings (m-1, m-2, m-3) — accepted-as-is

- m-1 (inline-code hard-wrap in `coding/SKILL.md` L161-164): cosmetic only; Markdown renderer collapses the newline. Deferred.
- m-2 (Markdown link vs. name-only inconsistency between `mbt-skill.md` Related references bullets, in both `coding/references/` and `test/references/`): policy edge case (sibling-skill-in-same-plugin path is stable but external-skill-rule was applied uniformly); deferred to retrospective for a project-wide rule clarification rather than a per-file patch.
- m-3 (`test/SKILL.md` L116-119 trailing "without any retroactive cleanup" reads as private memo): low-severity wording polish; deferred.

These three are explicitly out of scope for the Round 1 → Round 2 round-trip and do not affect the Round 2 Gate. They are flagged in the cycle's retrospective candidate list.

### Round 2 supplementary observation (commit `309a84c`, T28-r2)

Commit `309a84c` (T28-r2: rewrite 4 dev-workflow files for stale skill names) is primarily an api-design / holistic concern, but it incidentally improves readability by removing stale skill-name references from `dev-workflow` documentation. No new readability defect introduced; sampled the 4 rewritten files via diff and confirmed naming consistency with the new `coding` / `test` plugin layout. No finding raised.

### Round 2 Gate

| Severity     | Count                                             |
| ------------ | ------------------------------------------------- |
| Blocker      | 0                                                 |
| Major (open) | 0                                                 |
| Minor (open) | 3 (all accepted-as-is, deferred to retrospective) |

Round 2 Gate: **`approved`**.

## Round history metadata

| Round | Date       | Reviewer instance      | Round-only Gate |
| ----- | ---------- | ---------------------- | --------------- |
| 1     | 2026-05-04 | reviewer (readability) | needs_fix       |
| 2     | 2026-05-04 | reviewer (readability) | approved        |

Final Gate: `approved`. 0 Blocker, 0 Major open. 2 Major (M-1, M-2) resolved in Round 2 (commits `70e19f7`, `1cbdd8f`). 3 Minor (m-1, m-2, m-3) accepted-as-is, deferred to retrospective.

<!--
Authoring guide: plugins/dev-workflow/skills/share-artifacts/references/review-report.md
Per-aspect emphasis: plugins/dev-workflow/skills/specialist-reviewer/SKILL.md "readability"
-->
