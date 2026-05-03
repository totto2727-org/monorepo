# Task Plan: {{title}}

- **Identifier:** {{identifier}}
- **Author:** {{planner_instance_id}}
- **Source:** `design.md`
- **Created at:** {{created_at}}
- **Status:** {{status}} <!-- draft | approved -->

This document is the **immutable plan finalized in Step 5**. Task state tracking during Steps 6-7 happens in `TODO.md`.

## Premises

- Tasks are decomposed based on the component breakdown, key types, and API design from the Design Document
- One task = one `implementer` can complete it
- Tasks that can be executed in parallel are made explicit

## Task list

### T1: {{task_1_title}}

- **Summary:** {{task_1_summary}}
- **Artifact:** {{task_1_artifact}} <!-- files to be added / modified / committed -->
- **Dependencies:** {{task_1_dependencies}} <!-- none, or T<n>, T<m> -->
- **Parallelizable:** {{task_1_parallelizable}} <!-- yes | no (whether it can be launched concurrently with other tasks) -->
- **Estimated size:** {{task_1_estimate}} <!-- S | M | L, etc., per project convention -->
- **Test cases covered:** {{task_1_covered_test_cases}} <!-- Optional. List of TC-NNN from qa-design.md (e.g. TC-001, TC-005). May be left blank; in Step 6 the implementer references qa-design.md directly. -->
- **Design document references:** {{task_1_design_ref}}

### T2: {{task_2_title}}

- **Summary:** {{task_2_summary}}
- **Artifact:** {{task_2_artifact}}
- **Dependencies:** {{task_2_dependencies}}
- **Parallelizable:** {{task_2_parallelizable}}
- **Estimated size:** {{task_2_estimate}}
- **Test cases covered:** {{task_2_covered_test_cases}}
- **Design document references:** {{task_2_design_ref}}

<!-- Add T3, T4, ... as needed -->

## Dependency graph

```mermaid
{{dependency_graph}}
```

Example:

```
graph LR
  T1 --> T3
  T2 --> T3
  T3 --> T4
  T3 --> T5
```

## Parallelizable groups

The unit of parallel launching that Main consults during Step 6.

- **Wave 1 (root):** {{wave_1}} <!-- e.g. T1, T2 -->
- **Wave 2:** {{wave_2}} <!-- e.g. T3 (after T1 and T2 complete) -->
- **Wave 3:** {{wave_3}} <!-- e.g. T4, T5 (after T3 completes; can run in parallel) -->

## Risks / anticipated Blockers

{{risks}}

- {{risk_1}}
- {{risk_2}}
