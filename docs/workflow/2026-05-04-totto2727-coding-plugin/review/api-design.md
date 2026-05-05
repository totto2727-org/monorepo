# Review Report: API Design

- **Cycle:** 2026-05-04-totto2727-coding-plugin
- **Aspect:** api-design — backward compatibility, contract clarity, error model, naming consistency, cross-manifest parity, and external/internal reference policy hygiene for the new `totto2727-coding` plugin
- **First reviewed:** 2026-05-04
- **Last updated:** 2026-05-04
- **Final Gate:** approved
- **Round count:** 2

## Findings list

| ID  | Severity | Finding                                                                                                                                                                                                                                                                                            | State               | First Round | Resolution commit | Notes                                                                                                                                                                                                                |
| --- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ----------- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| M-1 | Major    | T28 placeholder rewrite missed `moonbit-bestpractice` (and adjacent `effect-*` glob in step-qa-design); 4 stale references remained in `plugins/dev-workflow/`, breaking the cross-plugin contract that dev-workflow must reference relocated skills via the new `totto2727-coding` namespace.     | fixed               | 1           | 309a84c           | T28 grep target was widened in Round 2 to include `moonbit-bestpractice`, `effect-*`, and `totto2727-fp`; re-verified 0 hits on Round 2 (see [detail](#m-1-detail-leftover-old-skill-names-in-dev-workflow-plugin)). |
| m-1 | Minor    | `plugins/totto2727-coding/.script/generate-docs-moonbit.ts` still embedded the old script name `process-moonbit-docs.ts` at L8 (header comment) and L16 (Usage error message), so users hitting the error would get a non-existent command path.                                                   | fixed               | 1           | 70e19f7           | Both lines rewritten to the new script name. Re-verified `grep "process-moonbit-docs" generate-docs-moonbit.ts` returns 0 hits.                                                                                      |
| m-2 | Minor    | 3 of 4 Tier-2 index files (`coding/references/mbt-skill.md`, `test/references/ts-skill.md`, `test/references/mbt-skill.md`) mixed Japanese and English, breaking the documentation contract "Markdown Output: always English" and diverging from the pure-English `coding/references/ts-skill.md`. | fixed               | 1           | 1cbdd8f           | All 3 files now English-only and structurally aligned with `coding/references/ts-skill.md` (sections: In-plugin detail files / External skill references / Related references).                                      |
| i-1 | Info     | The `docs-moonbit` skill `description` is shorter than peer skills, making auto-discovery rank weaker for ambiguous queries.                                                                                                                                                                       | accepted-as-is      | 1           | -                 | User-approved 2026-05-04 as Retrospective carryover; not blocking the cycle. Track as a follow-up item in `docs/retrospective/2026-05-04-totto2727-coding-plugin.md`.                                                |
| i-2 | Info     | Slash command placement under `plugins/totto2727-coding/.claude-plugin/commands/` (vs sibling skills) is inconsistent with the directory convention used by other plugins.                                                                                                                         | accepted-as-is      | 1           | -                 | User-approved 2026-05-04 as Retrospective carryover; out-of-scope for this cycle's stated deliverable.                                                                                                               |
| i-3 | Info     | `coding/SKILL.md` L150-153 hard-codes a path-based reference to the Tier-2 index files instead of the skill-name-based external-reference policy.                                                                                                                                                  | accepted-as-is      | 1           | -                 | User-approved 2026-05-04 as Retrospective carryover; intentional for in-plugin index linkage. Re-evaluate if/when the indices move out of `references/`.                                                             |
| i-4 | Info     | Cross-manifest parity check: `.claude-plugin/plugin.json`, `.cursor-plugin/plugin.json`, `.codex-plugin/plugin.json` carry identical `name` / `version` / `description` / `author` fields after T30 sync.                                                                                          | (consistency check) | 1           | -                 | No drift detected in Round 1 or Round 2. T30 commit `ab64491` established lockstep; no post-T30 manifest mutations occurred.                                                                                         |
| i-5 | Info     | Marketplace registration parity: `.claude-plugin/marketplace.json` registers `totto2727-coding` with the correct relative source `./plugins/totto2727-coding`, and the dropped `moonbit` / `components-build` entries are absent.                                                                  | (consistency check) | 1           | -                 | Verified via T2 commit `f937572`; no further drift.                                                                                                                                                                  |

## Detailed sections

### M-1 detail: leftover old skill names in dev-workflow plugin

**Round 1 evidence (4 hits in `plugins/dev-workflow/`):**

- `plugins/dev-workflow/agents/qa-analyst.md:46` — referenced `moonbit-bestpractice` directly instead of `totto2727-coding`'s relocated index.
- `plugins/dev-workflow/skills/specialist-implementer/SKILL.md:52` — same.
- `plugins/dev-workflow/skills/specialist-qa-analyst/SKILL.md:60` — same.
- `plugins/dev-workflow/skills/step-qa-design/SKILL.md:29` — referenced `effect-*` glob (legacy) plus `moonbit-bestpractice`.

**API-design impact:** dev-workflow's specialist instructions form an _external API_ relative to the `totto2727-coding` plugin's renamed/relocated skill surface. Stale references break the cross-plugin contract: any specialist following these instructions would attempt to load skills under names that no longer resolve, silently degrading skill auto-discovery for downstream cycles.

**Root cause:** T28 verification grep target was scoped to a narrow set of placeholder strings that did not include `moonbit-bestpractice`, `effect-layer`, `effect-runtime`, `effect-hono`, or `totto2727-fp`. Round 2's T28-r2 widened the grep to the full union and rewrote the 4 sites.

**Round 2 verification command:**

```sh
grep -rn "moonbit-bestpractice\|moonbit-docs\|components-build-docs\|effect-layer\|effect-runtime\|effect-hono\|totto2727-fp" plugins/dev-workflow/ --include="*.md"
```

Result: 0 hits (PASS).

## Round history metadata

| Round | Date       | Reviewer instance              | Round-only Gate |
| ----- | ---------- | ------------------------------ | --------------- |
| 1     | 2026-05-04 | reviewer (api-design, initial) | needs_fix       |
| 2     | 2026-05-04 | reviewer (api-design, re-run)  | approved        |

Final Gate: `approved`. 0 Major / Blocker findings open, 3 `accepted-as-is` (i-1, i-2, i-3) carried to Retrospective.

<!--
Authoring guide: share-artifacts/references/review-report.md
Detailed state-label semantics and per-aspect emphasis are delegated to specialist-reviewer/SKILL.md.
-->
