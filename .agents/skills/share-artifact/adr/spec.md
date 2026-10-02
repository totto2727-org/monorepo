# ADR guidance

An Architecture Decision Record captures a durable project decision, its reasons, and its consequences.
Use [documentation-principles](../../documentation-principles/SKILL.md) for content quality.
The [template](template.md) outlines a record, and the [sample](sample.md) illustrates an API compatibility decision.

## Scope and storage

Use ADRs for decisions with lasting project-wide relevance, not work logs or transient implementation notes.
Store records at `docs/adr/<YYYY-MM-DD>-<title>.md`, using a kebab-case title.
Create the directory when filing the first record.
Follow an established project ADR convention when it differs.

## Decision structure

- Title identifying the decision.
- Filing date, decision owner, and origin when useful for accountability.
- Context explaining the problem, constraints, and forces.
- Decision stating the chosen approach early.
- Alternatives with the reasons for adoption or rejection.
- Consequences covering additions, effects on existing users, future constraints, and costs.
- Related records when they help explain dependencies or supersession.

A compact options table can make alternatives easier to compare.
Use prose when a table would obscure the trade-offs.
Do not add empty metadata or sections just to match the template.

## Approval and supersession

When using the illustrated frontmatter convention, `scope: general` identifies a durable project decision and `confirmed` records approval of the record by its decision owner.
A new unapproved record uses `confirmed: false`.
Implementation completion or an unrelated approval does not establish approval of the record.

Preserve an approved record's historical decision rather than silently rewriting it to match a new approach.
Record a changed decision in a new ADR and link the old and new records with a supersession notice.
For example:

```markdown
> Superseded by [New decision](2026-09-20-new-decision.md).
```

The new record explains what changed and contains the active decision.
