---
name: commit
description: Create a clean git commit from current changes using OpenCode session context, repository conventions, and local validation evidence.
---

<!--
This file adapts the Apache-2.0 licensed OpenAI Symphony commit skill for this
repository's OpenCode workflow.
Original source: https://github.com/openai/symphony/tree/main/.codex/skills/commit
-->

# Commit

Use this skill when asked to commit, prepare a commit message, or finalize staged work.

## Goals

- Produce one logical commit that reflects the actual repository changes.
- Follow this repository's git workflow and commit-message conventions.
- Include enough message detail for reviewers to understand what changed, why it changed, and how it was validated.

## Inputs

- OpenCode session context for intent and rationale.
- `git status`, `git diff`, and `git diff --staged` for actual changes.
- Repository instructions in `AGENTS.md`, package-local `AGENTS.md`, and recent commit history.

## Steps

1. Inspect recent commit style with `git log --oneline -10` before choosing a message.
2. Inspect the working tree and staged changes with `git status`, `git diff`, and `git diff --staged`.
3. Stage only intended files. Do not stage unrelated user or merge artifacts.
4. Sanity-check newly added files. If build outputs, logs, temp files, secrets, or unrelated files appear, stop and fix the index before committing.
5. Run the validation required for the change before committing, or record a precise blocker if validation cannot run.
6. Choose a Conventional Commits subject such as `feat(scope): ...`, `fix(scope): ...`, or `docs(scope): ...`.
7. Keep the subject imperative, at most 72 characters, and without a trailing period.
8. Write a body that records:
   - Summary of key changes.
   - Rationale and trade-offs.
   - Tests or validation run.
9. Create the message with a temp file and commit with `git commit -F <file>` so newlines are literal.
10. Do not amend an existing commit unless the user explicitly requested an amend.

## Output

- A single git commit whose staged diff, message, and validation evidence match.

## Template

```text
<type>(<scope>): <short summary>

Summary:
- <what changed>

Rationale:
- <why it changed>

Tests:
- <command and result>
```
