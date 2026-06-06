---
name: ci-monitoring
description: >
  A utility skill that consolidates GitHub Actions CI run confirmation,
  background monitoring, and retry discipline on failure. After a push, it
  finalizes "CI passed" via a double-check (`gh run watch --exit-status` log tail EXIT
  line + `gh run view --json conclusion`), and on failure provides a procedure that allows
  up to 2 retries (new commit pushes), escalating to a blocker decision on the 3rd failure.
  Trigger conditions: CI confirmation after a commit push, all situations requiring CI PASS
  as a completion criterion.
  Referenced via "CI confirmation", "gh run watch", "CI failure retry", "ci-monitoring".
  Do NOT use for: modifications of the CI workflow itself (editing
  `.github/workflows/*.yaml` is out of scope), test design, PR write operations.
metadata:
  author: totto2727
  version: 1.0.0
allowed-tools: Bash, Read, Glob, Grep
---

# CI Monitoring — Procedures for Confirming, Monitoring, and Retrying GitHub Actions CI Runs

Use case category: **Workflow Automation** (finalizes CI results as observed values and incorporates them into completion judgments for subsequent steps)
Design pattern: **Domain Intelligence** (consolidates gh CLI / GitHub Actions domain knowledge and this repository's CI characteristics in one place)

Immediately after pushing a commit, **confirm that "the corresponding CI run has passed"** before proceeding to the next step. This skill consolidates that CI confirmation procedure (background watch + EXIT line confirmation + `gh run view --json conclusion` double-check) and the retry discipline on failure (up to 2 retries -> escalate to blocker).

## Basic Policy

- **CI PASS is finalized via a double-check**: Determine PASS only when **both** the exit code of `gh run watch --exit-status` (= the `EXIT=N` line at the log tail) and the value of an independent `gh run view <run-id> --json conclusion` are `success`. Determination must not be made solely on the bash exit code (= background task completion notification)
- **The EXIT line must always be written to the log tail**: Mandate the pattern `gh run watch ... > LOG 2>&1; echo "EXIT=$?" >> LOG` so that the `EXIT=` line can later be confirmed via grep / tail
- **Fixes are retried via new commit pushes**: This repository's CI failure patterns are almost exclusively deterministic problems (oxfmt / typecheck / test), so instead of `gh run rerun`, count **a new push of a fix commit** as 1 retry
- **Escalate to Blocker on the 3rd failure**: When the same commit series fails 3 consecutive times, terminate retries and ask the user for a decision

## 1. Preparation: latest run ID and branch

```bash
BRANCH=$(git branch --show-current)
RUN_ID=$(gh run list --branch "$BRANCH" --limit 1 --json databaseId --jq '.[0].databaseId')
echo "BRANCH=$BRANCH RUN_ID=$RUN_ID"
```

## 2. Background Watch (Mandatory)

```bash
LOG="$TMPDIR/ci-watch-${RUN_ID}.log"
(gh run watch "$RUN_ID" --exit-status > "$LOG" 2>&1; echo "EXIT=$?" >> "$LOG") &
WATCH_PID=$!
echo "Background watch started: PID=$WATCH_PID LOG=$LOG"
```

## 3. Double-Check (watch exit + `gh run view` conclusion)

After the background task completes, perform a double-check:

```bash
# Check 1: EXIT line at log tail
EXIT_LINE=$(grep -E '^EXIT=[0-9]+$' "$LOG" | tail -n 1)
WATCH_RESULT=${EXIT_LINE#EXIT=}

# Check 2: independent API fetch
CONCLUSION=$(gh run view "$RUN_ID" --json conclusion --jq '.conclusion')

if [ "$WATCH_RESULT" = "0" ] && [ "$CONCLUSION" = "success" ]; then
  echo "CI PASS confirmed (double-check OK)"
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

## 4. CI Failure Retry Flow (Up to 2 Retries -> Blocker)

```bash
ATTEMPT=1   # 1, 2 are allowed; 3 escalates to blocker
# ATTEMPT is the count of "failure -> fix -> re-push" cycles
# (1 retry = 1 fix-commit push; `gh run rerun` is not used)

while [ $ATTEMPT -le 2 ] && [ $STEP_CI_PASS -eq 0 ]; do
  # 1. Save failure content
  gh run view "$RUN_ID" --log-failed > "$TMPDIR/ci-fail-$RUN_ID.log"

  # 2. Read the log and apply a local fix according to the failure cause
  #    - oxfmt: vp check --fix && vp check
  #    - typecheck: vp check (until pass)
  #    - test: vp test
  # 3. git add the fix with explicit paths, commit in Conventional Commits format
  # 4. git push origin "$BRANCH"
  # 5. Re-execute §1 to §3 above and determine PASS / FAIL with the new RUN_ID

  ATTEMPT=$((ATTEMPT + 1))
done

if [ $STEP_CI_PASS -eq 0 ]; then
  # 3 consecutive failures -> escalate to blocker
  echo "BLOCKER: CI failed 3 consecutive attempts" >&2
fi
```

## 5. How to Fill the `## CI status` Section of the PR Description

When updating the PR description immediately after each commit push, reflect the values obtained via the procedures above into the CI status section:

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
  - commit abc1234: attempt 1 failure (oxfmt) -> fix push def5678 attempt 2 success
```

## 6. Audit: Measuring CI Results for a Branch

To aggregate the latest attempt's conclusion for all branch commit SHAs:

```bash
git log --pretty=format:"%H" "main..HEAD" | while read SHA; do
  CONCLUSION=$(gh run list --branch "$BRANCH" --commit "$SHA" --workflow CI \
    --json conclusion --jq '.[0].conclusion // "no-run"')
  echo "$SHA $CONCLUSION"
done
```

If retries occurred, **the fix commit has a different SHA**, so simply tracking the original commit SHA automatically reflects the "ultimate PASS" (since it does not go through `gh run rerun`, the attempt number is generally 1).

## What This Skill Does NOT Cover

- **Modifications of the CI workflow itself** (editing `.github/workflows/*.yaml`) -> out of scope; domain of CI/CD pipeline design
- **Test design** (authoring test plans) -> domain of QA/test engineering
- **PR write operations** (`gh pr create` / `gh pr edit` / `gh pr ready`, etc.) -> delegated to PR management skills or manual operation
- **Active use of `gh run rerun`** -> this repository has no flakiness, so re-runs are basically unnecessary (used only ad hoc when needed)
- **Long-term CI statistics** (weekly / monthly trends) -> out of scope; handled by separate skills or observability dashboards
- **Integrated monitoring of multiple workflows / matrix CI** -> this repository has only the single `check` job; future matrix-ization is a separate concern

## Triggering Test (Examples)

- "I pushed a commit and want to confirm that CI passed" -> execute the procedures in §2 to §3
- "I want to confirm CI + update PR description" -> execute §2 to §5 in sequence
- "CI failed; how should I retry?" -> the retry flow in §4
- "I want to audit CI results for all commits on this branch" -> the read operations in §6
