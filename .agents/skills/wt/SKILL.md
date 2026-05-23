---
name: wt
description: List git worktrees with their open / merged / missing PR status and remove the ones whose PRs are merged or never opened. Use when reviewing or pruning short-lived worktrees created during multi-task development, especially after PRs have landed.
allowed-tools: Bash(wt:*)
---

# `wt` — Git worktree manager with PR awareness

Lists and cleans up `git worktree`s, cross-referenced against GitHub PR state via `gh`. Built for workflows that spin up a worktree per task or per agent and need an easy way to see which are still alive.

## Commands

```bash
wt ls            [<dir>]              # list worktrees + PR state
wt cleanup       [<dir>] [--dry-run]  # remove worktrees with merged or missing PRs
```

`<dir>` (optional) — base directory to look under. Defaults to the parent directory of all worktrees configured for the current repo.
`--dry-run, -n` — print what would be removed without touching the filesystem or git.

## Removal rules

For each worktree's branch, `wt` queries `gh` for PR state **and** checks the local git status (`pushed` / `committed` / dirty). Removal happens only when:

| PR state   | Git status   | `cleanup` removes?           |
| ---------- | ------------ | ---------------------------- |
| **merged** | any          | ✓ (merged)                   |
| **closed** | `pushed`     | ✓ (closed, pushed)           |
| **none**   | `pushed`     | ✓ (no PR, pushed)            |
| **open**   | any          | ✗                            |
| anything   | not `pushed` | ✗ (preserves un-pushed work) |

The main worktree and any worktree without a branch (detached HEAD) are never touched.

## Typical workflows

```bash
# See where every worktree stands before cleanup
wt ls

# Preview what cleanup would delete
wt cleanup --dry-run

# Actually delete merged + PR-less worktrees
wt cleanup
```

## Prerequisites

- `git` 2.5+ (worktree support)
- `gh` CLI authenticated against the repo's GitHub host (`gh auth status`)
- Run inside any worktree of the repo whose worktrees you want to manage

## Notes

- Removal goes through `git worktree remove` (no `--force`); local uncommitted changes block removal — fix or commit first.
- Branch refs themselves are not deleted; only worktree directories. Use `git branch -d` afterward if you also want the branch gone.
