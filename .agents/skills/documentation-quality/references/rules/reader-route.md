# Reader route

## Applicability and context

Use `reader-route` for developer pages whose purpose depends on coherent ordering or navigation.
Establish the reader's goal and inspect relevant destinations when navigation delegates essential information.
Review English source documents, not translated editions.
Use these examples for follow-up review, not as samples or expected labels in blind model input.

## Illustrative comparison

This hypothetical restore runbook requires an empty target, a compatible snapshot, and write access before restoration.
Assume its supplied sections contain those checks and a result-verification procedure.
These outlines compare order, not executable restore commands.

**Problematic**

```text
Restore a test database
1. Restore the snapshot.
2. Find your target type in the administration handbook.
3. Check that the target is empty and the snapshot is compatible.
4. Obtain write access if the command failed.
5. Browse the troubleshooting index to find verification instructions.
```

**Improved**

```text
Restore a test database
1. Choose the target type under "Supported restore targets."
2. Follow that target's "Before restoring" checks:
   empty target, compatible snapshot, and write access.
3. If all checks pass, follow "Restore the snapshot."
4. Follow "Verify the restored data" before using the test database.
```

### Why this diagnosis

The improved route places necessary checks before the operation that relies on them.
Its destinations identify the next relevant section instead of sending readers through broad indexes.
The route ends with the intended verified outcome, not merely a completed command.
Moving a prerequisite behind a link works only when the destination actually supplies it before use.

## Exceptions and false positives

- Reference indexes can support selective lookup rather than a single sequential reading path.
- Architecture explanations may need concepts introduced in dependency order without any setup procedure.
- Multiple routes are legitimate when readers have different environments, constraints, or goals.
- Require prior tutorial state only when the current task depends on it.
- Direct-entry readers may need a prerequisite repeated locally.
- Do not impose a particular generator, platform, tool, or default route on unrelated documentation.

## Inspect and fix a failure

1. Trace the intended reading or execution route from entry to its stated outcome.
2. Identify premature actions, missing conceptual foundations, ambiguous choices, or unnecessary detours.
3. Check delegated prerequisites and next steps in the actual destination excerpts.
4. Put prerequisites before use and a documented normal path before optional branches, when one exists.
5. Verify real links and commands separately from the judgment of ordering.

## Abstention boundaries

- `not_applicable`: an isolated factual entry or lookup-only reference has no meaningful ordering or navigation responsibility.
- `insufficient_context`: the page scope or decisive linked destination is unavailable.
- Do not assume an unseen destination contains a prerequisite or classify its contents as a proven failure.
