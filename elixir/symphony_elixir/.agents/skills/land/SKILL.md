---
name: land
description: Land a PR by monitoring conflicts, resolving failures, waiting for checks, and squash-merging when green; use when asked to land, merge, or shepherd a PR to completion.
---

<!--
このファイルは元のApache 2.0ライセンスのコードから変更されています
変更日: 2026-07-01
変更者: totto2727
変更内容: project-local OpenCode workflow 用の land skill として追加
-->

# Land

## Goals

- Ensure the PR is conflict-free with main.
- Keep CI green and fix failures when they occur.
- Squash-merge the PR once checks pass and review feedback is addressed.
- Do not yield to the user until the PR is merged unless blocked.
- Do not delete the remote branch manually when the repository auto-deletes merged head branches.

## Preconditions

- `gh` CLI is authenticated.
- You are on the PR branch with a clean working tree.
- The PR is approved or the tracker state explicitly indicates merge handling.

## Steps

1. Locate the PR for the current branch with `gh pr view`.
2. Confirm local checks required by the repository have passed before any push.
3. If the working tree has uncommitted changes, commit and push them before proceeding.
4. Check mergeability and conflicts against main.
5. If conflicts exist, update from `origin/main`, resolve conflicts, validate, commit, and push.
6. Review all human and bot PR comments; address required fixes or reply with a justified pushback.
7. Watch CI checks until complete.
8. If checks fail, inspect logs, fix the issue, commit, push, and restart the check loop.
9. When all checks are green and feedback is resolved, squash-merge using the PR title/body for the merge subject/body.

## Required Guardrails

- Do not call `gh pr merge` directly until mergeability, CI, and review feedback have been checked.
- Do not merge while unresolved review comments remain.
- If feedback conflicts with the user's stated intent or task context, reply with the rationale before changing code.
- If ambiguity blocks progress, ask for clarification in the PR or tracker thread and wait.

## Useful Commands

```bash
branch=$(git branch --show-current)
pr_number=$(gh pr view --json number -q .number)
pr_title=$(gh pr view --json title -q .title)
pr_body=$(gh pr view --json body -q .body)

gh pr view --json mergeable,mergeStateStatus
gh pr checks --watch
gh pr merge --squash --subject "$pr_title" --body "$pr_body"
```
