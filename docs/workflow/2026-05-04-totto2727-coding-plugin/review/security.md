# Review Report: Security

- **Cycle:** 2026-05-04-totto2727-coding-plugin
- **Aspect:** security
- **First reviewed:** 2026-05-04
- **Round count:** 1
- **Final Gate:** **approved**

## Round 1 (2026-05-04)

### Verdict

**PASS** (no Blocker / no Major / 2 Minor accepted-as-is)

### Scope context

This cycle is documentation/plugin restructuring (rename + move + relative-path fix). The only executable surface introduced or touched is two pre-existing Deno scripts that were renamed and lightly edited. No runtime API, no new network endpoints, no new secrets handling. Per `design.md` operational considerations: "No secrets, no network calls at runtime. The two Deno scripts fetch from public URLs and write to repo-local paths only." Confirmed empirically below.

### Findings list

| ID  | Severity | Finding                                                                                                                          | State                           | Round | Notes                                                                                                                                                                                                                             |
| --- | -------- | -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- | ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| m-1 | Minor    | `generate-docs-moonbit.ts` L8/L16 had stale comment / Usage error message referring to old script name `process-moonbit-docs.ts` | fixed (commit `70e19f7`, T5-r2) | 1     | Cosmetic but listed for completeness; resolved by Round 2 readability M-1 / api-design m-1 fix                                                                                                                                    |
| m-2 | Minor    | `generate-docs-moonbit.ts` accepts arbitrary URLs from `Deno.args` and `fetch`es them with no host allow-list                    | accepted-as-is                  | 1     | Pre-existing posture; documented invocation always uses `docs.moonbitlang.com`. Out of scope for this cycle. Optional hardening for future cycle: add `new URL(url).hostname === 'docs.moonbitlang.com'` check at fetch loop top. |

### Detailed sections

#### 1. Generation script safety

- **Network surface (fetch).**
  - `generate-docs-moonbit.ts:62` — `fetch(url)` where `url` comes from `Deno.args` (CLI). The script ships a slash command (`update-docs-moonbit.md`) that hard-codes the resolution flow against `https://docs.moonbitlang.com/en/latest/...`, so under the documented invocation path the URLs are always `docs.moonbitlang.com`. **No URL allow-list is enforced in code, but the privilege model already constrains it**: `--allow-net` is required and the slash command is the only documented entry. An advanced user could invoke the script with arbitrary URLs, but doing so requires explicit `--allow-net` consent at the Deno level and is no different from running `curl` from the same shell.
  - `generate-docs-components-build.ts:9-10, 22, 89-91` — `SITEMAP_URL` and `BASE_URL` are **hardcoded constants** (`https://www.components.build/...`). Slugs extracted from the sitemap are interpolated into `${BASE_URL}/llms.mdx/${slug}` (L89). Because `slug` comes from a remote sitemap, an attacker controlling components.build could steer the script to fetch arbitrary `https://www.components.build/llms.mdx/<anything>` — i.e. **same-origin only**. No SSRF / arbitrary-host vector. Acceptable.
- **Untrusted-input parsing.** `parseSections` (moonbit) and `locRegex` / `parseFrontmatter` (components-build) operate on remote content with regex; output is **only written to disk** and never `eval`'d, executed, or templated into shell. No injection risk.
- **Filesystem writes / path traversal.**
  - `outputDir` is computed deterministically as `join(scriptDir, '..', 'skills', 'docs-{moonbit,components-build}')`. **No user-controlled path component** flows into write paths.
  - `splitByHeading` builds `fname` from `toKebab(headings[i].title)` (moonbit script L101-102). `toKebab` strips everything except `[a-z0-9 -]` and converts spaces to `-`, so a malicious heading like `## ../../etc/passwd` would be normalized to `etcpasswd` (no slashes, no `..`). **Not vulnerable to path traversal.**
- **`import.meta.dirname` null guard.** Both scripts now early-throw with a descriptive message. Per design A6 this satisfies SC-7. Security relevance is incidental (avoids silent fallback that could in theory write under an attacker-controlled CWD if the script were invoked from an unusual location); the chosen "early throw" is the safer of the design alternatives.
- **Conclusion:** Script attack surface is unchanged by this cycle. Renaming + null guard add no new vulnerabilities.

#### 2. Plugin manifest / settings.json permission posture

- `.claude/settings.json` `enabledPlugins` adds `"totto2727-coding@totto2727": true` and removes the two old entries. The new plugin is **owned by the same author / marketplace (`totto2727`)** as the old plugins; `extraKnownMarketplaces.totto2727` already trusts the entire repo as a directory marketplace. **Net privilege delta: zero** — content from the same trust boundary is consolidated, not expanded.
- `.claude-plugin/plugin.json` (the new manifest) declares only `name / description / version / author`. No `permissions:` block, no MCP server registration, no hooks. Plugin is documentation-only.

#### 3. W5 deletion blast radius

Verified each W5 deletion commit's file list. All deletions scoped correctly to the targeted directory:

| Commit    | Deletion                           | Verdict                |
| --------- | ---------------------------------- | ---------------------- |
| `8719621` | `plugins/moonbit/` (34 files)      | All within target tree |
| `2e9229a` | `plugins/components-build/` (6)    | All within target tree |
| `41520f3` | `.agents/skills/effect-layer/` (1) | Scoped correctly       |
| `7550a55` | `.agents/skills/effect-runtime/`   | Scoped correctly       |
| `800d85d` | `.agents/skills/effect-hono/`      | Scoped correctly       |
| `ff446c7` | `.agents/skills/totto2727-fp/`     | Scoped correctly       |

No `.git/`, `.env`, settings, or unrelated files touched.

#### 4. Secrets / PII scan in migrated content

Ran a regex scan for common secret patterns (`api[_-]?key`, `password`, `token`, `bearer`, `aws_`, `private[_-]?key`, `BEGIN [A-Z]+ PRIVATE KEY`, `sk_live_`, `ghp_`, `gho_`) across all migrated files. **No secrets found.** Author email `kaihatu.totto2727@gmail.com` in `plugin.json` is the public maintainer contact and is intentional per `design.md`.

#### 5. Slash command safety (`update-docs-*.md`)

- `update-docs-moonbit.md` runs `deno run --allow-net --allow-read --allow-write .script/generate-docs-moonbit.ts ...` with URLs sourced from a documented WebFetch step against `docs.moonbitlang.com`. Attack surface = same as any documentation-pipeline tool that follows a documented external link.
- `update-docs-components-build.md` runs `deno run .script/generate-docs-components-build.ts` with **no arguments**. URLs entirely hard-coded. Zero injection surface.
- Both rely on **explicit `--allow-net --allow-read --allow-write` permissions**; no `--allow-run` / `--allow-env` / `--allow-all`. **Least-privilege posture preserved.**

#### 6. Manifest sync (`c-plugin dev marketplace sync`) trust boundary

- T30 (commit `ab64491`) reads `.claude-plugin/marketplace.json` (in-repo edit base) and emits derivatives. All sources and destinations are repo-local; no network involved. The cycle only **invokes** sync; it does not modify the sync implementation. No new path-traversal vector introduced.

### Pass criterion

This review **passes** because:

- No Blocker
- No Major
- 1 Minor (m-1) was resolved in Round 2 by another reviewer's Major fix; 1 Minor (m-2) is a pre-existing posture observation acceptable for this cycle and recommended as future hardening only

The cycle's security profile matches the explicit design statement: a documentation-only restructure with no new attack surface. **Limited security surface — restructuring only, no new code paths or attack surface introduced.**

### Round history metadata

| Round | Date       | Reviewer instance   | Round-only Gate | Notes                                                                                  |
| ----- | ---------- | ------------------- | --------------- | -------------------------------------------------------------------------------------- |
| 1     | 2026-05-04 | reviewer (security) | **approved**    | No Round 2 needed — original review already PASS. m-1 cross-resolved by Round 2 fixes. |
