# QA Design: {{title}}

- **Identifier:** {{identifier}}
- **Author:** {{author}}
- **Source:** {{source_documents}}
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}
- **Status:** {{status}} <!-- draft | approved -->

This document defines the **test design for human review before implementation**. It translates success criteria into observable test cases and records why each case should be automated, AI-driven, or manual.

## Overview

{{overview}}

Summarize how the source success criteria are rewritten into observable behavior.

Examples:

- SC-1: When the user submits valid credentials, the API returns 200 and sets a session cookie.
- SC-2: When credentials are invalid, the API returns 401 without revealing which field failed.
- SC-3: After 5 failed login attempts, further attempts from the same IP are blocked for 15 minutes.

## Rationale for automated vs. manual

{{automation_rationale}}

Write 1-3 paragraphs explaining the rationale for the chosen execution actors (`automated` / `ai-driven` / `manual`). Base this on observability, determinism, cost, and whether human judgment is required.

## Test file placement policy

{{file_placement_policy}}

Describe placement policy by category. Concrete file paths may be finalized during implementation.

Examples:

- `automated × assertion`: co-located with the source file, such as `foo.test.ts` next to `foo.ts`.
- `automated × scenario`: under an integration or e2e test directory.
- `manual × inspection`: under `docs/test-design/{{identifier}}/manual-tests/<TC-ID>.md`.

## Essential test cases (TC-NNN)

Cases that verify behaviors expressible at the specification/design level.

| ID     | Target SC   | Expected behavior | Actor       | Style       | Pass criterion  | Why required (conditional) | Notes (optional) |
| ------ | ----------- | ----------------- | ----------- | ----------- | --------------- | -------------------------- | ---------------- |
| TC-001 | {{sc_id_1}} | {{behavior_1}}    | {{actor_1}} | {{style_1}} | {{criterion_1}} | -                          | -                |
| TC-002 | {{sc_id_2}} | {{behavior_2}}    | {{actor_2}} | {{style_2}} | {{criterion_2}} | -                          | -                |
| TC-003 | (none)      | {{behavior_3}}    | {{actor_3}} | {{style_3}} | {{criterion_3}} | {{reason_3}}               | -                |

<!-- Add TC-004, TC-005, ... as needed. -->

### Enum value quick reference

- **Actor (`Actor` column):** `automated` | `ai-driven` | `manual`
- **Style (`Style` column):** `assertion` | `scenario` | `observation` | `inspection`
- **Forbidden combination:** `automated × inspection`
- **Combinations requiring notes:** `ai-driven × assertion`, `manual × assertion`, `manual × observation`

## Implementation-driven test cases (TC-IMPL-NNN)

Cases verifying defensive branches that arise only in the concrete implementation, such as library, framework, OS, serialization, or adapter behavior. Keep this section empty during pure design unless implementation details are already known.

| ID          | Target SC | Expected behavior   | Actor            | Style            | Pass criterion       | Why required (mandatory) | Notes (optional) |
| ----------- | --------- | ------------------- | ---------------- | ---------------- | -------------------- | ------------------------ | ---------------- |
| TC-IMPL-001 | (none)    | {{impl_behavior_1}} | {{impl_actor_1}} | {{impl_style_1}} | {{impl_criterion_1}} | {{impl_reason_1}}        | -                |

<!-- Append rows as implementation details are discovered. May remain empty after initial design. -->

## Coverage table

A reverse lookup from success criteria to test case IDs. Only essential test cases (`TC-NNN`) are required for success-criterion coverage.

| SC ID | Corresponding TC-IDs | Notes |
| ----- | -------------------- | ----- |
| SC-1  | {{tc_for_sc_1}}      | -     |
| SC-2  | {{tc_for_sc_2}}      | -     |
| SC-3  | {{tc_for_sc_3}}      | -     |

<!-- Write one row per success criterion. If any criterion has zero matching TCs, clarify the criterion or revise the test design. -->
