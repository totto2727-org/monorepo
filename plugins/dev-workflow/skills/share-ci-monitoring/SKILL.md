---
name: share-ci-monitoring
description: >
  [Common to Main / Specialist] A utility skill that consolidates GitHub Actions CI run
  confirmation, background monitoring, and retry discipline on failure. After a push, it
  finalizes "CI passed" via a **double-check** (`gh run watch --exit-status` log tail EXIT
  line + `gh run view --json conclusion`), and on failure provides a procedure that allows
  up to 2 retries (new commit pushes), escalating to Blocker on the 3rd failure.
  Trigger conditions: CI confirmation after a commit push, all situations requiring CI PASS
  as a Step completion criterion, situations where Validator measures SC-7, situations
  filling the CI status section of the PR description.
  Referenced via "CI confirmation", "gh run watch", "CI failure retry", "ci-monitoring".
  Do NOT use for: workflow procedure definitions (dev-workflow), test design (qa-analyst
  authors qa-design.md), modifications of the CI workflow itself (editing
  `.github/workflows/*.yaml` is out of scope for this workflow), PR write operations
  (Main-only, see `specialist-common §7`).
allowed-tools: Bash, Read, Glob, Grep
---

# CI Monitoring — Procedures for Confirming, Monitoring, and Retrying GitHub Actions CI Runs

Use case category: **Workflow Automation** (finalizes CI results as observed values and incorporates them into completion judgments for subsequent steps)
Design pattern: **Domain Intelligence** (consolidates gh CLI / GitHub Actions domain knowledge and this repository's CI characteristics in one place)

In a dev-workflow cycle, immediately after pushing each step's completion commit (Step 6 commits per task), **confirm that "the corresponding CI run has passed"** before proceeding to the next step. This skill consolidates that CI confirmation procedure (background watch + EXIT line confirmation + `gh run view --json conclusion` double-check) and the retry discipline on failure (up to 2 retries -> escalate to Blocker).

## Basic Policy

- **CI PASS is finalized via a double-check**: Determine PASS only when **both** the exit code of `gh run watch --exit-status` (= the `EXIT=N` line at the log tail) and the value of an independent `gh run view <run-id> --json conclusion` are `success`. Determination must not be made solely on the bash exit code (= background task completion notification)
- **The EXIT line must always be written to the log tail**: Mandate the pattern `gh run watch ... > LOG 2>&1; echo "EXIT=$?" >> LOG` so that the `EXIT=` line can later be confirmed via grep / tail
- **Fixes are retried via new commit pushes**: This repository's CI failure patterns are almost exclusively deterministic problems (oxfmt / typecheck / test), so instead of `gh run rerun`, count **a new push of a fix commit** as 1 retry
- **Escalate to Blocker on the 3rd failure**: When the same Step series fails 3 consecutive times, terminate retries and record in `progress.yaml.blockers[]` + ask the user for a decision via the In-Progress user query format
- **Main-only write operations + Specialist read operations**: `gh run rerun` (write) is Main-only. Read operations (`gh run list --json` / `gh run view --json` / `gh run watch`) may also be used by Specialists (especially `validator`) (compliant with `specialist-common §7`)
- **Single-Source-of-Progress consistency**: The source of truth for CI status is GitHub's run state. The `## CI status` section of the PR description / `progress.yaml.blockers[]` are derived views

## Prerequisites

- This repository's CI is a single required check, `check` (workflow name = `CI` in `.github/workflows/*.yaml`). Job and workflow names have been finalized via investigation results such as `docs/workflow/*/research/ci-structure.md`
- Median 109s / p90 120s / max 140s. Zero flakiness; 100% of failures are deterministic problems (oxfmt Formatting / typecheck / test)
- `gh run rerun` is, in principle, not used in this repository (no flakiness, so re-running without fixes is meaningless)

## 1. Get Run ID Right After Push (Avoiding Race)

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
SHA=$(git rev-parse HEAD)

# Loop waiting for run id to appear (race avoidance, max 30 seconds)
RUN_ID=""
for i in 1 2 3 4 5 6; do
  RUN_ID=$(gh run list --branch "$BRANCH" --workflow CI --commit "$SHA" \
    --json databaseId --jq '.[0].databaseId')
  if [ -n "$RUN_ID" ] && [ "$RUN_ID" != "null" ]; then break; fi
  sleep 5
done

if [ -z "$RUN_ID" ] || [ "$RUN_ID" = "null" ]; then
  echo "ERROR: run id not found within 30s for $SHA" >&2
  exit 1
fi
```

If a run id does not appear within 30 seconds due to a GitHub Actions outage, abort with an error (Blocker candidate).

## 2. Background Watch + EXIT Line Recording

```bash
# 3 mandatory options:
#   --exit-status : reflect CI conclusion in exit code
#   --interval 10 : poll every 10 seconds (API rate margin)
#   --compact     : suppress output size
LOG="$TMPDIR/dev-workflow/ci-watch-$RUN_ID.log"
mkdir -p "$(dirname "$LOG")"

gh run watch "$RUN_ID" --exit-status --interval 10 --compact > "$LOG" 2>&1
echo "EXIT=$?" >> "$LOG"
```

When running in the background, append `&` to the end and collect completion via `wait $WATCH_PID`. **In either case, always append `echo "EXIT=$?" >> "$LOG"`** (because the tail line is read for later confirmation).

## 3. PASS Determination via Double-Check (Mandatory Procedure)

Determination must not be made solely on `gh run watch`'s exit code. Confirm that **both** of the following are `success`:

```bash
# (a) Read the EXIT line at the log tail
EXIT_LINE=$(tail -1 "$LOG")
case "$EXIT_LINE" in
  "EXIT=0") WATCH_RESULT="success" ;;
  "EXIT="*) WATCH_RESULT="failure" ;;
  *)        WATCH_RESULT="unknown" ;;
esac

# (b) Independently fetch conclusion via gh run view
CONCLUSION=$(gh run view "$RUN_ID" --json conclusion --jq '.conclusion')

# PASS only when both are success
if [ "$WATCH_RESULT" = "success" ] && [ "$CONCLUSION" = "success" ]; then
  echo "CI PASS: run $RUN_ID (commit $SHA)"
  STEP_CI_PASS=1
else
  echo "CI FAIL or inconsistent: watch=$WATCH_RESULT conclusion=$CONCLUSION"
  STEP_CI_PASS=0
fi
```

### Why a Double-Check Is Necessary

- The completion notification of a background task (= bash's `wait` exit code) only indicates **that the background job has exited**; in cases where `gh run watch` itself was interrupted (network disconnection, GitHub API 503, etc.), even an exit code of 0 does not guarantee that CI has been finalized
- The `EXIT=` line at the log tail records the exit code of `gh run watch --exit-status`, but if disconnection happens before the log is flushed, the `EXIT=` line itself may not be written
- `gh run view --json conclusion` **independently fetches** from the GitHub API, so it constitutes a confirmation via a separate path from watch
- Concrete example: in the past cycle `2026-05-03-pr-ci-integration`, Main short-circuited "CI PASS" from the background task's exit code 0, missed the log's `EXIT=1`, and overlooked 9 CI failures. Validator measured this with `gh run list --json conclusion` and exposed it (see Retrospective)

## 4. CI Failure Retry Flow (Up to 2 Retries -> Blocker)

```bash
ATTEMPT=1   # 1, 2 are allowed; 3 escalates to Blocker
# ATTEMPT is the count of "failure -> fix -> re-push" cycles, manually counted by Main
# (1 retry = 1 fix-commit push; `gh run rerun` is not used)

while [ $ATTEMPT -le 2 ] && [ $STEP_CI_PASS -eq 0 ]; do
  # 1. Save failure content
  gh run view "$RUN_ID" --log-failed > "$TMPDIR/dev-workflow/ci-fail-$RUN_ID.log"

  # 2. Main reads the log and applies a local fix according to the failure cause
  #    - oxfmt: vp check --fix && vp check
  #    - typecheck: vp check (until pass)
  #    - test: vp test
  # 3. git add the fix with explicit paths, commit in Conventional Commits format
  # 4. git push origin "$BRANCH"
  # 5. Re-execute §1 to §3 above and determine PASS / FAIL with the new RUN_ID

  ATTEMPT=$((ATTEMPT + 1))
done

if [ $STEP_CI_PASS -eq 0 ]; then
  # 3 consecutive failures -> escalate to Blocker
  # Append a CI failure entry to progress.yaml.blockers[] and commit
  # In-Progress user query format:
  # Create $TMPDIR/dev-workflow/step<N>-ci-blocker.md (background / options / recommendation)
  # Ask user for a decision (Step 3 rollback / design rethink / different approach)
  echo "BLOCKER: CI failed 3 consecutive attempts" >&2
fi
```

For the format of recording into `progress.yaml.blockers[]`, see the CI failure example in `share-artifacts/references/progress-yaml.md`.

## 5. How to Fill the `## CI status` Section of the PR Description

When updating the PR description immediately after each step's completion commit (for the send procedure, see **`share-pr-manager` skill §2**), reflect the values obtained via the procedures above into the CI status section of the template (`share-artifacts/templates/pr-body.md`):

```markdown
## CI status

- Latest commit SHA: <short 7 chars>
- Latest `check` job: success (run id: <RUN_ID>, attempt: 1)
- Retry history: none
```

If retries occurred, format the history as a block:

```markdown
## CI status

- Latest commit SHA: def5678
- Latest `check` job: success (run id: 25271162031, attempt: 2)
- Retry history:
  - Step 6 task-T1 (commit abc1234): attempt 1 failure (oxfmt) -> fix push def5678 attempt 2 success
```

## 6. Use by Validator (Step 8)

When `specialist-validator` measures SC-7 (each step completion commit's CI ultimately PASSes), use the read operations from this skill:

```bash
# Aggregate the latest attempt's conclusion for all branch commit SHAs
git log --pretty=format:"%H" "main..HEAD" | while read SHA; do
  CONCLUSION=$(gh run list --branch "$BRANCH" --commit "$SHA" --workflow CI \
    --json conclusion --jq '.[0].conclusion // "no-run"')
  echo "$SHA $CONCLUSION"
done
```

If retries occurred, **the fix commit has a different SHA**, so simply tracking the step completion commit SHA automatically reflects the "ultimate PASS" (since it does not go through `gh run rerun`, the attempt number is generally 1).

## What This Skill Does NOT Cover

- **Modifications of the CI workflow itself** (editing `.github/workflows/*.yaml`) -> out of scope for this workflow. Domain of CI/CD pipeline design
- **Test design** (authoring qa-design.md / qa-flow.md) -> `specialist-qa-analyst`
- **PR write operations** (`gh pr create` / `gh pr edit` / `gh pr ready`, etc.) -> delegated to **`share-pr-manager`** skill. The Main-only permission boundary is defined in `specialist-common §7`
- **Active use of `gh run rerun`** -> this repository has no flakiness, so re-runs are basically unnecessary (used only ad hoc by Step 7 reviewer when needed)
- **Long-term CI statistics** (weekly / monthly trends) -> out of scope for this workflow; handled by separate skills or observability dashboards
- **Integrated monitoring of multiple workflows / matrix CI** -> this repository has only the single `check` job; future matrix-ization is carried over as a Retrospective matter

## Triggering Test (Examples)

- "I pushed a commit and want to confirm that CI passed" -> execute the procedures in §2 to §3
- "Step 6 task T1 is complete; I want to confirm CI + update PR description" -> execute §2 to §5 in sequence
- "CI failed; how should I retry?" -> the retry flow in §4
- "As a Validator, I want to measure SC-7" -> the read operations in §6
