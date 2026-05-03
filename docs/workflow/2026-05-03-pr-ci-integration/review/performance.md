# Review Report: performance

- **Cycle:** 2026-05-03-pr-ci-integration
- **Aspect:** performance — CI 待機時間 / API レート / ポーリング・リトライ・コミット頻度のオーバーヘッド評価
- **First reviewed:** 2026-05-03
- **Last updated:** 2026-05-03
- **Final Gate:** approved
- **Round count:** 1

## サマリ

- **Blocker:** 0 件
- **Major:** 0 件 (M-1 は accepted-as-is に降格)
- **Minor:** 5 件 (accepted-as-is、Retrospective 繰越合意推奨)
- **Info:** 4 件 (整合確認のみ)
- **Final Gate:** approved

## 指摘一覧

| ID  | 深刻度 | 指摘内容                                                                                                                                                                   | 状態           | 検出 Round | 解消 commit | Notes                                                                                                                                                                     |
| --- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ---------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| M-1 | Major  | SKILL.md は「6 観点並列が常時推奨」と読める。軽量サイクル (1〜2 ファイル改修) で観点を縮める基準がない。本サイクル (3 ファイル多面改修) では妥当。                         | accepted-as-is | 1          | -           | 観測対象 `specialist-reviewer/SKILL.md` L7 / `dev-workflow/SKILL.md` L501。Intent 非スコープ (`specialist-*` 大規模変更非スコープ)。Retrospective 繰越合意 (2026-05-03)。 |
| m-1 | Minor  | `gh run watch --interval 10` の API ポーリング負荷見積もりが SKILL.md/research にない。本サイクルの試算では 100〜130 req/cycle ≒ 5000 req/h の 2.6%。                      | accepted-as-is | 1          | -           | 観測対象 `dev-workflow/SKILL.md` L899-L900。matrix 化時に注記「`--interval` を縮める場合は rate limit を勘案」を残すと将来安全。                                          |
| m-2 | Minor  | design.md L491-L495 のパフォーマンス予測 (約 18 分) が Step 6 タスク単位 CI を計上していない。実態は ~23〜25 分。SKILL.md L382 の要件 (全タスク CI PASS) は仕様通り。      | accepted-as-is | 1          | -           | 観測対象 `design.md` L492-L495 / `dev-workflow/SKILL.md` L382。Step 8 Validator の実測で確定。Retrospective 繰越合意。                                                    |
| m-3 | Minor  | `gh run watch` の race 回避ループ (L892-L897) は最大 30 秒 sleep × 6 で run id 取得。30 秒以内に出現しない場合のフォールバックが不明。本リポ実測 queue p99 8s で十分余裕。 | accepted-as-is | 1          | -           | 観測対象 `dev-workflow/SKILL.md` L892-L897。GitHub Actions 全体障害時のみ問題化。発生確率極小。Retrospective 繰越合意。                                                   |
| m-4 | Minor  | `gh pr edit --body-file` の頻度上限規律が任意になっている。Step 6 で並列 implementer 完了ごとに更新するパターンを取ると 1 ステップ内 10 編集集中の可能性。                 | accepted-as-is | 1          | -           | 観測対象 `dev-workflow/SKILL.md` L815-L827。Single-Source 原則 (Main 専属) で write 競合自体は発生しない。Retrospective 繰越合意。                                        |
| m-5 | Minor  | `$TMPDIR/dev-workflow/ci-watch-<run-id>.log` のクリーンアップ規律が SKILL.md にない。サイクル間で蓄積し続けるとファイル数線形増加。                                        | accepted-as-is | 1          | -           | 観測対象 `dev-workflow/SKILL.md` L900-L901。OS の `$TMPDIR` ライフサイクル (再起動でクリア) に依存する解釈可。明示削除規律は YAGNI 範囲。Retrospective 繰越合意。         |
| i-1 | Info   | CI 待機時間の理論最大値: 9 ステップ × p90 120s + Step 6 タスク追加分 (~240s) + リトライ予備 (~120s) = 約 22 分。バックグラウンド `gh run watch` で Main の並行作業可。     | (整合確認のみ) | 1          | -           | 観測対象 `design.md` L491-L495 / `ci-structure.md` I-2。性能設計は実用性十分。                                                                                            |
| i-2 | Info   | リトライ規律「新規コミット push を 1 リトライ、最大 2 回」は本リポ現実 (flaky ゼロ) と完全整合。`gh run rerun` 不採用は Main の反復負荷で正当化。3 回失敗合計 ~5.5 分。    | (整合確認のみ) | 1          | -           | 観測対象 `dev-workflow/SKILL.md` L918-L941 / `ci-structure.md` I-3。                                                                                                      |
| i-3 | Info   | 冪等性チェック (`gh pr list --head` / `gh pr view --json isDraft`) の追加 read API 呼び出しは 3 回/cycle 程度。Single-Source 原則違反防止の価値が遥かに大きい。            | (整合確認のみ) | 1          | -           | 観測対象 `dev-workflow/SKILL.md` L799-L813 / L949-L962。                                                                                                                  |
| i-4 | Info   | `--interval 10` (10 秒) ポーリングは本リポ p90 120s に対し最適点。短縮 (5 秒) で API 負荷 2 倍 vs 検出遅延短縮効果薄。                                                     | (整合確認のみ) | 1          | -           | 観測対象 `dev-workflow/SKILL.md` L900。                                                                                                                                   |

## 詳細セクション

### M-1 詳細: External Review 6 並列の正当性根拠の SKILL.md 記載不足

`specialist-reviewer/SKILL.md` L7 で「観点ごとに並列起動される前提（6 並列）」と固定的に書かれており、`dev-workflow/SKILL.md` L501 も同様。本サイクル (改修対象 3 ファイル × ドキュメント中心) では 6 並列が現実に動作し、performance / security / readability / test-quality / api-design / holistic それぞれが独立した付加価値を提供しているため正当化される。

しかし、より小規模なサイクル (例: typo 修正 1 ファイル / 数行) で 6 並列を起動するとレビュー観点の意義が薄く、LLM コストが過剰になる可能性がある。SKILL.md には「6 観点 = 必須 / オプション」「観点削減基準」が明示されていない。

ただし本サイクルの Intent 非スコープであり (Intent Spec L34: `specialist-*` への大規模変更非スコープ)、本サイクル自身の運用判断としては適切に 6 並列が機能している。**深刻度を Major → accepted-as-is** とし、Retrospective で「サイクル規模に応じた reviewer 並列度」を将来サイクルの議題として繰越すことを推奨する。

### m-2 詳細: パフォーマンス予測値の精度

design.md L491-L495 のパフォーマンス予測は Step 6 を 1 ステップ = 1 CI run として計上している。実際の Step 6 は本サイクル task-plan で **5 タスク** あり、各タスクが TODO.md start / complete + 実装コミットで `dev-workflow/SKILL.md` L342-L345 に従い「タスク単位コミット」として独立 CI run を生成する。

実値見積もり:

- 通常ステップ (Step 1-5, 7-9): 8 ステップ × ~120s = 16 分
- Step 6 (5 タスク、Wave 直列 3 ): 3 wave × ~120s = 6 分
- リトライ予備 (本リポ過去比 2-5%): +1〜3 分
- **合計: 約 23〜25 分**

design.md の「約 18 分」は Step 6 の Wave 直列性を計上していないため、実態は + 約 5〜7 分。

## Round 履歴メタ

| Round | 実行日     | reviewer instance               | 単独 Gate |
| ----- | ---------- | ------------------------------- | --------- |
| 1     | 2026-05-03 | reviewer (performance, initial) | approved  |
