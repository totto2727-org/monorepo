# Reference: How to write `qa-design.md`

## Purpose

Expand success criteria into **observable test cases**. Each test case is tagged on two independent axes: execution actor and verification style. The document must stay at a test-design level: it can mention placement policy and observability constraints, but it should not depend on a specific framework such as Vitest, Playwright, pytest, or MoonBit unless the user explicitly asks for framework binding.

## File location

Use the location that matches the project. Recommended default:

```text
docs/test-design/<identifier>/qa-design.md
```

When maintaining an existing workflow directory, place it beside the related planning/design documents instead.

## Section structure

```text
1. # QA Design: <title>
2. ## Overview
3. ## Rationale for automated vs. manual
4. ## Test file placement policy
5. ## Essential test cases (TC-NNN)
6. ## Implementation-driven test cases (TC-IMPL-NNN)
7. ## Coverage table
```

## Writing rules

### 1. Overview

Transcribe and deepen the success criteria. Qualitative requirements must become observable statements. Examples:

- “fast” -> “p95 latency below 200 ms for scenario X”.
- “easy to use” -> “a first-time user can complete flow X without opening help”.
- “safe” -> “invalid input is rejected before persistence and no partial state remains”.

Assign IDs (`SC-1`, `SC-2`, ...) so later tables can reference them.

### 2. Rationale for automated vs. manual

Explain in 1-3 paragraphs why each behavior should be verified by `automated`, `ai-driven`, or `manual` execution.

Useful criteria:

- Determinism and reproducibility.
- Whether a single command can run it in CI.
- Whether contextual browser/tool operation is needed.
- Whether subjective human judgment is required.
- Cost of maintaining the test versus risk of regression.

### 3. Test file placement policy

Describe placement by category, not necessarily final paths.

Examples:

- `automated × assertion` -> co-located with the source file.
- `automated × scenario` -> integration/e2e directory.
- `manual × inspection` -> human-readable procedure under `docs/test-design/<id>/manual-tests/<TC-ID>.md`.

### 4. Essential test cases (TC-NNN)

Essential cases verify behaviors expressible at the specification/design level.

Required columns:

| Column              | Content                             | Example                                   |
| ------------------- | ----------------------------------- | ----------------------------------------- |
| `ID`                | Test case identifier, zero-padded   | `TC-001`                                  |
| `Target SC`         | Success criterion ID or `(none)`    | `SC-1`                                    |
| `Expected behavior` | Observable event                    | `Invalid credentials return 401`          |
| `Actor`             | Execution actor enum                | `automated`                               |
| `Style`             | Verification style enum             | `assertion`                               |
| `Pass criterion`    | Concrete pass condition             | `status is 401 and no session is created` |
| `Why required`      | Mandatory when `Target SC = (none)` | `Regression prevention`                   |
| `Notes`             | Conditional rationale or caveats    | `manual because UX judgment is required`  |

Typical reasons for `Target SC = (none)`:

- Defensive programming.
- Internal invariants.
- Regression prevention.
- Security requirements not stated explicitly in the success criteria.

### 5. Two-axis enum rules

Actor values:

- `automated` — fully reproducible with a command or CI.
- `ai-driven` — requires contextual AI operation and reporting.
- `manual` — requires human judgment, physical operation, UAT, or subjective review.

Style values:

- `assertion` — exact equality or state judgment.
- `scenario` — sequential multi-step flow.
- `observation` — threshold, metric, latency, count, or trend judgment.
- `inspection` — subjective qualitative review.

Forbidden:

- `automated × inspection`.

Requires note:

- `ai-driven × assertion`.
- `manual × assertion`.
- `manual × observation`.

### 6. Implementation-driven test cases (TC-IMPL-NNN)

Use this section for defensive branches discovered only after concrete implementation choices are known. It may remain empty in initial design.

Examples:

- Library-specific parse failures.
- Adapter boundary behavior.
- OS/filesystem differences.
- Serialization edge cases.

### 7. Coverage table

Map every `SC-N` to at least one `TC-NNN`. If any row has no test case, clarify the success criterion or revise the design before implementation.

## Review checklist

- Every success criterion has coverage.
- Every `Target SC = (none)` case has a reason.
- Every actor/style combination is valid.
- Conditional combinations have notes.
- The design is understandable without reading implementation code.
