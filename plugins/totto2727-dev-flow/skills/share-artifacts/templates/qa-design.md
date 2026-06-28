# QA Design: {{title}}

- **Identifier:** {{identifier}}
- **Author:** {{qa_analyst_instance_id}}
- **Source:** owning execution system's intent specification and design artifact
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}
- **Status:** {{status}} <!-- draft | approved -->

This document is the **essential test design finalized by the owning execution system**. During implementation, the implementer appends "tests discovered during implementation". See `share-artifacts/references/qa-design.md` for authoring details.

## Overview

{{overview}}

A summary that drills the success criteria from the intent specification down to an observable form.

Examples:

- SC-1: When the user submits valid credentials to the login form, they receive a 200 response containing a JWT within 500 ms
- SC-2: When credentials are invalid, the system returns 401
- SC-3: After 5 failed login attempts, the IP is temporarily blocked for 15 minutes

## Rationale for automated vs. manual

{{automation_rationale}}

Building on the architectural decisions in the owning execution system's design artifact, write 1-3 paragraphs explaining the rationale for the choice of execution actor (automated / ai-driven / manual) for each test.

## Test file placement policy

{{file_placement_policy}}

Describe placement policy by category. Concrete file paths are finalized by the owning execution system during task planning or implementation.

Examples:

- `automated × assertion`: co-located with the source file (e.g. place `foo.test.ts` next to `foo.ts` in the same directory)
- `automated × scenario`: directly under `e2e/`
- `manual × inspection`: place the procedure document in the manual-test artifact location used by the owning execution system

## Essential test cases (TC-NNN)

Cases that verify behaviors expressible at the specification level. The qa-analyst designs the initial set in Step 4; in Step 6 the implementer appends "additional behavioral patterns" with continuing numbering.

| ID     | Target SC   | Expected behavior | Actor       | Style       | Pass criterion  | Why required (conditional) | Notes (optional) |
| ------ | ----------- | ----------------- | ----------- | ----------- | --------------- | -------------------------- | ---------------- |
| TC-001 | {{sc_id_1}} | {{behavior_1}}    | {{actor_1}} | {{style_1}} | {{criterion_1}} | -                          | -                |
| TC-002 | {{sc_id_2}} | {{behavior_2}}    | {{actor_2}} | {{style_2}} | {{criterion_2}} | -                          | -                |
| TC-003 | (none)      | {{behavior_3}}    | {{actor_3}} | {{style_3}} | {{criterion_3}} | {{reason_3}}               | -                |

<!-- Add TC-004, TC-005, ... as needed -->

### Enum value quick reference

- **Actor (`Actor` column):** `automated` | `ai-driven` | `manual`
- **Style (`Style` column):** `assertion` | `scenario` | `observation` | `inspection`
- **Forbidden combination:** `automated × inspection` (not allowed)
- **Combinations requiring notes (△):** `ai-driven × assertion`, `manual × assertion`, `manual × observation` — when used, the `Notes` column must contain the rationale

## Implementation-driven test cases (TC-IMPL-NNN)

Cases verifying defensive branches that arise only in the concrete implementation (libraries / frameworks / OS, etc.). Empty during Step 4; added by the implementer in Step 6 only when discovered.

| ID          | Target SC | Expected behavior   | Actor            | Style            | Pass criterion       | Why required (mandatory) | Notes (optional) |
| ----------- | --------- | ------------------- | ---------------- | ---------------- | -------------------- | ------------------------ | ---------------- |
| TC-IMPL-001 | (none)    | {{impl_behavior_1}} | {{impl_actor_1}} | {{impl_style_1}} | {{impl_criterion_1}} | {{impl_reason_1}}        | -                |

<!-- The implementer appends rows in Step 6 as needed. May remain empty in Step 4. -->

## Coverage table

A reverse lookup from success criterion to TC-ID. The Step 8 validator uses it to confirm coverage. Only essential test cases (TC-NNN) are in scope.

| SC ID | Corresponding TC-IDs | Notes |
| ----- | -------------------- | ----- |
| SC-1  | {{tc_for_sc_1}}      | -     |
| SC-2  | {{tc_for_sc_2}}      | -     |
| SC-3  | {{tc_for_sc_3}}      | -     |

<!-- Write one row per success criterion from the owning execution system's intent specification. If any criterion has zero matching TCs, return it to the execution system's test-design step. -->
