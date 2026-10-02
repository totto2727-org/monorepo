---
name: documentation-quality
description: >-
  Review developer documentation across languages, tools, and project types, with on-demand anti-patterns and examples.
  Use for documentation quality checks and optional parallel Jev evaluation through OOMOL/OpenConnector.
  Apply primarily to English source documentation, not translated editions.
  Use documentation-principles for writing principles and share-artifact for document formats.
compatibility: Node.js 22 or later and curl for the optional evaluator. Live checks require OOMOL/OpenConnector with TypeSafe AI Actions.
---

# Documentation Quality

Apply [documentation-principles](../documentation-principles/SKILL.md) to the reader's task, not a document-length target.
Select criteria by the document's purpose rather than a particular technology or development workflow.
Review English source documentation by default and exclude translated editions from evaluations.
Translation fidelity, source accuracy, runnable examples, and working links require separate checks.

## Review workflow

1. Establish the audience, purpose, and available evidence.
2. Select applicable checks from the [rule index](references/rules.md), not every rule for every fragment.
3. Review coherent paragraphs, heading sections, or complete small pages with their surrounding context.
   Keep code, tables, warnings, and their explanations intact; assess navigation and cross-page duplication at the wider scope.
4. For a finding or uncertain judgment, open only that rule's linked guide for anti-patterns, an improved example, and exceptions.
   Inspect the actual passage before recommending a correction; examples illustrate decisions, not mandatory wording.
5. Report the source range, rule ID, evidence, and next action.
   Distinguish defects from missing context, inapplicable rules, and model errors rather than rewriting every flagged passage.

## Optional parallel checks

Use [running evaluations](references/running.md) for manifests, gateway setup, dry runs, bounded concurrency, and report interpretation.
Send content only to an authorized OOMOL/OpenConnector gateway through its `typesafe_ai.evaluate` Action, never a direct provider endpoint.
Keep review examples and expected labels out of blind evaluation requests.

> [!WARNING]
> Jev judgments are review assistance, not an unattended approval gate.
> High confidence does not guarantee correctness; low confidence, abstentions, and request errors are not passes.

For `fail` or an uncertain answer, match its question ID to the report's `rule.id`, then open that rule in the [index](references/rules.md).
For transport or response-format errors, follow the [execution guide](references/running.md#read-the-report) instead of changing document prose.
A reasoning reviewer must verify any proposed correction in context; Jev does not supply a verified rationale.
