# Consequential limit

## Applicability and context

Use `consequential-limit` when a developer-documentation passage describes a limitation affecting the reader's intended use or understanding.
Establish where it applies, what it means for the reader, and any known available remedy or alternative.
Review English source documents, not translated editions.
Use these examples for follow-up review, not as samples or expected labels in blind model input.

## Illustrative comparison

This hypothetical database client keeps export cursors for one hour after creation.
Its defined contract rejects expired cursors and allows a new export, but does not recover an expired export's position.

**Problematic**

> Export cursors have limited retention.
> Restart if necessary.

**Improved**

> An export cursor expires one hour after creation.
> After that, a resume request fails with `CURSOR_EXPIRED` and cannot continue from the saved position.
> Start a new export from the beginning if you still need the data.
> Restarting does not recover the expired cursor's position.

### Why this diagnosis

The improved passage states the interval, the affected operation, and the observable failure.
It identifies an available next action without claiming that the action restores lost progress.
It does not suggest that all database operations stop when one export cursor expires.
The warning need not become a complete export tutorial to communicate the limitation.

## Exceptions and false positives

- Require a remedy or alternative only when it is known and available.
- If none exists, explain the limitation without promising a solution.
- If availability is unknown, do not turn uncertainty into either a remedy or a claim that none exists.
- A limitation can qualify a benchmark or architecture conclusion, not only restrict an operation.
- Choose placement and prominence by reader impact and document format, not a mandatory callout syntax.
- Explicit surrounding context may supply applicability or consequences when readers encounter it before relying on the guidance.

## Inspect and fix a failure

1. Identify the affected operation, claim, configuration, or time interval precisely.
2. Verify the consequence and any proposed remedy against the supplied evidence.
3. Replace vague restriction language with what the reader can expect or cannot conclude.
4. State a known next action without implying it solves more than it does.
5. Check that readers encounter the qualification before relying on the affected guidance.

## Abstention boundaries

- `not_applicable`: the target discusses no consequential restriction or limitation.
- `insufficient_context`: decisive evidence about applicability, effect, or an asserted remedy is unavailable.
- Omitting an established consequence is a defect even when no remedy exists.
