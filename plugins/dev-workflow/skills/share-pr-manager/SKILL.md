---
name: pr-manager
description: >
  [Main-only write operations / Specialist read operations] A utility skill that consolidates
  GitHub Pull Request operations: Draft creation, summary updates, Draft -> Ready transitions,
  and state reads. It mandates idempotency guards (pre-checks via `gh pr list --head` and
  `gh pr view --json isDraft`), and uses `--body-file` for transmission to prevent
  shell quoting accidents. CI monitoring is delegated to `share-ci-monitoring`, and the
  template body itself is delegated to `share-artifacts/{templates,references}/pr-body.md`,
  making this a pure PR operation layer.
  Trigger conditions: Draft PR creation at cycle initialization, PR summary updates upon each
  step completion, Ready transition after Step 9 completion, situations where a Specialist needs
  to read PR state.
  Referenced via "create Draft PR", "update PR summary", "gh pr ready", "Ready transition", "pr-manager".
  Do NOT use for: workflow procedure definitions (dev-workflow), PR description body content
  specifications (`share-artifacts/references/pr-body.md`), CI monitoring / retry / Blocker
  handling (`share-ci-monitoring`), GitHub Issue / Discussion management (out of scope for
  this workflow).
allowed-tools: Bash, Read, Glob, Grep
---

# PR Manager — A Skill Consolidating GitHub Pull Request Operations

Use case category: **Workflow Automation** (consolidates PR lifecycle operations into a single place, ensuring idempotency and permission boundaries)
Design pattern: **Domain Intelligence** (consolidates domain knowledge of gh CLI's PR-related commands and the idempotency requirements specific to this workflow)

In a dev-workflow cycle, each cycle has one GitHub Pull Request that is **created as Draft -> updated on each step completion -> transitioned to Ready after Step 9 completion**. This skill consolidates **the procedures for these PR operations (write side)** and **PR state reads (read side)**, responding to invocations from related skills (`dev-workflow` / `specialist-common` / `specialist-validator` / `share-artifacts`).

## Basic Policy

- **Write operations are Main-only**: `gh pr create` / `gh pr edit` / `gh pr ready` / `gh pr close` / `gh pr reopen`, etc., are **executed solely by Main**. Specialists may use only read operations (consistent with `specialist-common` §7)
- **Idempotency guards are mandatory**: For state-changing operations such as "do not double-create an already created PR" or "do not re-Ready an already Ready PR", implement them as a two-stage process: **pre-read to verify current state -> only write if necessary**
- **Send via `--body-file`**: Send PR descriptions in the form `gh pr edit --body-file <path>` rather than HEREDOC. This permanently avoids accidents where quotes, backticks, etc. inside Markdown get corrupted by shell quoting
- **Templates live in share-artifacts**: The body of the PR description (how each section is filled in) is not defined in this skill; it is delegated to `share-artifacts/{templates,references}/pr-body.md`
- **CI lives in ci-monitoring**: Confirmation, watching, retrying, and Blocker handling of PR CI status are not handled by this skill; they are delegated to the `share-ci-monitoring` skill. This skill only reads "PR meta information (number, isDraft, body, state, mergedAt, etc.)"
- **Single-Source-of-Progress consistency**: The PR description is a **view** derived from `progress.yaml` / `TODO.md`; the PR description must not become the source of truth

## Prerequisites

- This workflow assumes the use of the `gh` CLI on GitHub Actions (consistent with this repository's operations)
- 1 cycle = 1 PR (one open PR is associated with the current cycle branch)
- Branch naming follows the `feat/<id>` pattern (per the project-specific `git-workflow` skill)
- The current branch name is assumed to be already obtained via the `BRANCH` environment variable or `git rev-parse --abbrev-ref HEAD`

## 1. Draft PR Initialization (At Cycle Start, Idempotent)

Simultaneously with the cycle initialization commit `docs(dev-workflow/<identifier>): initialize cycle`, create one corresponding **Draft PR**. The Draft PR is created only once at cycle start, executed idempotently by Main immediately after Step 1 completion (reusing an existing PR if any).

The PR description is generated as a volatile file at `$TMPDIR/dev-workflow/<identifier>-pr-body.md` and sent via `gh pr create --draft --body-file` (template: `share-artifacts/templates/pr-body.md`).

```bash
# Idempotency guard: reuse existing open PR if one exists
existing_pr=$(gh pr list --head "$BRANCH" --state open --json number,isDraft --jq '.[0]')
if [ -z "$existing_pr" ] || [ "$existing_pr" = "null" ]; then
  # Not yet created -> create new Draft PR
  gh pr create \
    --draft \
    --base main \
    --head "$BRANCH" \
    --title "feat(dev-workflow/<identifier>): <one-line summary>" \
    --body-file "$TMPDIR/dev-workflow/<identifier>-pr-body.md"
else
  # Reuse existing PR (cases such as Step 1 re-execution or manually pre-created PR)
  echo "Reusing existing PR: $existing_pr"
fi
```

**Note:** Even if an existing PR has `isDraft: false` (= already Ready), this skill does **not revert** it to Draft (a destructive operation). For cases where the cycle resumes and Drafting is needed, Main must explicitly invoke `gh pr edit --draft`, or confirm via the In-Progress user query format.

## 2. PR Summary Update (At Each Step Completion + As Needed)

The PR summary (PR description) **must be updated immediately after each step's completion commit** (9 times). Furthermore, even mid-step, it may be updated **as needed** when content changes (e.g., adding a Research Note, reflecting status when a Blocker occurs).

Update procedure:

1. Main regenerates `$TMPDIR/dev-workflow/<identifier>-pr-body.md` according to the template (`share-artifacts/templates/pr-body.md`) (reflecting cumulative state)
2. Send via `gh pr edit <num> --body-file <path>`

```bash
# After Main regenerates $TMPDIR/dev-workflow/<id>-pr-body.md from the template
PR_NUMBER=$(gh pr list --head "$BRANCH" --state open --json number --jq '.[0].number')
gh pr edit "$PR_NUMBER" --body-file "$TMPDIR/dev-workflow/<identifier>-pr-body.md"
```

**Reason for mandating `--body-file`:** The HEREDOC-based `--body "..."` carries an ongoing risk that `` ` `` / `"` / `$` / `\`, etc. inside Markdown get corrupted by shell quoting (this has actually occurred in past manually-crafted PRs). With `--body-file`, the file content is sent verbatim.

**How to fill each section:** See "Section specifications" in `share-artifacts/references/pr-body.md`. For the CI status section, see `share-ci-monitoring` §5.

## 3. Draft -> Ready Transition (After Step 9 Completion, Idempotent)

After confirming that the CI for the Step 9 (Retrospective) completion commit has passed (the double-check in `share-ci-monitoring` §3), Main transitions the cycle PR **from Draft to Ready**. The Ready transition is one of the final actions of cycle completion.

```bash
PR_NUMBER=$(gh pr list --head "$BRANCH" --state open --json number --jq '.[0].number')
IS_DRAFT=$(gh pr view "$PR_NUMBER" --json isDraft --jq '.isDraft')

if [ "$IS_DRAFT" = "true" ]; then
  gh pr ready "$PR_NUMBER"
  echo "PR #$PR_NUMBER: Draft -> Ready"
elif [ "$IS_DRAFT" = "false" ]; then
  echo "PR #$PR_NUMBER: already Ready (no-op)"
else
  echo "Unexpected isDraft value: $IS_DRAFT" >&2
  exit 1
fi
```

**Reason for the idempotency guard:** The behavior of `gh pr ready` may depend on the CLI version and GitHub-side state, and re-execution against an already-Ready PR could be destructive (not explicitly stated in official documentation; see `docs/workflow/2026-05-03-pr-ci-integration/research/gh-cli.md` D-2). Mandating an `isDraft` pre-check at the design level prevents regressions due to CLI specification changes.

**Verifying the Ready transition:** Confirm that the output of `gh pr view --json isDraft` is `false` (a mechanical determination independent of any test framework). If the `readyForReviewAt` field is not in the field list of `gh pr view --json`, confirm that the `event: "ready_for_review"` event in `gh api repos/<owner>/<repo>/issues/<num>/timeline` occurs at or after the Step 9 commit time.

## 4. PR State Reads (Specialists May Also Use, Read Operations)

Read operations may be used by both Main and Specialists. Representative queries:

```bash
# Basic meta information (number / isDraft / state / mergedAt)
gh pr view <num> --json number,isDraft,state,mergedAt --jq '.'

# Get PR body (description) (used by validator for SC-2 etc. validation)
gh pr view <num> --json body --jq '.body'

# List of commits associated with PR (used by validator at SC-5 to confirm initialize cycle commit existence)
gh pr view <num> --json commits --jq '.commits[].messageHeadline'

# Search PR by branch / commit list (resolve cycle branch -> PR number)
gh pr list --head "$BRANCH" --state all --json number,isDraft,createdAt --jq '.[0]'

# PR timeline (retrieve description edit events, convert_to_draft, etc.)
gh api repos/<owner>/<repo>/issues/<num>/timeline --paginate \
  --jq '.[] | {event, created_at, actor: .actor.login}'

# created_at vs updated_at (observe whether description edits occurred. By spec, description edits do not appear in timeline)
gh api repos/<owner>/<repo>/issues/<num> --jq '{created: .created_at, updated: .updated_at}'
```

**Specialist usage scope:** The `validator` invokes this skill's read operations during dynamic validation of SC-5/6/8. The `reviewer` (holistic perspective) may also read for things like PR commit granularity confirmation. **However, `--jq` filtering and result evaluation must be completed on the Specialist side; this skill only provides observation primitives.**

## 5. Permission Boundaries (Main vs Specialist)

| Operation type      | Example command                                          | Main | Specialist |
| ------------------- | -------------------------------------------------------- | ---- | ---------- |
| Draft creation      | `gh pr create --draft`                                   | Yes  | No         |
| Summary update      | `gh pr edit <num> --body-file`                           | Yes  | No         |
| Ready transition    | `gh pr ready <num>`                                      | Yes  | No         |
| Draft revert        | `gh pr edit <num> --draft`                               | Yes\* | No        |
| close / reopen      | `gh pr close <num>` / `gh pr reopen <num>`               | Yes\* | No        |
| State read          | `gh pr view <num> --json ...` / `gh pr list --json ...`  | Yes  | Yes        |
| Timeline read       | `gh api .../timeline`                                    | Yes  | Yes        |

\* Draft revert / close / reopen are destructive or semi-destructive operations and are executed by Main only after user judgment (an In-Progress temporary report).

For details, this is consistent with `specialist-common` §7 "Permission Boundaries for PR / CI Operations (Common Across All Specialists)".

## 6. Template Integration (share-artifacts/pr-body.md)

The **structure and section specifications** of the PR description are not defined in this skill. See:

- **Template body**: `share-artifacts/templates/pr-body.md` (Main copies it to `$TMPDIR/dev-workflow/<id>-pr-body.md`)
- **Authoring guide**: `share-artifacts/references/pr-body.md` (how to fill each section, quality criteria, good / bad examples)
- **How to fill the CI status section**: `share-ci-monitoring` skill §5

Only the timing of updates is this skill's responsibility:

- Initial send: simultaneous with §1 Draft PR initialization (`gh pr create --body-file`)
- Subsequent: §2 immediately after each step completion commit + as needed (`gh pr edit --body-file`)

## 7. Related Skills / Delegation Targets

| Concern                                                          | Owning skill                                                | Relationship to this skill                  |
| ---------------------------------------------------------------- | ----------------------------------------------------------- | ------------------------------------------- |
| When to perform PR operations (timing / triggers)                | `dev-workflow` "## Cycle PR and CI Integration Protocol"    | dev-workflow invokes pr-manager             |
| How to perform PR operations (commands / idempotency)            | **`share-pr-manager`** (this skill)                         | -                                           |
| CI watch / double-check / retry / Blocker                        | `share-ci-monitoring`                                       | Parallel concern (not included in PR ops)   |
| PR description template / each section spec                      | `share-artifacts/{templates,references}/pr-body.md`         | Referenced from §2 / §6 of this skill       |
| Common Specialist permission boundaries                           | `specialist-common` §7                                      | Aligned with §5 of this skill               |
| Specialist-specific PR responsibilities (validator's SC use)      | `specialist-validator` etc.                                 | Invokes only §4 read operations of this skill |
| Project-specific Git/PR conventions (Conventional Commits)        | `git-workflow` (totto2727 project)                          | Follow §1 `--title` convention of this skill |

## What This Skill Does NOT Cover

- **PR description content (how to fill each section)** -> delegated to `share-artifacts/references/pr-body.md`
- **CI run confirmation / monitoring / retry / Blocker handling** -> delegated to `share-ci-monitoring` skill
- **When to perform PR operations (triggers per step)** -> delegated to `dev-workflow` "## Cycle PR and CI Integration Protocol"
- **GitHub Issue / Discussion / Project operations** -> out of scope for this workflow
- **PR synchronization across multiple repositories** -> out of scope for this workflow
- **Writing PR review comments** (`gh pr review` / `gh pr comment`) -> not handled in this cycle (to be considered in a future separate cycle, Retrospective extension point)
- **Merge operations** (`gh pr merge`) -> human reviewer responsibility, out of scope for this workflow
- **CI workflow definition modifications** (`.github/workflows/*.yaml`) -> domain of CI/CD pipeline design, out of scope for this workflow

## Triggering Test (Examples)

- "I just pushed the Step 1 completion commit and want to create a Draft PR" -> §1 (idempotency check -> `gh pr create --draft --body-file`)
- "I want to update the PR description right after the Step 5 completion commit" -> §2 (regenerate `$TMPDIR/<id>-pr-body.md` -> `gh pr edit --body-file`)
- "The CI for the Step 9 completion commit passed and I want to make the PR Ready" -> §3 (`isDraft` pre-check -> `gh pr ready`)
- "As a Validator, I want to confirm that the PR was created as Draft for SC-5" -> §4 read operations (`gh pr view --json isDraft,createdAt`)
- "I want to confirm in the timeline that the PR description was updated" -> §4 read operations (`gh api .../timeline`)
