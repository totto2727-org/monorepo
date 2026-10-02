# Output Evaluation

Use this method for G6 in a general review, or when a focused review covers functional quality, baselines, or iteration.
The normal and problem/edge cases required by `SKILL.md` are minimum review evidence, not Agent Skills format constraints.

## Define cases

Define each case with:

- A realistic user prompt.
- A human-readable expected output.
- Required input files, if any.
- Observable assertions derived from the expected behavior, refined when execution reveals an unreliable check rather than relaxed merely to fit the output.

Include at least one normal and one problem or edge case for a general review.
Add malformed, boundary, or ambiguous cases where they exercise a material risk.

## Isolate runs and choose a baseline

Start every run in a clean context. Do not leak development discussion, expected answers, previous outputs, or the suspected fix into the evaluation.

Use the same prompt and inputs across configurations:

- Compare with the skill against no skill when measuring whether the skill adds value.
- Compare a revised skill against a snapshot of the previous version when measuring an improvement.
- Skip the baseline for a structural-only review unless the report claims better output, reliability, or efficiency.

Store prompts, inputs, outputs, timing, and grading evidence so another reviewer can trace each result. No exact workspace layout is required.

## Write assertions and grade outputs

Prefer assertions that are specific, observable, and tolerant of irrelevant wording differences. Reject assertions such as "the output is good" and brittle checks that require an exact phrase without a functional reason.

For each executed assertion, record PASS or FAIL with a concrete output reference.
Mark concrete unexecuted cases Designed and absent evidence Missing, rather than inventing a pass or failure.

- Use verification scripts for mechanical facts such as file existence, valid syntax, dimensions, or row counts.
- Use human review for usefulness, visual quality, tone, organization, and qualities not captured by objective assertions.
- Use blind comparison when version labels could bias a holistic judgment.

Review the assertions themselves. Replace checks that always pass both configurations, always fail because they are impossible, or cannot be verified from the available output.

## Analyze and iterate

Look beyond aggregate pass rates:

- Skill-only passes reveal where the skill adds value.
- Failures in both configurations can indicate a broken assertion or unrealistic task.
- Inconsistent results can indicate model randomness or ambiguous instructions.
- Time, token, or tool-call outliers can reveal wasted work in execution traces.

Combine failed assertions, specific human feedback, and execution traces when proposing revisions. Generalize the correction, remove instructions that add no value, and bundle repeated helper logic as a tested script. Rerun all applicable cases in a fresh iteration and stop when feedback is consistently satisfied or improvement plateaus.
