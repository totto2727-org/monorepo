---
confirmed: true
---

# ADR: c-plugin — Recursive Sync Direction and .gitignore Management

## Context

Two behaviors were underspecified in the original ADR (`2026-04-06-c-plugin-cli-tool.md`):

1. The `-r` flag for `skill sync` and `skill update` was described as "recursive search" without specifying direction (upward vs. downward).
2. The `.gitignore` management strategy said "auto-append if not present" but did not specify content or update policy.

## Decision

### 1. `-r` flag: downward recursive search

The `-r` flag searches **downward** from the current working directory, collecting all `.agents/` directories that contain a `skills-lock.json`. `sync` or `update` is run for each found directory.

**Rationale**: The primary use case is running `c-plugin skill sync -r` from a monorepo root to update all sub-projects at once. Upward search would only ever find one `.agents/` and provides no value over the default behavior.

**Skipped directories**: `.agents/`, `.git/`, `node_modules/`

Implementation: `service/discover.ts` — `collectAgentsDirs(startDir)`

### 2. `.gitignore` management: full overwrite

The `.gitignore` is written at `agentsDir/.gitignore` (same level as `skills-lock.json`) and **fully overwritten** on every sync with the following static content:

```
.cache/
skills/
.gitignore
```

- `.cache/` — git clone cache, must not be tracked
- `skills/` — symlink directory, must not be tracked
- `.gitignore` — the file itself, to keep `.agents/` minimal in git history

**Rationale**: Overwriting is simpler than appending and avoids stale entries. The content is static and predictable. Excluding `.gitignore` itself keeps `.agents/` clean (only `skills-lock.json` is tracked).

The `.gitignore` is written after every successful sync via `service/gitignore.ts` — `write(agentsDir)`.

## Impact

- `service/discover.ts` — new, implements downward recursive search
- `service/gitignore.ts` — new, writes `.gitignore` on each sync
- `service/update.ts` — new, extracted from `cli/skill/update.ts` for reuse in recursive mode
- `cli/skill/sync.ts` / `cli/skill/update.ts` — updated to loop over collected dirs when `-r`
- Original ADR sections 8 (subcommand details for `-r`) and 10 (.gitignore) are superseded by this ADR
