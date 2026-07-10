---
name: push
description: Push the current branch to origin and create or update the corresponding GitHub pull request.
---

<!--
This file adapts the Apache-2.0 licensed OpenAI Symphony push skill for this
repository's OpenCode workflow.
Original source: https://github.com/openai/symphony/tree/main/.codex/skills/push
-->

# Push

Use this skill when asked to push, publish updates, or create/update a pull request.

## Prerequisites

- `gh` CLI is installed and authenticated for this repository.
- Required local validation for the change has passed before each push attempt.

## Goals

- Push the current branch to `origin` safely.
- Create a PR if none exists for the branch, otherwise update the existing PR.
- Keep PR title, body, labels, and Linear linkage aligned with the current branch scope.
- Do not hide auth, permission, or workflow restriction failures behind remote rewrites.

## Related Skills

- `pull`: use when push is rejected because the branch is stale or needs a merge-based sync.
- `commit`: use before pushing when the working tree contains intended changes.

## Steps

1. Identify the current branch and confirm `git status` is clean.
2. Run validation appropriate to the change. Prefer the narrowest `vp run ...` task that proves the scope, then widen when required.
3. Push the branch to `origin` with upstream tracking if needed.
4. If push is rejected because the remote moved:
   - Run the `pull` skill.
   - Resolve conflicts, validate again, and retry the normal push.
   - Use `--force-with-lease` only when history was intentionally rewritten and the user or workflow explicitly permits it.
5. If push fails because of auth, permissions, or repository rules, surface the exact error and do not rewrite remotes as a workaround.
6. Ensure a PR exists for the branch:
   - Create one when missing.
   - Update title/body when an open PR exists.
   - Do not reuse a branch tied to a closed or merged PR for a new attempt.
7. Write or refresh the PR body using `.github/pull_request_template.md` when present.
8. Ensure required labels and Linear issue links/attachments are present.
9. Run the PR feedback sweep required by `WORKFLOW.md` before handoff.
10. Return the PR URL and validation evidence.

## Useful Commands

```sh
branch=$(git branch --show-current)
git status --short --branch
git push -u origin HEAD
gh pr view --json state,url,title,body,labels
gh pr create --title "<clear PR title>"
gh pr edit --title "<clear PR title>" --body-file /path/to/pr_body.md
```

## Notes

- Do not use `--force`; prefer `--force-with-lease` only for explicit history-rewrite workflows.
- Reconsider the PR title and body after every meaningful branch update.
- Before moving a Linear issue to review, confirm PR checks are green and actionable comments are resolved.
