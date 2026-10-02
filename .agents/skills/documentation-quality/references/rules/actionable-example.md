# Concrete demonstration

## Applicability and context

Use `actionable-example` when developers need a concrete demonstration to apply a procedure or understand a concept.
Inspect surrounding explanations and existing examples before deciding that a demonstration is missing.
Review English source documents, not translated editions.
Use these examples for follow-up review, not as samples or expected labels in blind model input.

## Illustrative comparison

This hypothetical batch tool reads `workers` and `tasks_per_worker` from a JSON configuration.
Both are positive integers, and its maximum concurrent task count is their product.
The guide teaches sizing a three-worker configuration for at most twelve concurrent tasks.

**Problematic**

> Adjust the per-worker task limit to keep total concurrency within twelve tasks.

**Improved**

> Divide the total limit by the worker count: 12 / 3 = 4 tasks per worker.
> Use this configuration:

```json
{
  "workers": 3,
  "tasks_per_worker": 4
}
```

> The resulting maximum is 3 * 4 = 12 concurrent tasks.
> Increasing `workers` without lowering `tasks_per_worker` also increases that maximum.

### Why this diagnosis

The problematic instruction leaves the learner to connect the overall limit to the individual fields.
The filled configuration and calculation show that connection and its resulting behavior.
A runnable program would add no necessary information to this particular sizing example.

## Exceptions and false positives

- Commands, configuration, request/result pairs, diagrams, calculations, and code are valid demonstrations when suited to the idea.
- Factual reference entries, warnings, and already unambiguous instructions may need no example.
- An architecture concept may need a diagram rather than an execution sequence.
- A focused example may rely on clearly available earlier setup rather than repeat an entire project.
- Customization examples should show the changed behavior and how it is connected, not merely name an undefined replacement.
- A demonstration does not replace necessary explanations of constraints or failure handling.

## Inspect and fix a failure

1. Identify the procedure or relationship the reader is expected to grasp.
2. Locate the missing connection rather than requiring an example merely because none is present.
3. Choose the smallest suitable demonstration and show its outcome or interpretation.
4. Verify inputs, transformations, labels, and results against the stated contract.
5. Check real examples against supported behavior separately from this writing judgment.

## Abstention boundaries

- `not_applicable`: no concrete demonstration is needed for the passage's purpose.
- `insufficient_context`: the concept or referenced setup is unavailable, preventing a completeness judgment.
- A clearly missing step in an otherwise supplied demonstration is a defect, not missing context.
