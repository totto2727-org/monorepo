---
name: adr
description: >
  Skill for creating and referencing Architecture Decision Records (ADR).
  Use when recording design decisions, reviewing past architectural choices,
  or checking existing ADRs before implementation.
  Common triggers: "create ADR", "record design decision", "check ADR",
  "architecture decision", "design rationale".
  Do NOT use for: general documentation, meeting notes, code comments,
  or changelog entries.
---

# ADR (Architecture Decision Record) Guidelines

## Overview

Important architectural decisions are recorded as ADRs in `docs/adr/`.
If the `docs/adr/` directory does not exist, create it before writing the first ADR.

## File Format

### File Name

!`echo "$(date +%Y-%m-%d)-title.md"`

### Frontmatter

All ADR files must have the following YAML frontmatter:

```yaml
---
confirmed: false
---
```

| Field       | Type    | Description                                                                 |
| ----------- | ------- | --------------------------------------------------------------------------- |
| `confirmed` | boolean | `true`: Confirmed (generally immutable), `false`: Proposed (pending review) |

### Body Structure

```markdown
---
confirmed: false
---

# ADR: Title

## Context

Background on why this decision is needed.

## Decision

The specific design decision. May include table design, API design, route design, etc.

## Impact

The scope of impact from this decision. New tables, changes to existing code, new routes, etc.
```

## Operational Rules

1. **Creation**: Create with `confirmed: false` and confirm after review.
2. **Confirmation**: After user approval, change `confirmed` to `true`.
3. **Immutability Principle**: ADRs with `confirmed: true` must not be modified in principle.

## ADR Creation Procedure

1. Ensure `docs/adr/` directory exists (create if missing)
2. Create a `YYYY-MM-DD-title.md` file in `docs/adr/`
3. Set `confirmed: false` in the frontmatter
4. Describe the context, decision, and impact
5. Commit and submit for review
6. After approval, change to `confirmed: true`

## Referencing ADRs

- Check relevant ADRs before implementation and follow confirmed design decisions
- Do not implement anything that contradicts an ADR with `confirmed: true`
