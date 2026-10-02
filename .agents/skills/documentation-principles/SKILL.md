---
name: documentation-principles
description: >-
  Shared principles for creating, editing, and planning developer documentation across languages, tools, and project types.
  Apply primarily to English source documentation, not translated editions.
  Use documentation-quality for reviews and rule-specific examples, and share-artifact for document formats.
---

# Documentation Principles

**Minimize the reader's effort to find, understand, and use the information they need.**
Choose guidance by the reader's purpose, not a particular language, framework, or project structure.
Apply these principles primarily to English source documentation before translation, not as a rewriting or quality-review pass on translated editions.
Review translation fidelity and target-language correctness separately.

## Serve a reader's purpose

Choose the audience, task, and document type before deciding what belongs.
Include information because it helps that reader, not merely because it is available.
Distinguish learning, task execution, reference, and explanation without forcing every document into one format.

## Lead with the useful answer

State the action, result, or decision before supporting background.
When a task has a supported normal path, present it before optional alternatives and disclose detail when it becomes necessary.
Match technical detail to the reader's goal, whether usage, operation, implementation, or design.

## Give each unit one responsibility

Organize pages, sections, and paragraphs around coherent reader questions.
Choose boundaries by meaning and keep dependent explanation together.
A short unit is complete when it answers its question with the context its reader needs.

## Keep information discoverable and local

Put prerequisites and consequences where the reader needs them.
Maintain one clear home for detailed guidance and link to it from relevant entry points.
Separate choosing a path from following the chosen task.

## Use the minimum sufficient form

Prefer direct, concrete wording and descriptive headings.
Remove repetition and material that adds no reader value, not necessary context.

## Prefer examples over prose

Prefer concrete examples, code, and diagrams over prose describing the same behavior or relationships.
Use prose to supply context, constraints, and consequences that the examples cannot convey.
Choose the form that makes the information easiest to understand.

## Preserve accuracy and consequences

Accuracy takes precedence over brevity.
Keep requirements, constraints, failure conditions, and meaningful trade-offs explicit, with consistent terminology.
Distinguish verified facts from assumptions, make consequential limitations visible, and state a next action when one is available.

## Apply the principles

Before adding material, ask whether the reader needs it for this document's purpose.
Before removing material, ask whether doing so loses accuracy, context, or a necessary decision.
Use the repository's document conventions; default to GitHub Flavored Markdown when none are specified.

Use [documentation-quality](../documentation-quality/SKILL.md) for review procedures, anti-patterns, and rule-specific examples.
Use [share-artifact](../share-artifact/SKILL.md) for README, AGENTS.md, and ADR structure.
These principles do not prescribe a research, editing, or agent-execution workflow.

## Sources

- [Diátaxis](https://diataxis.fr/): distinguish reader needs and document types.
- [StrictDoc technical writing guidance](https://github.com/strictdoc-project/technical_writing_skill/blob/main/SKILL.md): direct wording, bottom-line-first structure, and concision.
- [Next.js documentation](https://nextjs.org/docs) and [agent guidance](https://github.com/vercel/next.js/blob/canary/.agents/skills/README.md): task-oriented structure and progressive disclosure.
