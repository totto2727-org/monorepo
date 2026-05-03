## Summary

- (1-3 bullets summarizing the purpose and key changes — derived from the Intent Spec's "Purpose" section)

## Cycle artefacts

- intent-spec: docs/workflow/{{identifier}}/intent-spec.md
- research: docs/workflow/{{identifier}}/research/<topic>.md (one per topic)
- design: docs/workflow/{{identifier}}/design.md
- qa-design: docs/workflow/{{identifier}}/qa-design.md
- qa-flow: docs/workflow/{{identifier}}/qa-flow.md
- task-plan: docs/workflow/{{identifier}}/task-plan.md
- TODO: docs/workflow/{{identifier}}/TODO.md
- review: docs/workflow/{{identifier}}/review/<aspect>.md (six aspects)
- validation: docs/workflow/{{identifier}}/validation-report.md
- retrospective: docs/retrospective/{{identifier}}.md

## Progress checklist

- [ ] Step 1: Intent Clarification
- [ ] Step 2: Research
- [ ] Step 3: Design
- [ ] Step 4: QA Design
- [ ] Step 5: Task Decomposition
- [ ] Step 6: Implementation
- [ ] Step 7: External Review
- [ ] Step 8: Validation
- [ ] Step 9: Retrospective

## CI status

- Latest commit SHA: <abbrev-sha>
- Latest `check` job: <conclusion> (run id: <run-id>, attempt: <n>)
- Retry history: (list only when there were failures, grouped by Step)

## Test plan (finalized in Step 8)

- [ ] SC-N (criteria): <observed value / verification command>

## Notable incidents (only when applicable)

- Rollback / premise-collapse history

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
