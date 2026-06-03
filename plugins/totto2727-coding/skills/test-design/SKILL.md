---
name: test-design
description: >
  Designs reviewer-friendly test plans before implementation by translating
  success criteria and design decisions into framework-agnostic test cases
  (`qa-design.md`) and Mermaid coverage flows (`qa-flow.md`). Use when the user
  asks for "test design", "QA design", "qa-design.md", "qa-flow.md", success
  criteria coverage, automated/manual test rationale, or a human-reviewable test
  plan. This is intentionally separate from the `test` skill: `test` covers how
  to write and review concrete test code, while `test-design` covers pre-code
  test strategy and coverage artifacts. Do NOT use for running tests, choosing a
  test CLI, or adding implementation-incidental test code.
---

# Test Design (totto2727)

This skill defines a standalone QA-design workflow for the coding plugin. Its purpose is to make test coverage reviewable by humans **before** implementation starts: success criteria become observable test cases, and the branching structure becomes Mermaid diagrams whose leaves map to test-case IDs.

For concrete test implementation conventions, use the sibling [`test`](../test/SKILL.md) skill. This skill stays framework-agnostic unless the user explicitly asks to bind the design to a specific test framework.

## Outputs

Produce these artifacts together:

1. **`qa-design.md`** — test case table, coverage table, automated/manual rationale, and placement policy.
2. **`qa-flow.md`** — Mermaid flowcharts visualizing the branches covered by the test cases.

Use these bundled assets:

- [`templates/qa-design.md`](templates/qa-design.md)
- [`templates/qa-flow.md`](templates/qa-flow.md)
- [`references/qa-design.md`](references/qa-design.md)
- [`references/qa-flow.md`](references/qa-flow.md)

## Inputs

At minimum, read:

- The user's stated goal and success criteria.
- Any available intent/specification document.
- Any available design or architecture document.
- Project-specific testing constraints when they affect feasibility, while keeping the design artifact framework-agnostic.

If success criteria are implicit, first rewrite them as `SC-N` entries in observable terms. If a criterion cannot be observed or verified, stop and ask for clarification instead of inventing a test.

## Procedure

1. Assign success criterion IDs (`SC-1`, `SC-2`, ...).
2. Rewrite each criterion into observable behavior. Replace vague words like “fast”, “easy”, or “safe” with measurable or reviewable outcomes.
3. Decide the execution actor for each test case:
   - `automated` — reproducible by CI or a local test command; preferred when possible.
   - `ai-driven` — requires contextual browser/tool operation that an AI agent can perform and report.
   - `manual` — requires human judgment, physical operation, UAT, or subjective review.
4. Decide the verification style:
   - `assertion` — exact equality/state judgment.
   - `scenario` — sequential multi-step behavior.
   - `observation` — threshold, metric, count, latency, or trend judgment.
   - `inspection` — qualitative review such as UX, layout, logs, or document quality.
5. Create essential test cases (`TC-NNN`) for behaviors expressible at the spec/design level.
6. Leave implementation-driven cases (`TC-IMPL-NNN`) empty unless implementation details are already known; those are normally appended later when concrete code reveals defensive branches.
7. Create a coverage table mapping every `SC-N` to at least one `TC-NNN`.
8. Create `qa-flow.md` with one or more Mermaid `flowchart TD` diagrams. Every leaf must be a `TC-NNN`, `TC-IMPL-NNN`, or `skip: <reason>`.
9. Present both artifacts for human review. Do not replace the artifacts with a prose-only summary.

## Two-axis tagging rules

Every test case must have both axes filled.

| Axis  | Values                                                  |
| ----- | ------------------------------------------------------- |
| Actor | `automated` / `ai-driven` / `manual`                    |
| Style | `assertion` / `scenario` / `observation` / `inspection` |

Forbidden combination:

- `automated × inspection` — automation cannot perform subjective inspection without an explicit oracle.

Combinations requiring a note:

- `ai-driven × assertion`
- `manual × assertion`
- `manual × observation`

The note must explain why a more reproducible actor/style is not appropriate.

## Design decision guide

- Unit-style behavior usually maps to `automated × assertion`.
- Integration behavior usually maps to `automated × assertion` or `automated × scenario`.
- End-to-end behavior usually maps to `automated × scenario` when deterministic, or `ai-driven × scenario` when contextual operation is needed.
- Performance, counts, and thresholds map to `automated × observation` when measurable.
- UX, visual polish, and subjective document review map to `manual × inspection` unless a visual automation oracle is explicitly available.

## Exit criteria

- Every success criterion is covered by at least one essential test case.
- Any test case with `Target SC = (none)` has a mandatory reason.
- Every test case has valid Actor and Style values.
- `automated × inspection` is not used.
- Every Mermaid leaf is a test case ID or an explicit skip with rationale.
- The design is useful for a human reviewer without reading implementation code.

## What this skill does not cover

- Concrete test implementation patterns; use [`test`](../test/SKILL.md).
- Test command execution and CI verification.
- Test framework selection unless the user asks to adapt the design to a framework.
- Editing CI workflows.
