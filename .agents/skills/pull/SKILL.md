---
name: pull
description: Merge the latest base branch into the current branch and resolve conflicts without rebasing.
---

<!--
This file adapts the Apache-2.0 licensed OpenAI Symphony pull skill for this
repository's OpenCode workflow.
Original source: https://github.com/openai/symphony/tree/main/.codex/skills/pull
-->

# Pull

Use this skill when a workflow needs to sync a feature branch with its base branch, handle non-fast-forward push rejection, or resolve merge conflicts.

## Base Branch

- If the workflow or issue context names a `Dependency base branch`, sync against that branch.
- Otherwise sync against latest `origin/main`.
- Use a merge-based update. Do not rebase unless explicitly instructed.

## Workflow

1. Verify the working tree is clean or commit/stash intended local changes first.
2. Enable rerere locally:
   - `git config rerere.enabled true`
   - `git config rerere.autoupdate true`
3. Confirm `origin` exists and the current branch is the branch to receive the merge.
4. Fetch latest refs with `git fetch origin`.
5. Sync the remote feature branch first when it exists:
   - `git pull --ff-only origin $(git branch --show-current)`
6. Merge the base branch with clearer conflict context:
   - `git -c merge.conflictstyle=zdiff3 merge origin/main`
   - Replace `origin/main` with the configured dependency base branch when present.
7. If conflicts appear, resolve them semantically, stage resolved files, and continue the merge.
8. Run repository validation appropriate for the changed files.
9. Record sync evidence in the workpad or handoff note:
   - merge source
   - result (`clean` or `conflicts resolved`)
   - resulting `HEAD` short SHA

## Conflict Resolution Guidance

- Inspect context before editing:
  - `git status` for conflicted files.
  - `git diff` or `git diff --merge` for conflict hunks.
  - `git diff :1:path :2:path` and `git diff :1:path :3:path` when base/ours/theirs intent is unclear.
- With `merge.conflictstyle=zdiff3`, conflict markers include ours, base, and theirs. Decide the intended final behavior before editing.
- Preserve both sides' intent when possible, especially for workflow or validation rules.
- Avoid `ours` or `theirs` shortcuts unless one side should fully win.
- Resolve source and handwritten files before generated files, then regenerate outputs when applicable.
- After resolving, run `git diff --check` to catch conflict markers and whitespace errors.

## When To Ask

Ask only when the correct resolution depends on product intent or an external contract that cannot be inferred locally. Otherwise make the safest reversible decision, document the rationale, validate, and continue.
