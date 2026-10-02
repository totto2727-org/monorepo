# Reader relevance

## Applicability and context

Use `consumer-contract` to assess whether a developer-documentation passage serves its intended audience and goal.
Read the heading and surrounding material before deciding which facts, explanations, or actions matter.
Review English source documents, not translated editions.
Use these examples for follow-up review, not as samples or expected labels in blind model input.

## Illustrative comparison

This hypothetical CLI accepts an output path and refuses to overwrite an existing file.
The section teaches exporting a report, not the architecture of the command dispatcher.

**Problematic**

> Set `--output` to the destination file path.
> If the file already exists, the export fails without changing it.
> The dispatcher constructs its command registry through three internal modules.

**Improved**

> Set `--output` to the destination file path.
> If the file already exists, the export fails without changing it.

### Why this diagnosis

The retained sentences explain the input and a consequence that affects the export task.
The dispatcher sentence does not help this reader choose an output path or understand the result.
That same detail could matter in an architecture explanation of command registration.
The distinction is relevance to the stated audience and goal, not a fixed division between users and maintainers.

## Exceptions and false positives

- Architecture explanations can serve understanding without asking the reader to perform an action.
- Implementation detail belongs when it explains a meaningful compatibility requirement, failure, or design decision.
- Definitions, defaults, constraints, and uncertainty may be essential even when they lengthen the passage.
- Specialist audiences may need detail that a general developer audience does not.
- Do not remove a useful explanation merely because code or a table mentions the same subject.

## Inspect and fix a failure

1. State who the passage is for and what they need to understand, decide, or do.
2. Identify the exact detail that does not support that goal in the supplied context.
3. Verify behavior before replacing a mechanism with its reader-visible consequence.
4. Preserve relevant conditions and consequences when removing or relocating the distraction.
5. Reread the unit to ensure the change did not remove a necessary qualification.

## Abstention boundaries

- `not_applicable`: the target has no explanatory or instructional content to assess, such as an isolated identifier list.
- `insufficient_context`: the audience or purpose needed to judge relevance cannot be established.
- An unfamiliar or specialist audience is not evidence that its necessary detail is irrelevant.
