# Triggering Evaluation

Use this method for G2/G6 in a general review, or when a focused review covers activation or metadata changes.
The minimum explicit, paraphrased, and adjacent-negative cases in `SKILL.md` are review requirements, not standard format constraints.
Beyond those minimum cases, do not turn example query counts, run counts, thresholds, or split ratios into universal requirements.

## Design the query set

Use realistic prompts labeled `should_trigger: true` or `should_trigger: false`.

For should-trigger cases, vary:

- Phrasing: formal, casual, abbreviated, and occasionally misspelled.
- Explicitness: direct domain names and indirect descriptions of the need.
- Detail: terse requests and context-rich requests with paths or concrete data.
- Complexity: focused tasks and larger workflows where the skill-relevant part is only one step.

For should-not-trigger cases, prefer near-misses that share terms or concepts but require an adjacent capability. Obviously unrelated prompts provide little evidence about description precision.

Include realistic context such as file paths, field names, personal background, and user constraints. Start with the smallest useful set; expand only when the review risk or optimization goal justifies it.

## Execute and record evidence

For an authorized client evaluation, verify that the skill is installed and discoverable.
For each query, record whether the client loaded the target `SKILL.md` using an activation trace, tool history, verbose log, or equivalent artifact.
If a suitable client or trace is unavailable, keep concrete cases Designed and explain the limitation without blocking a structural review.
A model's statement that it would use the skill is not an observed activation.

Model activation may be nondeterministic. When a stable rate matters, run each query multiple times and record the fraction of activations. A single run can show one observed outcome but cannot establish a stable trigger rate.

## Avoid overfitting

For repeated description optimization, use separate revision and held-out query sets with positive and negative cases where relevant.
This is unnecessary for a one-off structural review.

1. Establish the current description's baseline without exposing held-out results to the revision process.
2. Use only train failures to guide revisions.
3. Generalize from failure categories rather than copying exact query keywords.
4. Select the best revision by validation behavior, not by the latest iteration number.
5. Stop when improvement is no longer meaningful or the labels themselves appear unreliable.

Keep validation results hidden from the revision process. Otherwise the validation set becomes additional training data and no longer measures generalization.

## Apply the result

After updating the description:

1. Recheck the 1024-character limit.
2. Run a quick manual sanity check.
3. Use fresh positive and negative prompts that were not part of optimization for the final generalization check.
4. Preserve concrete evidence and classify unexecuted cases as Designed rather than Executed.
