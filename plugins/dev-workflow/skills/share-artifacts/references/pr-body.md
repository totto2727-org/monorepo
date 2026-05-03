# Reference: pr-body.md

A skeleton for generating the **description (body)** of a GitHub Draft / Ready PR. Template: `share-artifacts/templates/pr-body.md`.

## Purpose

Under the design that **persists the description of a cycle PR only on GitHub** (see "## Cycle PR and CI integration protocol" in `dev-workflow/SKILL.md`), provide a common template that Main uses to regenerate the description via a volatile file at the completion of each step and send it to the PR.

- Do not create a persistent artifact such as `pr-overview.md` inside the repository (Single-Source-of-Progress principle: the true sources are `progress.yaml` / `TODO.md`)
- The template is placed under share-artifacts as a **common contract that makes "when to fill in what" explicit**
- The description of an individual cycle (= the contents after template expansion) is **not committed**. It is generated volatilely in `$TMPDIR/dev-workflow/<identifier>-pr-body.md` and sent via `gh pr edit --body-file`

## Creation timing and author

- **Author:** Main (write-system `gh pr edit` is exclusive to Main, see `specialist-common §7`)
- **Regeneration timing:**
  - Immediately after the cycle initialization commit (simultaneously with creating the Draft PR at the start of Step 1, initial send)
  - Immediately after each step completion commit (mandatory, 9 times)
  - Other times when Main judges the contents have changed significantly (optional, as needed)
- **Output destination:** `$TMPDIR/dev-workflow/<identifier>-pr-body.md` (volatile, not reused across cycles)

## Section specifications

The sections of the template are structured to **be filled in incrementally**. At Step 1 completion, initialize with Summary + Cycle artefacts (intent-spec only) + Progress checklist (only Step 1 `[x]`) + CI status (results of the initial commit), and update the relevant sections as each subsequent step completes.

### `## Summary`

- Summarize the **purpose and main changes** in 1-3 bullets
- Source: derived from the "Purpose" section of the Intent Spec (`docs/workflow/<id>/intent-spec.md`)
- The contents rarely change as steps progress (kept as long as the Intent Spec does not change)

### `## Cycle artefacts`

- List the paths of artifacts already created in the format `<kind>: docs/workflow/<id>/<file>`
- Append the relevant line as each step completes. **Do not output lines for steps not yet started** (do not leave empty bullets)
- Exception: Retrospective is `docs/retrospective/<id>.md` (aggregated directory)

### `## Progress checklist`

- Checklist of Steps 1-9
- Completed steps as `[x]`, incomplete as `[ ]`
- If a step is "reactivated" via rollback, switch it back to `[ ]` and record the reason in the Notable incidents section

### `## CI status`

- **Latest commit SHA**: short SHA (7 characters)
- **Latest `check` job result**: `success` / `failure` / `in_progress`, run id, attempt number
- **Retry history**: list as a block only the steps where a failure → fix push cycle occurred
  - Example: `Step 6 task-T1 (commit abc1234): attempt 1 failure → fix push def5678 attempt 2 success`
- **Judgment basis**: output of `gh run view <run-id> --json conclusion` (for details, see the `share-ci-monitoring` skill)

### `## Test plan (completed at Step 8)`

- During Steps 1-7, **a tentative list with checkboxes not yet finalized** (based on SC-N from the Intent Spec)
- At Step 8 Validation completion, fill in each SC's verdict (`PASS` / `FAIL` / `SKIP` / `PENDING`) and observed values
- Observed values are summarized excerpts cited from `validation-report.md`

### `## Notable incidents (only if applicable)`

- History of rollback occurrences (derived from `progress.yaml.rollbacks[]`)
- History of recovery via user judgment after Blockers (derived from `progress.yaml.blockers[]`)
- Premise-breaking events such as taking in a large origin/main change via rebase
- **If not applicable, omit the section entirely** (do not leave an empty section)

### Footer separator (`---` + Generated with Claude Code)

- The separator line `---` and the footer must always be at the end of the PR body
- The footer wording is fixed: `🤖 Generated with [Claude Code](https://claude.com/claude-code)`

## Quality criteria

- **Single-Source-of-Progress consistency**: the contents of the PR description are a **view** derived from `progress.yaml` / `TODO.md`; the PR description must not become the true source
- **Incremental update consistency**: as steps progress, only the relevant sections of the template grow. **Do not leave lines for steps not yet started** (= do not leave placeholders such as "[Step 5]: TBD")
- **Freshness of CI status**: the latest SHA / run id at the time of the PR description update commit must be reflected (do not leave the state of an old run)
- **Test plan is a citation of Validator output**: the Test plan section after Step 8 completion cites the SC verdict lines of `validation-report.md` directly (summarization is fine but contradictions are not)
- **Notable incidents is fact-only**: subjective impressions are written in the Retrospective, and the PR description records only facts (occurrence date/time / commit SHA / scope of impact)

## Relationship with related artifacts

- **Inputs**: `progress.yaml` (Step status / artifacts list), `TODO.md` (Step 6/7 progress), `validation-report.md` (Test plan section after Step 8 completion)
- **Outputs**: GitHub PR body (persistent) + `$TMPDIR/dev-workflow/<identifier>-pr-body.md` (volatile)
- **Related skills**: `dev-workflow/SKILL.md` "## Cycle PR and CI integration protocol", `ci-monitoring/SKILL.md` (how to fill the CI status section), `specialist-common §7` (`gh pr edit` is exclusive to Main)

## Good examples / Bad examples

### Good example

- At Step 5 completion, Cycle artefacts lists 7 kinds (intent-spec / research/ / design / qa-design / qa-flow / task-plan / TODO), Progress checklist Steps 1-5 are `[x]`, CI status has the latest commit SHA + `check: success`, Test plan is a tentative list of SC-N, and the Notable incidents section is omitted (not applicable)
- Immediately before the footer there is one blank line + the `---` separator

### Bad example

- All not-yet-started Steps 6-9 are written into `Cycle artefacts` (with empty paths listed)
- The CI status SHA is stale (= does not reflect the latest update commit, the PR body update was forgotten when only another file was edited)
- Leaving the Notable incidents section empty as "not applicable" (it should be omitted)
- Leaving the Test plan as a tentative list even after Step 8 completion (Validator output not cited)
