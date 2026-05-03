## Summary

dev-workflow に PR 作成・CI 確認の運用ルールを組み込むサイクル。**WIP / Draft**。
このサイクル自身を新運用 (Draft PR + 適宜概要更新 + バックグラウンド CI 確認) のドッグフード対象とする。

## Cycle

- Identifier: `2026-05-03-pr-ci-integration`
- Working dir: `docs/workflow/2026-05-03-pr-ci-integration/`
- Status: **Step 7 (External Review) 進行中**

## Scope

dev-workflow/SKILL.md に新セクション「サイクル PR と CI 連携プロトコル」を追加し、5 ルールを集約。各 Step Exit Criteria 末尾に CI PASS 行追加。`specialist-common §7` に「PR 操作は Main 専属」を 1 行追加。`progress-yaml.md` の `### blockers` に CI failure 例追記。

## Implementation summary (Step 6 done)

| Task | Wave | Commit  | Description                                                  |
| ---- | ---- | ------- | ------------------------------------------------------------ |
| T4   | 1    | bc1a84d | specialist-common §7 PR-Main-only line                       |
| T5   | 1    | 8a2aff6 | progress-yaml blockers CI-failure example                    |
| T1   | 1    | 45dff2b | dev-workflow/SKILL.md +新セクション (~110 行 + テンプレート) |
| T2   | 2    | 1509c57 | 9 Step Exit Criteria に CI PASS 追記                         |
| T3   | 3    | 0001ed9 | コミット規約 → PR-CI プロトコル参照リンク                    |
| T6   | post | d0250d1 | oxfmt cleanup (cycle artefacts)                              |
| T7   | post | 80ce71a | qa-design TC-009 見出し名補正                                |

## Progress

- [x] Cycle initialized
- [x] Draft PR created (this PR #95)
- [x] Rebased onto origin/main (`docs/dev-workflow/` → `docs/workflow/` rename absorbed)
- [x] Step 1: Intent Clarification
- [x] Step 2: Research (4 research notes)
- [x] Step 3: Design (567 行)
- [x] Step 4: QA Design (22 TC + qa-flow.md)
- [x] Step 5: Task Decomposition (5 tasks / 3 waves)
- [x] Step 6: Implementation (T1-T5 + T6/T7 follow-ups, all CI PASS)
- [ ] Step 7: External Review (6 reviewers parallel: security / performance / readability / test-quality / api-design / holistic)
- [ ] Step 8: Validation
- [ ] Step 9: Retrospective

## CI status

全コミットの CI = ✅ PASS (Step 6 各タスクコミット含む)。詳細は `gh run list --branch feat/dev-workflow-pr-ci-integration` 参照。

## Notable events

- 2026-05-03: origin/main の大規模変更 (PR #94 マージ: `docs/dev-workflow/` → `docs/workflow/` リネーム + roadmap 概念追加) を rebase で取り込み。
- 2026-05-03: ユーザーから Steps 2-9 の事前一括承認取得 (小規模サイクルのため)。
- 2026-05-03 Step 6 完了: T1-T5 を 3 Wave 5 implementer で完了。T6/T7 は post-Wave に Main 直接処理。

## Test plan

- [x] dev-workflow/SKILL.md に新セクション + 各 Exit Criteria に CI PASS 行 + 既存セクション保全
- [x] specialist-common §7 / progress-yaml.md の補助改修
- [x] CI (check) が pass — 全コミットで成功
- [ ] 本サイクル自身が新ルール (Draft 作成 → 適宜概要更新 → CI PASS → Ready 化) を実証 → Step 8 で検証
- [ ] External Review (6 観点) 通過 → Step 7
- [ ] SC-1〜SC-8 全て PASS → Step 8

## Artifacts

- [intent-spec.md](docs/workflow/2026-05-03-pr-ci-integration/intent-spec.md)
- [research/](docs/workflow/2026-05-03-pr-ci-integration/research/)
- [design.md](docs/workflow/2026-05-03-pr-ci-integration/design.md)
- [qa-design.md](docs/workflow/2026-05-03-pr-ci-integration/qa-design.md) / [qa-flow.md](docs/workflow/2026-05-03-pr-ci-integration/qa-flow.md)
- [task-plan.md](docs/workflow/2026-05-03-pr-ci-integration/task-plan.md) / [TODO.md](docs/workflow/2026-05-03-pr-ci-integration/TODO.md)
- [progress.yaml](docs/workflow/2026-05-03-pr-ci-integration/progress.yaml)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
