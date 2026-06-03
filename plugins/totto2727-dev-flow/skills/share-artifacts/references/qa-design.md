# Reference: How to write `qa-design.md`

## Purpose

Expand the success criteria from the owning execution system's intent specification into **a set of observable test cases**. Each test case is independently tagged with the two axes "execution agent" and "verification style", and written at an abstraction level that does not depend on a specific test framework (Vitest / Playwright / pytest etc.). The owning execution system uses this document during implementation and validation.

## Author / creation timing

- **Author:** the owning execution system's QA/test-design role
- **Updater:** the implementation role, appending "tests discovered during implementation"
- **Approval:** follows the owning execution system's gate rules

## File location

Storage path is selected by the owning execution system. This plugin retains only the format reference.

## Section structure

```text
1. # qa-design (title)
2. ## Overview (deepens success criteria into observable form)
3. ## Auto vs. manual decision policy (rationale from architecture and design)
4. ## Test file placement policy (placement policy per category; concrete paths are confirmed by the owning execution system)
5. ## Essential test cases (TC-NNN: verifies behaviors expressible at the spec level)
6. ## Implementation-detail test cases (TC-IMPL-NNN: verifies defensive branches that arise only with concrete implementation)
7. ## Coverage table (success criteria → TC-ID reverse lookup, used in Validation)
```

## How to write each section

### 1. Overview

**Transcribe and deepen** the success criteria from the owning execution system's intent specification as-is. Rewrite qualitative descriptions like "fast" into observable forms like "p95 < 200ms in a specific scenario". The rewritten result is finalized according to that system's QA gate.

Assign IDs to success criteria (e.g. `SC-1`, `SC-2`) so they can be referenced in the subsequent test case tables.

### 2. Auto vs. manual decision policy

Based on the architectural decisions in the owning execution system's design artifact, describe in 1-3 paragraphs the rationale for selecting the "execution agent" (automated / ai-driven / manual) for each test. Examples:

- "Visual confirmation of the front-end UI is more reliably judged by the human eye, so `manual × inspection`"
- "Backend API response verification is reproducible by an automated test runner, so `automated × assertion`"
- "Reproducing complex user scenarios can be substituted by an AI agent's browser operations: `ai-driven × scenario`"

### 3. Test file placement policy

Describe **only the placement policy per category**. Concrete file paths are decided by the owning execution system during task planning or implementation.

Examples:

- `automated × assertion` tests → co-located with the source file (e.g. `foo.ts` and `foo.test.ts` in the same directory)
- `automated × scenario` tests → directly under `e2e/`
- `manual × inspection` instruction documents → the manual-test artifact location used by the owning execution system

### 4. Essential test cases (TC-NNN)

Cases that verify behaviors expressible at the specification and design level. Describe in **a Markdown table**.

#### Required columns (6 columns)

| Column               | Content                                                        | Example values                                                         |
| -------------------- | -------------------------------------------------------------- | ---------------------------------------------------------------------- |
| `ID`                 | Test case identifier (3-digit zero-padded)                     | `TC-001`                                                               |
| `Target SC`          | Success criterion ID from the intent specification or `(none)` | `SC-1` / `(none)`                                                      |
| `Expected behavior`  | Stated as an observable event (no code yet, so behavior-based) | `When a User submits valid credentials to the login form, returns 200` |
| `Execution agent`    | Axis A: enum                                                   | `automated` / `ai-driven` / `manual`                                   |
| `Verification style` | Axis B: enum                                                   | `assertion` / `scenario` / `observation` / `inspection`                |
| `Pass criteria`      | Concrete description of pass conditions                        | `HTTP status is 200 and JWT is returned via Set-Cookie`                |

#### Conditionally required column (1 column)

| Column                | Content                    | When applicable                    |
| --------------------- | -------------------------- | ---------------------------------- |
| `Reason it is needed` | Why this test is necessary | Required when `Target SC = (none)` |

Typical examples of "Target SC = (none)":

- Defensive programming (throwing on invalid arguments)
- Verifying internal invariants (cache integrity)
- Regression prevention (preventing recurrence of past bugs)
- Security requirements (necessary but not explicit in the intent specification)

→ If "Reason it is needed" is empty, **send back at the Step 4 review**.

#### Optional columns

- `Notes` (rationale for adopting △ combinations / explanation of placement-policy deviations / others)
- `Placement candidate` (placement hint; concrete paths confirmed in task-plan)
- `Assigned implementer` (filled in Step 6, empty in Step 4)
- `Implementation status` (filled in Step 8: `pending` / `implemented` / `passed` / `failed`)

#### Numbering rules

- In Step 4, qa-analyst assigns sequential numbers from `TC-001`
- If implementer discovers "additional behavior patterns" in Step 6, **continue sequential numbering of `TC-NNN`** (append in this section). For example, if Step 4 ended at TC-001 to TC-020, Step 6 additions start from TC-021
- **Do not reuse IDs** even after deletion (to avoid confusion)

### 5. Implementation-detail test cases (TC-IMPL-NNN)

Cases that verify **defensive branches that arise only with concrete implementation** (libraries / frameworks / OS, etc.).

- Empty in Step 4 (qa-analyst designs only essential tests; does not foresee implementation details)
- Append only when discovered by implementer in Step 6
- Column structure is the same as essential tests (but `Target SC` is usually `(none)` and `Reason it is needed` is required)
- **Numbering:** sequential from `TC-IMPL-001`. Independent from essential test numbering (do not mix)

#### Distinguishing from essential tests

| Essential test (TC-NNN)                                                | Implementation-detail test (TC-IMPL-NNN)                                         |
| ---------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| Expressible at the specification and design level                      | Arises only with the behavior of a specific library / framework / OS             |
| Same test required even if reimplemented in another language / library | Not needed in another language / library, or becomes a different defensive test  |
| Example: "Unauthenticated User returns 401"                            | Example: "Defensive handling for the case where the library used returns `null`" |

When in doubt, report to Main as a Blocker (common to qa-analyst / implementer).

### 6. Coverage table

A reverse-lookup table from success criteria → TC-ID. Used by the Step 8 validator to confirm coverage.

Example:

| SC ID | Test case IDs          | Notes |
| ----- | ---------------------- | ----- |
| SC-1  | TC-001, TC-005         |       |
| SC-2  | TC-002, TC-003, TC-008 |       |
| SC-3  | TC-010                 |       |
| ...   | ...                    |       |

- **Only essential tests (TC-NNN) are subject**. TC-IMPL-NNN does not appear since they have no SC mapping
- If the count of TCs corresponding to an SC is 0, **roll back to Step 4** (test design omission)

## The 2-axis enum of verification means

### Axis A: Execution agent (3 values)

| Value       | Meaning                                           | Anticipated concrete tools (not written in qa-design.md)    |
| ----------- | ------------------------------------------------- | ----------------------------------------------------------- |
| `automated` | Test runner / script executes fully automatically | Vitest, Jest, pytest, go test, etc.                         |
| `ai-driven` | An AI agent executes interactively                | Claude's browser operations, AI-driven CLI execution        |
| `manual`    | A human operates and confirms manually            | Manual visual confirmation based on instructions, UAT, etc. |

### Axis B: Verification style (4 values)

| Value         | Meaning                                                        | Industry mapping                              |
| ------------- | -------------------------------------------------------------- | --------------------------------------------- |
| `assertion`   | Equality judgment of expected and actual values                | TDD, Property-based testing, snapshot, etc.   |
| `scenario`    | Verification of the result of a sequence of operations         | BDD, E2E testing, smoke test, etc.            |
| `observation` | Observation of values / logs / metrics with threshold judgment | Performance testing, observability test, etc. |
| `inspection`  | Subjective / qualitative confirmation                          | Exploratory testing, manual UX testing, etc.  |

### Validity of combinations (12 cells)

| Execution agent \ Verification style | `assertion`                        | `scenario`              | `observation`                                                     | `inspection`                                          |
| ------------------------------------ | ---------------------------------- | ----------------------- | ----------------------------------------------------------------- | ----------------------------------------------------- |
| `automated`                          | ✓ Unit tests etc. (most typical)   | ✓ E2E scripts           | ✓ Metric measurement + threshold                                  | ✗ **Forbidden combination** (essential contradiction) |
| `ai-driven`                          | △ Excessive (rationale required)   | ✓ AI browser operations | ✓ AI log analysis                                                 | ✓ AI-based UX evaluation                              |
| `manual`                             | △ Inefficient (rationale required) | ✓ Manual scenarios      | △ Measurement is recommended to be automated (rationale required) | ✓ Visual confirmation                                 |

- **✓**: Recommended combination
- **△**: Conditionally adoptable, rationale required in `Notes` column
- **✗**: Forbidden combination (`automated × inspection`). If automation of subjective judgment is possible, treat it as `observation` (quantification)

### Mapping to industry taxonomy

| Industry category         | Expression in this 2-axis system                  |
| ------------------------- | ------------------------------------------------- |
| Unit test (TDD)           | `automated × assertion`                           |
| Integration test          | `automated × assertion` or `automated × scenario` |
| E2E test (Selenium etc.)  | `automated × scenario`                            |
| BDD (Cucumber etc.)       | `automated × scenario`                            |
| Performance test          | `automated × observation`                         |
| Security scan (SAST/DAST) | `automated × observation`                         |
| Manual UX test            | `manual × inspection`                             |
| AI-assisted browser test  | `ai-driven × scenario`                            |
| AI-driven code review     | `ai-driven × inspection`                          |
| Smoke test                | `automated × scenario` (lightweight)              |

## Quality criteria

| Good                                                                 | Bad                                                                                |
| -------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Every success criterion is covered by at least one TC                | Empty rows in the coverage table (0 TCs for an SC)                                 |
| "Reason it is needed" is filled in for cases with Target SC = (none) | "Reason it is needed" is empty                                                     |
| Every TC has observable pass criteria (HTTP 200 / p95 < 200ms etc.)  | Vague expressions like "works correctly"                                           |
| No `automated × inspection` combinations                             | Forbidden combinations are used                                                    |
| △ combinations have the rationale recorded in `Notes`                | △ adopted without rationale                                                        |
| TC-NNN and TC-IMPL-NNN are numbered independently                    | Numbers are mixed (e.g. TC-001 and TC-IMPL-001 used as if different despite usage) |

## Related artifacts

- **Inputs:** owning execution system's intent specification (success criteria) and design artifact (architectural decisions = basis for auto/manual)
- **Output destinations:** owning execution system's task plan (optional TC-ID linkage), code, and validation artifacts
- **Linkage:** `qa-flow.md` (references TC-IDs of this table as leaves of the Mermaid flowchart, illustrating all TC-NNN / TC-IMPL-NNN)
