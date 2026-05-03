# QA Flow: {{title}}

- **Identifier:** {{identifier}}
- **Author:** {{qa_analyst_instance_id}}
- **Source:** `qa-design.md`
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}
- **Status:** {{status}} <!-- draft | approved -->

This document is a collection of figures that **visualize the test cases in `qa-design.md` as Mermaid flowcharts** so coverage can be confirmed at a glance. Drawing the branching structure of the tests in a form reviewers can survey at a glance reduces cognitive load. See `share-artifacts/references/qa-flow.md` for authoring details.

## Overview

{{overview}}

Introduce the structure of qa-flow.md in 2-5 lines.

Examples:

- Split into three concerns: authentication / authorization / order processing / notifications
- Error handling is consolidated into the "cross-cutting concerns" section
- Defensive branches that come from library specifications are listed separately under "implementation-driven branches"

---

## {{concern_1_title}}

Success criteria covered by this section: {{concern_1_sc_ids}}

```mermaid
flowchart TD
  Start([{{concern_1_start_label}}]) --> Q1{{{concern_1_q1_label}}}
  Q1 -->|true| TC_a[{{concern_1_tc_a}}]
  Q1 -->|false| TC_b[{{concern_1_tc_b}}]
```

---

## {{concern_2_title}}

Success criteria covered by this section: {{concern_2_sc_ids}}

```mermaid
flowchart TD
  Start([{{concern_2_start_label}}]) --> Q1{{{concern_2_q1_label}}}
  Q1 -->|admin| TC_x[{{concern_2_tc_x}}]
  Q1 -->|member| TC_y[{{concern_2_tc_y}}]
  Q1 -->|guest| Skip[skip: {{concern_2_skip_reason}}]
```

<!-- Add concern_3, concern_4, ... as needed -->

---

## Cross-cutting concerns (optional)

A section for cross-cutting concerns (error handling, logging, retries, etc.) drawn as a separate diagram. Delete if not needed.

```mermaid
flowchart TD
  Start([{{cross_start_label}}]) --> Q1{{{cross_q1_label}}}
  Q1 -->|...| TC_z[{{cross_tc_z}}]
```

---

## Implementation-driven branches (optional)

Consolidate `TC-IMPL-NNN` cases that do not fit naturally into the existing flowcharts in this section. Use it for branches discovered by the implementer in Step 6 that are independent enough that they cannot be folded into existing diagrams. May remain empty at the end of Step 4.

```mermaid
flowchart TD
  Start([{{impl_start_label}}]) --> Q1{{{impl_q1_label}}}
  Q1 -->|...| TC_impl[TC-IMPL-001: {{impl_tc_label}}]
```
