# Review Report: Test Quality

- **Cycle:** 2026-05-04-totto2727-coding-plugin
- **Aspect:** test-quality — observable acceptance check coverage, determinism, and TC-design correctness for the documentation/plugin restructuring cycle (no test framework runner; checks are bash + jq + deno + grep + wc).
- **First reviewed:** 2026-05-04
- **Last updated:** 2026-05-04
- **Final Gate:** approved
- **Round count:** 3

## Findings list

| ID  | Severity | Finding                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | State   | Detected Round | Resolved commit | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| --- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | -------------- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| M-1 | Major    | TC-013/014 A10 exclusion rule ("take only lines preceding `## External skill references`") wrongly excludes the legitimate `## Related references` section that exists AFTER the External heading in `coding/references/mbt-skill.md` and `test/references/mbt-skill.md`. The real link `[docs-moonbit](../../docs-moonbit/SKILL.md)` (mbt-skill.md L15) is not validated under the current TC-013 procedure.                                                                                                                   | fixed   | 1              | 784324d         | See [detail](#m-1-detail-tc-013-exclusion-truncation-overshoots). qa-design.md TC-013/014 Pass criterion changed in 784324d: exclusion now scopes to the body of the External skill references section only (lines from `^## External skill references$` up to but not including the next `^## ` heading). Round 2 verification: simulated awk extraction on `coding/references/mbt-skill.md` correctly retains `[docs-moonbit](../../docs-moonbit/SKILL.md)` (L15) in the link set.                                             |
| M-2 | Major    | TC-018 grep regex `\bmoonbit-docs\b` produces ~25 false-positive matches inside `plugins/totto2727-coding/skills/docs-moonbit/**` from upstream-attribution comments `<!-- https://github.com/moonbitlang/moonbit-docs -->`. As written, TC-018 will not pass even on a clean implementation. SC-6 cannot be met without either an additional exclusion or a more selective regex.                                                                                                                                              | fixed   | 1              | 784324d         | See [detail](#m-2-detail-tc-018-false-positive-on-upstream-repo-name). qa-design.md TC-018 Pass criterion changed in 784324d: pipeline now appends `\| grep -v '<!--' \| grep -v 'github\.com/moonbitlang/moonbit-docs'`. Round 2 verification: 25-of-25 docs-moonbit upstream-URL hits are now suppressed (raw 38 → after `<!--` filter 10 → after upstream-URL filter 9). However the residual 9 matches reveal a NEW false positive class — see M-4 below.                                                                    |
| M-3 | Major    | TC-018 / TC-025 do not cover the script body. The renamed `generate-docs-moonbit.ts` still contains stale `process-moonbit-docs.ts` strings at L8 and L16 (header comment + usage message). TC-025 scans only slash command files, and TC-018's regex word list does not include `process-moonbit-docs\.ts` or `generate-skill\.ts`. SC-6 (no leftover references) will silently pass while a leftover persists.                                                                                                                | fixed   | 1              | 70e19f7+784324d | See [detail](#m-3-detail-script-body-not-covered-by-leftover-grep). Two-part fix: (a) 70e19f7 (T5-r2) removed both stale strings from `generate-docs-moonbit.ts` (L8 header comment + L16 usage message); (b) 784324d added `process-moonbit-docs\.ts` and `generate-skill\.ts` to TC-018 regex AND extended TC-025 with a `grep -E 'process-moonbit-docs\.ts\|generate-skill\.ts'` zero-match assertion. Round 2 verification: `grep -rn 'process-moonbit-docs\|generate-skill' .script/` returns 0 matches.                    |
| M-4 | Major    | (Round 2 new) TC-018 grep recipe (after 784324d) still produces 9 residual false positives because `\beffect-layer\b` / `\beffect-runtime\b` / `\beffect-hono\b` / `\btotto2727-fp\b` patterns match the new in-plugin filenames `ts-effect-layer.md` / `ts-effect-runtime.md` / `ts-effect-hono.md` / `ts-totto2727-fp.md`. The hyphen `-` is not a word character, so `\b` succeeds on the `s\|-` boundary right before `effect-layer` in `ts-effect-layer.md`. TC-018 will fail to pass on the current clean implementation. | fixed   | 2              | 18187bf         | See [detail](#m-4-detail-tc-018-false-positive-on-ts-prefix-renames). qa-design.md TC-018 Pass criterion changed in 18187bf: pipeline now appends `\| grep -v -E '/ts-(effect-(layer\|runtime\|hono)\|totto2727-fp)\.md'` (option (a) from M-4 detail). Round 3 verification: full TC-018 grep pipeline (positive regex + 3 exclusion stages: `<!--`, upstream URL, new Tier-3 filenames) executed against the post-18187bf tree returns 0 matches (`exit=1` = no-match success), confirming SC-6 is now observably satisfiable. |
| m-1 | Minor    | TC-IMPL-NNN section was kept empty during Step 6 even though three implementation-time issues that meet the TC-IMPL criterion ("defensive branches that arise only in concrete implementation") were observed: (a) W2 git-index race condition, (b) W3 git-index race condition, (c) IDE-level Deno lib mismatch on `generate-docs-*.ts` (LSP TS2345 vs `deno check` exit 0).                                                                                                                                                   | pending | 1              | -               | progress.yaml.notes captures these but qa-design.md TC-IMPL stays as the placeholder TBD row. Per `share-artifacts/references/qa-design.md`, TC-IMPL is for "defensive branches in the implementation". (a)/(b) are process issues (retrospective material, not TC-IMPL); (c) is a real LSP-vs-runtime branching candidate worth capturing as TC-IMPL-001. Recommend appending TC-IMPL-001 for (c) only.                                                                                                                         |
| m-2 | Minor    | TC-022 (manual × scenario, post-merge plugin discovery) has no automation alternative recorded even though `c-plugin dev marketplace sync` (W6-T1) generated `.cursor-plugin/marketplace.json` + `.agents/plugins/marketplace.json` and these can be parsed offline for a partial smoke ("manifest is shaped right") prior to merge.                                                                                                                                                                                            | pending | 1              | -               | See [detail](#m-2-detail-tc-022-partial-automation-feasible). Not a Blocker because the worktree-vs-main-checkout caveat for the actual Claude Code session is real. Recommend keeping TC-022 as-is + adding TC-IMPL or a new automated TC for the offline manifest-parse smoke.                                                                                                                                                                                                                                                 |
| m-3 | Minor    | TC-024 is described as "subsumed by TC-013 in principle" but TC-013 currently does not validate this specific file (TC-013 scans `coding/references/ts-skill.md` and `coding/references/mbt-skill.md`, not `coding/references/mbt-bestpractice.md`). The "subsumed" comment in qa-design.md L84 Notes column is technically inaccurate.                                                                                                                                                                                         | pending | 1              | -               | Minor because TC-024 is a separate explicit TC, so the design-A7 link is still validated. Just a documentation tidy-up on qa-design.md L84 Notes.                                                                                                                                                                                                                                                                                                                                                                                |
| i-1 | Info     | Coverage table is complete: every SC-1..SC-10 has at least one TC. SC-2 has the most TCs (10, including cross-references), reflecting its breadth (manifest + 4 SKILL.md + 7 + 3 references + 2 scripts + 2 slash commands + cross-link + rename + script template).                                                                                                                                                                                                                                                            | -       | 1              | -               | (consistency check)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| i-2 | Info     | qa-flow.md sections 1-6 leaves are all TC-NNN (no skip leaves). Section 6 (TC-022, manual × scenario) correctly notes the deferred-success branch.                                                                                                                                                                                                                                                                                                                                                                              | -       | 1              | -               | (consistency check)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| i-3 | Info     | Actor × Style enums respect the forbidden combination: zero `automated × inspection`. Single `manual × scenario` (TC-022) has rationale recorded as required.                                                                                                                                                                                                                                                                                                                                                                   | -       | 1              | -               | (consistency check)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |

## Detailed sections

### M-1 detail: TC-013 exclusion truncation overshoots

The design A10 rule is: "the External skill references section intentionally lists external skills by name only with no Markdown link, so SC-4 must skip that section". TC-013/014's pass criterion implements this by truncating at the first occurrence of `## External skill references` and resolving links only on the prefix.

But the implemented Tier-2 files do not always end with the External skill references section. In particular:

`plugins/totto2727-coding/skills/coding/references/mbt-skill.md`:

```markdown
## In-plugin detail files

- [mbt-bestpractice.md](./mbt-bestpractice.md) — ... (real link, gets validated)

## External skill references

(本サイクル時点では MoonBit 関連の外部スキルなし。)

## Related references

- For MoonBit language reference (syntax / types / functions / methods), see [docs-moonbit](../../docs-moonbit/SKILL.md). ← real cross-skill link, NOT validated under current TC-013
- For MoonBit testing standards, see `test` skill ... ← name-only, OK to skip
```

`plugins/totto2727-coding/skills/test/references/mbt-skill.md` has the same shape with `[mbt-bestpractice]` style coding-skill reference under `## Related references`.

The current TC-013 procedure ("take only lines preceding `## External skill references`") drops the `## Related references` section entirely. This is a false-negative: a broken link inside `## Related references` would not be detected.

Fix options (in order of preference):

1. **Change the exclusion semantics in qa-design.md TC-013/014**: skip only the body of the External skill references section (lines from `^## External skill references$` up to the next `^## ` line, exclusive). The link extraction then runs on (prefix) + (suffix-after-next-heading). One-line awk: `awk '/^## External skill references/{skip=1; next} skip && /^## /{skip=0} !skip' file.md`.
2. Alternatively, **move `## External skill references` to be the last section in every Tier-2 file** (a content reorganization). This makes the "truncate at heading" rule sound, but it is brittle to future reorderings.
3. Alternatively, **introduce HTML comment markers** (`<!-- a10-exclude-start -->` / `<!-- a10-exclude-end -->`) around the External skill references section and exclude based on those.

Recommendation: option 1, because it requires no content rewrite and is explicit about scope.

### M-2 detail: TC-018 false positive on upstream repo name

TC-018's regex word list includes `\bmoonbit-docs\b` to detect the old skill name. The renamed `docs-moonbit` files (25+ files: SKILL.md plus references) include the upstream attribution comment `<!-- https://github.com/moonbitlang/moonbit-docs -->` at the top of every file. This is **legitimate** — it points at the official MoonBit docs repo, not the old plugin path — but the regex matches it because `-` is not a word character so the boundary `\b` succeeds before and after `moonbit-docs`.

I confirmed this empirically by running the TC-018 regex against the current implementation: 25 false-positive hits inside `plugins/totto2727-coding/skills/docs-moonbit/**`. As written, TC-018 will not pass even though SC-6's intent (no remaining old-path / old-name references) is satisfied.

Fix options:

1. **Add `--exclude-dir=plugins/totto2727-coding/skills/docs-moonbit`** to the TC-018 grep, plus a separate small TC that asserts the upstream attribution URL is canonical (`https://github.com/moonbitlang/moonbit-docs`).
2. Tighten the regex so it does not match inside URLs: e.g. `(?<![/\w])moonbit-docs(?![/\w])`. Note that GNU grep -E is POSIX ERE and does not support lookbehind; this needs `grep -P` (Perl regex) or migration to `rg`/`ripgrep`.
3. Replace the regex hit with two narrower checks: (a) `grep -E 'name:\s*moonbit-docs'` (frontmatter occurrence — should be 0) and (b) `grep -E 'skills/moonbit-docs/'` (path occurrence — should be 0). The current "any mention of the bareword" is too permissive.

Recommendation: option 3 — narrower checks express the actual leak we want to detect (frontmatter or path) without having to special-case directories or escape regex flavors.

### M-3 detail: Script body not covered by leftover grep

The renamed `plugins/totto2727-coding/.script/generate-docs-moonbit.ts` retains stale `process-moonbit-docs.ts` references in the file header comment (L8) and the CLI usage message (L16):

```ts
// L8:  //   sfw deno run --allow-net --allow-read --allow-write .script/process-moonbit-docs.ts \
// L16: console.error('Usage: deno run --allow-net --allow-read --allow-write .script/process-moonbit-docs.ts <URL> [URL...]')
```

Neither TC-018 nor TC-025 catches this:

- TC-018's regex does not include `process-moonbit-docs\.ts` (only the bare names `moonbit-docs`, `effect-layer`, etc.).
- TC-025's grep targets the **slash command** files (`update-docs-*.md`) only, not the script bodies.

This is a real leftover that would silently survive the entire SC-6 / SC-7 grid: SC-7 (`deno check`) only checks types, and SC-6 grep does not know to look for `process-moonbit-docs.ts`.

Fix options:

1. **Extend TC-025** to also assert: `grep -E 'process-moonbit-docs\.ts|generate-skill\.ts' plugins/totto2727-coding/.script/*.ts` returns no matches. This is a minimal change and keeps TC-025 as the "old script-name eradication" TC.
2. **Add TC-018b** specifically for the script bodies: `grep -E 'process-moonbit-docs|generate-skill\.ts' plugins/totto2727-coding/.script/` returns no matches.

Either way, the implementer should also clean up the two stale strings in the same Step 6 round-trip — without that, the next reviewer round will fail this added check.

### m-2 detail: TC-022 partial automation feasible

TC-022 stays `manual × scenario` because the Claude Code session must be opened in `/Users/totto2727/proj/monorepo/` (not the worktree), per `research/plugin-discovery-mechanism.md` Implications #4. That part of the test cannot be automated within the cycle.

However, two pieces are automatable already and would not require a real Claude Code session:

1. **Manifest shape check** — `jq` over the three sync-derived `marketplace.json` files plus `.claude/settings.json` to assert that the `totto2727-coding` plugin entry is structurally present and well-formed. This is what TC-015/016/017/021 already do — TC-022 could declare itself "automated portions" and "manual portion (interactive Claude Code session)" separately.
2. **Skill auto-discovery preview** — In a fresh session opened in the worktree, `Skill` listing would still pick up symlink-style skills (`.agents/skills/`) but would NOT pick up directory-source plugins. This means the manual portion of TC-022 is precisely the assertion "the directory-source plugin loads in the main checkout" — already documented but worth surfacing as a 2-line addendum to TC-022.

Recommend not blocking on this; record as a Retrospective candidate for a future "split TC-022 into automated/manual halves" exercise.

### M-4 detail: TC-018 false positive on `ts-` prefix renames

After Round 1's M-2 fix landed (commit 784324d), the TC-018 grep pipeline correctly suppresses the 25 docs-moonbit upstream-URL false positives. However a separate false-positive class — invisible while M-2's noise dominated — is now exposed: 9 hits inside the new in-plugin filenames `ts-effect-layer.md`, `ts-effect-runtime.md`, `ts-effect-hono.md`, `ts-totto2727-fp.md`.

Empirical evidence (running the current TC-018 recipe against the post-Round-2 tree):

```
plugins/totto2727-coding/skills/coding/references/ts-skill.md:7:- [`ts-effect-layer.md`](./ts-effect-layer.md) ...
plugins/totto2727-coding/skills/coding/references/ts-skill.md:8:- [`ts-effect-runtime.md`](./ts-effect-runtime.md) ...
plugins/totto2727-coding/skills/coding/references/ts-skill.md:9:- [`ts-effect-hono.md`](./ts-effect-hono.md) ...
plugins/totto2727-coding/skills/coding/references/ts-skill.md:10:- [`ts-totto2727-fp.md`](./ts-totto2727-fp.md) ...
plugins/totto2727-coding/skills/coding/references/ts-effect-runtime.md:3:Related skills: [ts-effect-layer](./ts-effect-layer.md), [ts-effect-hono](./ts-effect-hono.md)
plugins/totto2727-coding/skills/coding/references/ts-effect-layer.md:3:Related skills: [ts-effect-runtime](./ts-effect-runtime.md), [ts-effect-hono](./ts-effect-hono.md)
plugins/totto2727-coding/skills/coding/references/ts-effect-hono.md:3:Related skills: [ts-effect-layer](./ts-effect-layer.md), [ts-effect-runtime](./ts-effect-runtime.md)
js/package/fp/README.md:5:[ts-totto2727-fp.md](https://github.com/.../ts-totto2727-fp.md)
js/package/fp/CLAUDE.md:3:[ts-totto2727-fp.md](../../../plugins/.../ts-totto2727-fp.md)
```

Root cause: in POSIX ERE, `-` is not a word character, so `\b` matches at every `s|-` boundary. `\beffect-layer\b` therefore matches the `effect-layer` substring inside the filename `ts-effect-layer.md` (boundary after `s`, boundary after `r`). These 9 matches are **legitimate new content** (the renamed Tier-3 detail files in `coding/references/` per design A6 / A8), not leftovers, but TC-018 reports them as failures.

Note: this finding was latent in Round 1 — the 25-strong docs-moonbit false-positive cluster (M-2) overshadowed the 9-strong `ts-` cluster, and Round 1's regex grouping `\beffect-layer\b` pattern was assumed to be safe because the "old" effect-layer skill paths (`.agents/skills/effect-layer/...`) had a leading `/` separator that would not be `-`. The new in-plugin Tier-3 filenames break this assumption.

Fix options (in order of preference):

1. **Extend the negative-match pipeline** in TC-018 with `\| grep -v -E '/ts-(effect-(layer\|runtime\|hono)\|totto2727-fp)(\.md)?'`. This keeps the existing positive regex but excludes the four known new-filename patterns. Pros: minimal change, easy to read. Cons: hard-codes filename list; another rename would need a new exclusion.
2. **Switch to `grep -P`** (Perl-compatible regex) and use lookbehind: `(?<![-\w])effect-layer\b` instead of `\beffect-layer\b`. Pros: structurally correct (the boundary is "no preceding alphanumeric or hyphen"). Cons: `grep -P` is a GNU extension and less portable; macOS `grep` does not support `-P` without `ggrep`.
3. **Replace the bare-name regex with narrower leak-surface checks** (recommended for this cycle). The actual leaks SC-6 wants to detect are:
   (a) frontmatter `name:` lines pointing at old skills — `grep -E '^name:\s*(effect-(layer\|runtime\|hono)\|totto2727-fp\|moonbit-bestpractice\|moonbit-docs\|components-build-docs)$'`,
   (b) old skill paths — `grep -rE '(\.agents/skills/(effect-(layer\|runtime\|hono)\|totto2727-fp)\|plugins/(moonbit\|components-build)/)'`,
   (c) old script names — already covered by the TC-018 additions of `process-moonbit-docs\.ts` / `generate-skill\.ts`.
   Pros: captures the precise leak class and is robust to future Tier-3 renames. Cons: TC re-design touches more lines.

Recommendation: option 1 for the quickest unblock (pure pipeline edit in qa-design.md TC-018 Pass criterion). If the team prefers structural correctness over speed, option 3 is the right long-term shape and aligns with what Round 1 detail recommended for M-2.

## Round history meta

| Round | Date       | Reviewer instance                               | Single-Round Gate |
| ----- | ---------- | ----------------------------------------------- | ----------------- |
| 1     | 2026-05-04 | reviewer (test-quality, initial)                | needs_fix         |
| 2     | 2026-05-04 | reviewer (test-quality, post-784324d + 70e19f7) | needs_fix         |
| 3     | 2026-05-04 | reviewer (test-quality, post-18187bf, M-4 only) | approved          |

Final Gate: `approved` (Round 3). All four Major findings (M-1, M-2, M-3 from Round 1; M-4 from Round 2) are now `fixed`. Round 1 Minors (m-1, m-2, m-3) remain `pending` per their original disposition (they are non-blocking documentation tidy-ups / scope-discussion items, not regressions). SC-6 is now observably satisfiable: the empirically-run TC-018 grep pipeline returns 0 matches against the current tree.

## Round 2 (2026-05-04)

Scope: re-verify M-1, M-2, M-3 against commits 784324d (qa-design.md TC-013/014/018 + TC-025 amendments) and 70e19f7 (T5-r2 implementation cleanup of `generate-docs-moonbit.ts` L8 / L16). Out of scope (Round 1 minors carried unchanged): m-1, m-2, m-3.

### Verification per finding

- **M-1 (TC-013/014 exclusion overshoot) — fixed.** The Pass criterion in qa-design.md L73 (TC-013) and L74 (TC-014) now reads "excluding only lines that fall within the `## External skill references` section itself". Procedure column documents the `^## External skill references` ↔ next `^## ` heading window for exclusion. Empirical re-simulation on `plugins/totto2727-coding/skills/coding/references/mbt-skill.md` retains the legitimate `[docs-moonbit](../../docs-moonbit/SKILL.md)` link in the validation set (line L15). `test/references/mbt-skill.md` has only text-only references in `## Related references` (no Markdown link), so the post-exclusion link set is correctly `[mbt-bestpractice.md](./mbt-bestpractice.md)` only.
- **M-2 (TC-018 docs-moonbit false positives) — fixed.** The Pass criterion in qa-design.md L78 (TC-018) now appends `\| grep -v '<!--' \| grep -v 'github\.com/moonbitlang/moonbit-docs'`. Empirical run on the post-implementation tree: 38 raw matches → 10 after `<!--` filter (drops 28 HTML-comment hits) → 9 after upstream-URL filter (drops the one `language-error-codes-index.md:15` URL reference). All 25-or-more docs-moonbit false positives originally reported in Round 1 are gone.
- **M-3 (script body leftover) — fixed.**
  - Implementation side (T5-r2 / 70e19f7): `grep -n "process-moonbit-docs" plugins/totto2727-coding/.script/generate-docs-moonbit.ts` returns 0 matches; both L8 (header comment) and L16 (usage message) now spell `generate-docs-moonbit.ts`.
  - QA-design side (784324d): TC-018 regex word list extended with `process-moonbit-docs\.ts` and `generate-skill\.ts`; TC-025 Pass criterion adds the assertion `grep -E 'process-moonbit-docs\.ts\|generate-skill\.ts' plugins/totto2727-coding/.claude/skills/update-docs-*.md` returns no matches. Both `update-docs-moonbit.md` and `update-docs-components-build.md` invoke the new script names.

### New findings discovered during Round 2

- **M-4 (Major, new):** TC-018 grep recipe produces 9 residual false positives on the renamed Tier-3 detail files (`ts-effect-layer.md`, `ts-effect-runtime.md`, `ts-effect-hono.md`, `ts-totto2727-fp.md`). See M-4 detail above for root cause and fix options. This is the same regex-shape concern raised under Round 1 M-2 option 3 (recommendation to replace bare-name regex with narrower leak-surface checks), but in Round 1 it was only a forward-looking suggestion; Round 2 makes it observable.

### Round 2 Pass / Fail

Single-Round Gate: **needs_fix**.

- 1 new Major (M-4) `pending`.
- 0 Blocker.
- 3 Round 1 Majors (M-1, M-2, M-3) `fixed` — these no longer block.
- Round 1 Minors (m-1, m-2, m-3) remain `pending` per Round 1 disposition; not re-evaluated in Round 2.

Recommended next round-trip: a single-line edit to qa-design.md TC-018 Pass criterion (option 1 in M-4 detail) is sufficient to unblock SC-6. No implementation-side change needed for M-4.

## Round 3 (2026-05-04)

Scope: re-verify M-4 only against commit 18187bf (qa-design.md TC-018 Pass criterion amendment to suppress new Tier-3 filename false positives). Out of scope: M-1, M-2, M-3 (already `fixed` in Round 2 — not re-checked); m-1, m-2, m-3 (Round 1 minors, carried `pending` unchanged).

### Verification per finding

- **M-4 (TC-018 ts-prefix Tier-3 filename false positives) — fixed.** The Pass criterion in qa-design.md TC-018 (line 78) now reads, at the tail of the grep pipeline:

  ```
  | grep -v '<!--' | grep -v 'github\.com/moonbitlang/moonbit-docs' | grep -v -E '/ts-(effect-(layer|runtime|hono)|totto2727-fp)\.md'
  ```

  The new third stage (option (a) from M-4 detail) excludes the four legitimate Tier-3 filename patterns (`ts-effect-layer.md`, `ts-effect-runtime.md`, `ts-effect-hono.md`, `ts-totto2727-fp.md`). Empirical re-execution of the full TC-018 pipeline against the current tree:

  ```
  $ <full TC-018 grep recipe with all three exclusion stages>
  $ echo $?  # → 1 (grep no-match, success)
  $ wc -l    # → 0
  ```

  The 9 residual matches reported in Round 2 (4 references inside `coding/references/ts-skill.md` L7-L10, 3 cross-references in the renamed Tier-3 detail files themselves L3, 2 README/CLAUDE references in `js/package/fp/`) are now suppressed exactly as predicted. SC-6 is observably satisfiable.

  Spot-check: the exclusion regex is anchored to the `/ts-...md` filename suffix, so it does not over-suppress legitimate leaks. Specifically:
  - It does not match `effect-layer` outside a filename context (e.g. a hypothetical leftover `name: effect-layer` frontmatter or `.agents/skills/effect-layer/` path would still surface).
  - It does not match the bare directory name `effect-layer/` (no `ts-` prefix), so genuine old-skill paths remain detectable.
  - It does not interact with the upstream-URL filter (`github\.com/moonbitlang/moonbit-docs`) because the `/ts-...` filename suffix never co-occurs with that URL substring.

### New findings discovered during Round 3

None. The single-purpose edit in 18187bf does not introduce any new TC, regex flavor, or scope change beyond the documented filename exclusion; no follow-on false-positive cluster is observable.

### Round 3 Pass / Fail

Single-Round Gate: **approved**.

- 0 Blocker.
- 0 Major. (M-4 is now `fixed`; M-1, M-2, M-3 already `fixed` in Round 2.)
- 3 Minor (m-1, m-2, m-3) remain `pending` per Round 1 disposition. Per Step 7 gate policy, Minors do not block approval; they are tracked for retrospective / future tidy-up.

Final Gate flips to `approved`. SC-6 is now empirically demonstrable via the post-18187bf TC-018 recipe; no additional Step 6 round-trip is required from a test-quality perspective.
