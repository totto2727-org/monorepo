# Maintaining this skill

Keep these resources useful to people authoring documents, not to a document-generation system.
Use [documentation-principles](../../documentation-principles/SKILL.md) to judge whether a detail helps the reader.

## Resource roles

- Each document's `spec.md` contains audience boundaries and document-specific guidance.
- `template.md` uses Jinja placeholders and optional sections to illustrate the overall document shape.
- `sample.md` shows a readable concrete example without promising exact template output.

Keep the public `readme/spec.md`, `agents/spec.md`, and `adr/spec.md` paths stable for existing links.
Use simple descriptive placeholders rather than a required input schema, type guards, or renderer configuration.
Shorten templates when branching obscures the document structure.
Samples may omit irrelevant sections or use different wording from the template.
No generator, template rendering tests, fixture contexts, byte comparison, or generated-from footer is needed.

## Review

Read the guidance, template, and sample together for contradictory advice and unclear audience boundaries.
Check local links, meaningful examples, and commands that the document actually claims readers can run.
Label hypothetical examples and distinguish illustrative paths from links to maintained resources.
When real product examples need behavioral verification, use the project's actual implementation and normal test workflow rather than a copied toy implementation.
That verification belongs to the product, not to a Jinja rendering contract.
