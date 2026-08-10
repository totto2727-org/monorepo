# QA Flow: {{title}}

- **Identifier:** {{identifier}}
- **Author:** {{author}}
- **Source:** `qa-design.md`
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}
- **Status:** {{status}} <!-- draft | approved -->

This document visualizes the test cases in `qa-design.md` as Mermaid flowcharts so coverage can be reviewed at a glance. Each leaf must be a test case ID or an explicit `skip` with rationale.

## Overview

{{overview}}

Introduce the structure of this file in 2-5 lines.

Examples:

- Split into three concerns: authentication, authorization, and notification delivery.
- Error handling is consolidated into the cross-cutting concerns section.
- Implementation-driven branches are listed separately because they come from library behavior.

---

## {{concern_1_title}}

Success criteria covered by this section: {{concern_1_sc_ids}}

```mermaid
flowchart TD
  Start([{{concern_1_start_label}}]) --> Q1{"{{concern_1_q1_label}}"}
  Q1 -->|true| TC_a[{{concern_1_tc_a}}]
  Q1 -->|false| TC_b[{{concern_1_tc_b}}]
```

---

## {{concern_2_title}}

Success criteria covered by this section: {{concern_2_sc_ids}}

```mermaid
flowchart TD
  Start([{{concern_2_start_label}}]) --> Q1{"{{concern_2_q1_label}}"}
  Q1 -->|admin| TC_x[{{concern_2_tc_x}}]
  Q1 -->|member| TC_y[{{concern_2_tc_y}}]
  Q1 -->|guest| Skip[skip: {{concern_2_skip_reason}}]
```

<!-- Add concern_3, concern_4, ... as needed. -->

---

## Cross-cutting concerns (optional)

Use this for error handling, logging, retries, cancellation, authorization fallback, or other branches that cut across several concerns. Delete if not needed.

```mermaid
flowchart TD
  Start([{{cross_start_label}}]) --> Q1{"{{cross_q1_label}}"}
  Q1 -->|...| TC_z[{{cross_tc_z}}]
```

---

## Implementation-driven branches (optional)

Use this for `TC-IMPL-NNN` cases that do not fit naturally into the existing flowcharts. Delete if not needed.

```mermaid
flowchart TD
  Start([{{impl_start_label}}]) --> Q1{"{{impl_q1_label}}"}
  Q1 -->|...| TC_impl[TC-IMPL-001: {{impl_tc_label}}]
```
