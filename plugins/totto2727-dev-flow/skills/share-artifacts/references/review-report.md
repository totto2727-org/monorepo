# Reference: How to write `review/<aspect>.md`

## Purpose

From a **viewpoint independent of the implementer**, focus on a single review aspect (one of the 6 aspects: `security` / `performance` / `readability` / `test-quality` / `api-design` / `holistic`) and verify quality. The `holistic` aspect exclusively covers overall consistency checks (Task Plan completion judgment / `design.md` consistency / outlook for fulfilling Intent Spec success criteria / early detection of obvious bugs), and the other aspects perform their own deep inspections.

**Top-priority design principle (overview-ability):** regardless of the presence of Rounds, ensure that a reader who opens the file **first sees, at a glance, "what was raised, what was fixed, and what was accepted"**. Splitting into chapters/sections by Round structure damages overview-ability, so Rounds are recorded only as metadata (table columns and trailing supplementary information) and not made the primary axis of chapter/section structure. When the same finding is re-evaluated across multiple Rounds, consolidate into a single row and leave only the latest state (do not duplicate it in another file or another section).

## Author / creation timing

- **Author:** `reviewer` Specialist (separate instances launched in parallel per aspect)
- **Step:** Step 7 (External Review)
- **Approval:** user approval required (0 Blockers / all Major resolved / Minor handling policy)

## File location

`docs/workflow/<identifier>/review/<aspect>.md`

`<aspect>` ∈ {`security`, `performance`, `readability`, `test-quality`, `api-design`, `holistic`} (+ project-specific additional aspects)

Strictly **1 aspect = 1 file**. Even if Rounds increase, do not create a separate file (e.g. `review/round2-<aspect>.md`) (it harms overview-ability).

## File structure

Each `review/<aspect>.md` consists of the following 4 sections:

1. **Meta header** (required)
2. **Findings list table** (required, the core of this file)
3. **Detail sections** (optional, only for findings that need them)
4. **Round history meta** (optional, supplementary information at the end of the file)

### 1. Meta header

Place the following as a bullet list at the top of the file:

- **Cycle:** the cycle `<identifier>`
- **Aspect:** aspect name and a short description
- **First reviewed:** date Round 1 was executed (YYYY-MM-DD)
- **Last updated:** date of the latest Round
- **Final Gate:** the current Gate verdict (`approved` / `needs_fix` / `blocked`)
- **Round count:** number of Rounds executed

For the `backward-compatibility` aspect, additionally record `SC-12 baseline:` (commit hash for verification).

### 2. Findings list table (the core of this file)

A table with 1 row = 1 finding. **Place near the top of the file** so the reader can survey the whole at minimal scrolling.

Minimum column structure:

| Column            | Content                                                                                                                                                              |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ID`              | Finding ID. Major as uppercase `M-1` / `M-2` …, Minor as lowercase `m-1` / `m-2` …, Info as `i-1` / `i-2` …, Blocker as `B-1` … (severity identifiable by ID prefix) |
| `Severity`        | `Blocker` / `Major` / `Minor` / `Info`                                                                                                                               |
| `Finding`         | A 1-2 sentence summary (details optionally moved to "Detail sections")                                                                                               |
| `Status`          | One of the "Status labels" below                                                                                                                                     |
| `Detected Round`  | 1, 2, ... — when the same finding is re-detected in multiple Rounds, record **only the first Round** (do not create duplicate rows)                                  |
| `Resolved commit` | For `fixed` / `partial`, the corresponding commit SHA (may be shortened); otherwise `-`                                                                              |
| `Notes`           | Supplementary information, excerpt of the corresponding commit message, reason for invalidation, basis for Retrospective carryover agreement, etc.                   |

#### Status labels

| Label            | Meaning                                                                                                      | Conditions for use                                                                               |
| ---------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ |
| `fixed`          | Fixed                                                                                                        | A corresponding commit exists, and is not re-detected in re-Rounds (commit SHA must be included) |
| `partial`        | Partially resolved, with remaining issues                                                                    | Describe remaining issues and whether they carry over to the next Round in `Notes`               |
| `pending`        | Unresolved, scheduled to be addressed in the next Round                                                      | Record the responsible task / additional task ID in `Notes`                                      |
| `accepted-as-is` | "Ignored / accepted" (= confirmed via user approval as Retrospective carryover agreement / no action needed) | Record the agreement date and approver in `Notes`                                                |
| `obsolete`       | Invalidated by a design change or premise change                                                             | Record the reason for invalidation in `Notes`                                                    |

With these labels, a reader who opens the file can grasp at a glance which findings were "addressed", "ignored (accepted)", and "carried over unresolved" without being conscious of the timeline.

### 3. Detail sections (optional)

For findings whose meaning is not conveyed by the table summary alone, individually describe code excerpts as evidence and details of recommended actions in the form `### M-1 detail: <short heading>`. You may place a `[detail](#m-1-detail-...)` link from the `Notes` column of the table.

For findings that do not need details (those for which the 1-2 sentence summary in the table is sufficient), do not create a detail section.

### 4. Round history meta (optional, end of file)

Leave the audit information of each Round in a table form. Place this at the end of the file as supplementary information referenced when needed, not in the "main flow" of the file.

| Column              | Content                                                                                     |
| ------------------- | ------------------------------------------------------------------------------------------- |
| `Round`             | 1, 2, ...                                                                                   |
| `Date`              | YYYY-MM-DD                                                                                  |
| `reviewer instance` | Reviewer instance ID launched or simple identifier (e.g. `reviewer (consistency, initial)`) |
| `Single-Round Gate` | The Round-only Gate verdict (`approved` / `needs_fix` / `blocked`)                          |

At the end of the file, leave a one-line summary like "Final Gate: `approved`. 0 Major / Blocker, N `accepted-as-is`".

## Severity decision criteria

| Severity    | Response                                                                                                                                                                        |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Blocker** | Mandatory return to Step 6 (Task Plan unimplemented / Intent Spec success criterion unmet / obvious bug). Step 7 cannot proceed                                                 |
| **Major**   | Confirm the resolution policy (return to Step 6 / Retrospective carryover) by user judgment. To pass through Step 7, all Majors must be resolved as `fixed` or `accepted-as-is` |
| **Minor**   | Recordable for progress (kept as material for the Retrospective)                                                                                                                |
| **Info**    | Notes / consistency check results / audit memos on the aspect. Status is usually a non-label form like `(consistency check only)`                                               |

The `High / Medium / Low` labels used in old documents are deprecated. If you see old labels in transitional cycles being resumed, read them according to the following mapping based on content:

- `High` → `Blocker` or `Major` (Blocker if release-blocking)
- `Medium` → `Major`
- `Low` → `Minor`

## Per-aspect evaluation items

The focus items per aspect are described in the "Per-aspect review guidelines" section of `specialist-reviewer/SKILL.md`. This document (reference) defines only the **structural specification** of this file; the **evaluation guidelines per aspect** are delegated to the specialist side.

## Quality criteria

| Good                                                                                                     | Bad                                                                                    |
| -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| The findings list table is near the top of the file, and the whole can be grasped in 1 screen on opening | The table is at the end of the file, and a long preface must be read to reach the list |
| The same finding is consolidated in 1 row, reflecting only the final state across multiple Rounds        | The same finding is duplicated in separate Round 1 / Round 2 sections                  |
| `Notes` for `accepted-as-is` records the agreement date / approver / basis                               | Just "Retrospective carryover" with unclear background                                 |
| `fixed` rows have a SHA in the resolved commit column                                                    | `fixed` but no corresponding commit can be identified                                  |
| Composed only of findings specific to the aspect (others linked by reference)                            | Mixes findings from multiple aspects in one file                                       |

## Related artifacts

- **Inputs:** all diffs from Step 6, `design.md`, `intent-spec.md`, `task-plan.md`, `TODO.md`
- **Template:** `share-artifacts/templates/review-report.md`
- **Linkage:** Blocker / unresolved Major reactivates Step 6, with the `re_activations` counter recorded in `TODO.md`
- **Linkage to Retrospective:** Minor findings and `accepted-as-is` findings become material for the Retrospective
- **Parallelism:** independent per aspect. Direct communication with other reviewers happens through Main
