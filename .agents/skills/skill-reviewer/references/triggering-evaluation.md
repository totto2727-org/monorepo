# Triggering Evaluation

Read this reference when a review needs detailed trigger diagnosis, evidence, or description optimization. Do not turn example query counts, run counts, thresholds, or split ratios from source guides into universal scoring requirements.

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

Ensure the skill is installed and discoverable by the target client. For each query, record whether the client loaded the target `SKILL.md` using an activation trace, tool history, verbose log, or equivalent artifact.

Model activation may be nondeterministic. When a stable rate matters, run each query multiple times and record the fraction of activations. A single run can show one observed outcome but cannot establish a stable trigger rate.

## Avoid overfitting

When optimizing a description, divide queries into fixed train and validation sets with both positive and negative cases represented in each set.

1. Evaluate the current description on both sets.
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
