# Review Report: {{aspect_title}}

- **Cycle:** {{identifier}}
- **Aspect:** {{aspect}} <!-- security | performance | readability | test-quality | api-design | holistic | etc. -->
- **First reviewed:** {{first_reviewed_date}} <!-- YYYY-MM-DD (Round 1) -->
- **Last updated:** {{last_updated_date}} <!-- YYYY-MM-DD (final Round) -->
- **Final Gate:** {{final_gate}} <!-- approved | needs_fix | blocked -->
- **Round count:** {{round_count}}
<!-- For the backward-compatibility aspect, also add: - **SC-12 baseline:** {{baseline_commit}} -->

## Findings list

| ID  | Severity | Finding             | State               | First Round       | Resolution commit | Notes       |
| --- | -------- | ------------------- | ------------------- | ----------------- | ----------------- | ----------- |
| M-1 | Major    | {{finding_1_brief}} | {{state_1}}         | {{first_round_1}} | {{commit_1}}      | {{notes_1}} |
| m-2 | Minor    | {{finding_2_brief}} | {{state_2}}         | {{first_round_2}} | {{commit_2}}      | {{notes_2}} |
| i-3 | Info     | {{finding_3_brief}} | (consistency check) | {{first_round_3}} | -                 | {{notes_3}} |

<!--
State labels (pick one):
  fixed         : resolved (always include the commit SHA)
  partial       : partially resolved, work remaining (write details in Notes)
  pending       : unresolved, will be addressed in the next Round (write the responsible task in Notes)
  accepted-as-is: agreed by the user to defer to Retrospective / no action required (write the agreement date in Notes)
  obsolete      : invalidated by a design / premise change (write the reason in Notes)

ID prefix: B-N (Blocker) / M-N (Major) / m-N (Minor) / i-N (Info)
Consolidate duplicate findings (re-detected in multiple Rounds) into a single row, recording only the first Round in which the finding appeared.
-->

## Detailed sections

<!--
Write here only the findings whose impact cannot be conveyed by the table summary (1-2 sentences).
Do not write findings here that are sufficiently captured by the Notes column of the table.
Linking option: from the Notes column you may link with `[detail](#m-1-detail-...)`.
-->

### M-1 detail: {{detail_1_heading}}

{{detail_1_body}}

## Round history metadata

<!--
Auxiliary information for audit purposes. Not the main thread of this file, so it is placed at the end.
Read this only when the reader needs to confirm "who judged what and when".
-->

| Round | Date             | Reviewer instance    | Round-only Gate  |
| ----- | ---------------- | -------------------- | ---------------- |
| 1     | {{round_1_date}} | {{round_1_reviewer}} | {{round_1_gate}} |
| 2     | {{round_2_date}} | {{round_2_reviewer}} | {{round_2_gate}} |

Final Gate: `{{final_gate}}`. {{open_critical_count}} Major / Blocker findings open, {{accepted_count}} `accepted-as-is`.

<!--
Authoring guide: share-artifacts/references/review-report.md
Detailed state-label semantics and per-aspect emphasis are delegated to specialist-reviewer/SKILL.md.
-->
