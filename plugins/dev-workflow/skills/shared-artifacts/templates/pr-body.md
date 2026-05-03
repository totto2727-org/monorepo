## Summary

- (1〜3 bullet で目的・主要変更を要約 — Intent Spec の「目的」セクションから派生)

## Cycle artefacts

- intent-spec: docs/workflow/{{identifier}}/intent-spec.md
- research: docs/workflow/{{identifier}}/research/<topic>.md (各観点)
- design: docs/workflow/{{identifier}}/design.md
- qa-design: docs/workflow/{{identifier}}/qa-design.md
- qa-flow: docs/workflow/{{identifier}}/qa-flow.md
- task-plan: docs/workflow/{{identifier}}/task-plan.md
- TODO: docs/workflow/{{identifier}}/TODO.md
- review: docs/workflow/{{identifier}}/review/<aspect>.md (6 観点)
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

- 最新コミット SHA: <abbrev-sha>
- 最新 `check` job: <conclusion> (run id: <run-id>, attempt: <n>)
- リトライ履歴: (失敗があった場合のみ列挙、Step ごとにブロック)

## Test plan (Step 8 で完成)

- [ ] SC-N (criteria): <観測値 / 検証コマンド>

## Notable incidents (該当があった場合のみ)

- ロールバック・前提崩壊履歴

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
