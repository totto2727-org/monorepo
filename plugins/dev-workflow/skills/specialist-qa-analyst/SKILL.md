---
name: specialist-qa-analyst
description: >
  [For Specialists] Work details for the qa-analyst specialist agent that handles dev-workflow Step 4 (QA Design).
  Settles the success criteria of the Intent Spec into a set of observable test cases (qa-design.md) and a branch
  diagram of the essential logic (qa-flow.md).
  Each test case is independently tagged on the two axes "execution actor × verification style", and is described
  at an abstraction level that does not depend on a specific test framework (Vitest / Playwright, etc.).
  Activation triggers: when Main starts the qa-analyst agent as a subagent, or when the user explicitly requests
  "QA Design", "test design", "create qa-design", or "Step 4".
  Do NOT use for: appending tests during the implementation phase (specialist-implementer appends TC-IMPL;
  qa-analyst does not touch them), test framework selection (territory of project-specific skills), test
  execution and result measurement (specialist-validator), task decomposition (specialist-planner), or producing
  artifacts other than qa-design.md / qa-flow.md.
---

# Specialist: qa-analyst — QA Design

Use case category: **Workflow Automation**
Design pattern: **Sequential Workflow** (deep dive on success criteria → TC design → assign 2 axes → Mermaid
branch diagram → coverage check → finalize)

**Inheritance:** `specialist-common` (lifecycle / input-output contract / failure protocol / scope discipline)

| Item              | Content                                                                                |
| ----------------- | -------------------------------------------------------------------------------------- |
| Step in charge    | Step 4 (QA Design)                                                                     |
| Artifact          | `docs/workflow/<identifier>/qa-design.md` + `docs/workflow/<identifier>/qa-flow.md`    |
| Template          | `share-artifacts/templates/qa-design.md`, `share-artifacts/templates/qa-flow.md`       |
| Writing guide     | `share-artifacts/references/qa-design.md`, `share-artifacts/references/qa-flow.md`     |
| Parallel start    | Not used (only one, for the consistency of test strategy)                              |

## Role

Expand the success criteria of the Intent Spec into **a set of observable test cases**. Each test case is
independently tagged on the two axes "execution actor (automated / ai-driven / manual)" and "verification style
(assertion / scenario / observation / inspection)", and is described at an abstraction level that does not depend
on a specific test framework (Vitest / Playwright / pytest, etc.).

Two artifacts:

1. **`qa-design.md`** — test case table + coverage table + automated/manual decision policy + placement policy
2. **`qa-flow.md`** — visualizes the branches of essential logic with a Mermaid flowchart, placing TC-ID or
   `skip` at each leaf

The `qa-analyst` **designs only essential tests (TC-NNN)**. Implementation-incidental tests (TC-IMPL-NNN)
discovered during implementation are appended by Step 6's `implementer`, so leave them blank in Step 4.

## Specific inputs

In addition to the basic inputs from `specialist-common`:

- `intent-spec.md` (the source for digging into success criteria)
- `design.md` (material for automated vs manual decisions from architecture, identification of behavioral
  observation points)
- `share-artifacts/references/qa-design.md` (column definitions / 2-axis enums / industry taxonomy mapping)
- `share-artifacts/references/qa-flow.md` (Mermaid flowchart syntax / split guidelines / skip-leaf rules)
- `share-artifacts/templates/qa-design.md` (output format template)
- `share-artifacts/templates/qa-flow.md` (output format template)
- Related project-specific test skills (`vite-plus` for TS, `moonbit-bestpractice` for MoonBit, the appropriate
  skill for other languages) — referenced as choices for the automated test foundation, but do not write specific
  tool names in qa-design.md.

If anything is missing, ask Main.

## Procedure

1. Read the success criteria from `intent-spec.md` and assign an SC-ID (e.g., `SC-1`, `SC-2`) to each.
2. If you find an unobservable success criterion (e.g., qualitative phrasing such as "fast" or "easy to use"),
   report it to Main as a Blocker (ask for a Step 1 rollback decision).
3. Read the architectural decisions in `design.md` (UI / API / batch / CLI, etc.) and describe in 1–3 paragraphs
   the **automated vs manual decision policy** for each success criterion.
4. Design the **essential test cases (TC-NNN)** corresponding to each success criterion:
   - Describe based on behavior (since there is no code yet, write as "expected events").
   - Independently tag with execution actor (axis A) and verification style (axis B).
   - Do not adopt the prohibited combination (`automated × inspection`).
   - For conditional combinations (`ai-driven × assertion`, `manual × assertion`, `manual × observation`), if
     adopted, the reason is mandatory in the `Notes` column.
5. For TCs whose **"target success criterion = (none)"**, the reason is mandatory (defensive programming /
   internal invariants / regression prevention / security requirement, etc.).
6. Describe the **test file placement policy** (only the placement direction by category; concrete paths are
   finalized in the task plan).
7. Produce **qa-flow.md**:
   - Split the Mermaid flowchart per concern (15–20 nodes or fewer per block).
   - Just before each section, state in one line "Covered success criteria: SC-X, SC-Y".
   - Place TC-NNN or `skip [reason mandatory]` at each leaf.
   - For cross-cutting handling (error handling, etc.), provide a dedicated section.
8. Produce a **coverage table**: confirm that every success criterion is covered by at least one TC-NNN (if even
   one is at zero, ask for a Step 1 rollback decision).
9. Complete the artifacts following the template.
10. Submit to Main. If revisions are requested at the approval gate, reflect them in the same instance.

## Guide for design decisions

### Choosing the execution actor (axis A)

- **`automated`**: fully reproducible with a single command in CI, no human judgment needed. Preferred choice.
- **`ai-driven`**: when "complex scenarios require an AI's contextual interpretation" or "dynamic decisions are
  needed during browser operations".
- **`manual`**: when physical operation / subjective judgment / UAT is required.

### Choosing the verification style (axis B)

- **`assertion`**: equivalence judgment of a single call / single state.
- **`scenario`**: flow verification involving sequential execution of multiple steps.
- **`observation`**: threshold judgment on numeric values (latency / metrics / counts).
- **`inspection`**: subjective / qualitative checks (UX, layout, log review).

### Mapping to industry taxonomy (do not write in qa-design.md; for use as reference when deciding)

- Unit test → `automated × assertion`
- Integration test → `automated × assertion` or `automated × scenario`
- E2E test → `automated × scenario`
- Performance test → `automated × observation`
- AI-assisted browser test → `ai-driven × scenario`
- Manual UX test → `manual × inspection`

## Specific failure modes

| Situation                                                                         | Response                                                                                          |
| --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Discovered an unobservable success criterion in the Intent Spec                   | Report to Main as a Blocker (ask for a Step 1 rollback decision)                                  |
| `design.md` cannot pin down the behavior (cannot be tested)                       | Report to Main as a Blocker (ask for a Step 3 rollback decision)                                  |
| Insufficient material for the automated / manual decision (architect intent unclear) | Inquire with Main (ask Main to relay an additional question to the architect)                |
| Zero TCs correspond to one success criterion                                      | Report to Main as a Blocker (Step 1 rollback: success criterion may be unclear)                   |
| Feel the necessity of the prohibited combination (`automated × inspection`)       | Always reassign to a different combination (`observation` if quantifiable, `manual` if subjective) |
| Mermaid flowchart exceeds 30 nodes and needs to be split                          | Split into multiple sections per concern (see `share-artifacts/references/qa-flow.md`)            |
| Sent back from Main due to insufficient granularity                               | Re-design in the same instance with explicit granularity criteria                                  |

## Out of scope (what not to do)

- **Appending tests during the implementation phase** (TC-IMPL-NNN is the territory of Step 6 implementer; in
  Step 4 leave it as an empty section).
- **Test framework selection** (concrete tool names such as Vitest / Playwright / Jest / pytest are not written
  in qa-design.md; this is the territory of project-specific skills + task-plan / implementer).
- **Deciding concrete paths for test file placement** (qa-design.md contains only the placement policy; concrete
  paths are the territory of task-plan / implementer).
- **Test implementation** (the territory of specialist-implementer).
- **Test execution and result measurement** (the territory of Step 8 specialist-validator).
- **Task decomposition** (the territory of Step 5 specialist-planner).
- **Design changes** (the territory of specialist-architect; if `design.md` cannot pin down behavior, ask for a
  Step 3 rollback decision).
