# Retrospective: {{identifier}}

- **Identifier:** {{identifier}}
- **Writer:** {{retrospective_writer_instance_id}}
- **Created at:** {{created_at}}
- **Cycle started at:** {{cycle_started_at}}
- **Cycle completed at:** {{cycle_completed_at}}
- **Duration:** {{duration}}

## Cycle overview

{{cycle_summary}}

Describe in 1-3 paragraphs what this cycle achieved and how it answered the purpose stated in the Intent Spec.

## What went well (patterns that worked)

{{what_went_well}}

Record approaches that should be deliberately reproduced in future cycles.

- {{good_point_1}}
- {{good_point_2}}
- {{good_point_3}}

## Issues (what did not work well)

{{issues}}

Record places where the loop count was high, the root causes of Blockers, and places where unexpected costs occurred.

### Loop count analysis

| Loop between steps | Count            | Root cause         |
| ------------------ | ---------------- | ------------------ |
| Step 6 ↔ Step 7    | {{loop_6_7}}     | {{root_cause_6_7}} |
| Step 7 → Step 3    | {{rollback_7_3}} | {{root_cause_7_3}} |
| Step 8 → Step 6    | {{rollback_8_6}} | {{root_cause_8_6}} |

### Blocker history

- {{blocker_1}} (raised: {{blocker_1_at}}, resolved: {{blocker_1_resolved_at}}, response: {{blocker_1_resolution}})
- {{blocker_2}} (raised: {{blocker_2_at}}, resolved: {{blocker_2_resolved_at}}, response: {{blocker_2_resolution}})

## Improvements for the next cycle

{{improvements}}

Decompose down to a concrete action grain (write "do X when Y" rather than "improve X").

### Process improvements

- {{process_improvement_1}}
- {{process_improvement_2}}

### Skill improvements

Concrete improvement proposals for the totto2727-dev-flow plugin's skills (`totto2727-dev-flow` / `specialist-*` / `share-artifacts`).

- {{skill_improvement_1}}
- {{skill_improvement_2}}

### Specialist prompt improvements

Improvement proposals for the role definitions, input specifications, and expected outputs of the Specialists.

- `intent-analyst`: {{intent_analyst_improvement}}
- `researcher`: {{researcher_improvement}}
- `architect`: {{architect_improvement}}
- `qa-analyst`: {{qa_analyst_improvement}}
- `planner`: {{planner_improvement}}
- `implementer`: {{implementer_improvement}}
- `reviewer`: {{reviewer_improvement}}
- `validator`: {{validator_improvement}}
- `retrospective-writer`: {{retrospective_writer_improvement}}

## Reusable insights

{{reusable_insights}}

Lessons that may also help in other cycles or projects. Include candidates for memory or CLAUDE.md.

- {{insight_1}}
- {{insight_2}}

## Retrospective on user approval gates

{{gate_retrospective}}

Look back at the approve / reject record for each approval gate, and the cause of any rejections.

- Step 1 (Intent Clarification): {{gate_1_summary}}
- Step 3 (Design): {{gate_3_summary}}
- Step 4 (QA Design): {{gate_4_summary}}
- Step 5 (Task Decomposition): {{gate_5_summary}}
- Step 7 (External Review): {{gate_7_summary}}
- Step 8 (Validation): {{gate_8_summary}}

## Retrospective on in-progress user inquiries

{{in_progress_question_summary}}

Summarize the count and main topics of `$TMPDIR/totto2727-dev-flow/*.md` temporary reports (mid-flight requests for judgment) created during the cycle. A high count may indicate insufficient clarification at the Intent Spec stage.

- Count: {{in_progress_question_count}}
- Main topics: {{in_progress_question_topics}}

## Cost / time

{{cost_time}}

- Wall-clock time per phase: {{phase_durations}}
- Number of Specialist launches: {{specialist_launch_count}}
- Effective parallelism: {{effective_parallelism}}
