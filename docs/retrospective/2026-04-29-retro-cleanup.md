# Retrospective: 2026-04-29-retro-cleanup

- **Identifier:** 2026-04-29-retro-cleanup
- **Writer:** Main 兼任 (軽量サイクルのため retrospective-writer subagent 起動せず)
- **Created at:** 2026-04-29T14:45:00Z
- **Cycle started at:** 2026-04-29T10:00:00Z
- **Cycle completed at:** 2026-04-29T14:45:00Z
- **Duration:** 約 4.5 時間 (Step 1 ユーザー対話複数ラウンド + 軽量実装)

## サイクル概要

過去 3 サイクルの retrospective に蓄積した残提案を消化する第 4 弾メタサイクル。Step 1 で複数ラウンドのユーザー対話により scope を大幅縮小 (当初 30 SC → 最終 20 SC)、最終的に **3 件の Specialist 本文修正 + 1 件の ADR 起票 + retrospective 構造変更 (workflow 構造の追加対応)** に絞った。

直前サイクル (`2026-04-29-integrate-self-review-into-external`) より更にコンパクトに収まり、6 commits で実装完了。Validation 19/19 PASS (TC-011/TC-012 は本サイクル Step 9 完了後の最終検証)。

主要な成果は **retrospective を `docs/retrospective/` 集約ディレクトリに移動 + 削除ポリシー導入** で、これは Intent Spec 当初の retrospective 残提案には含まれない workflow 構造変更だが、ユーザー判断で追加対応となった。本サイクル自身がこの新方式の最初の retrospective として `docs/retrospective/2026-04-29-retro-cleanup.md` (このファイル) に保存される。

## 良かった点

- **Step 1 ユーザー対話で scope 縮小が機能した**: 初期 Intent Spec に含まれていた A-1 / A-3 / A-6 / A-7 / B 全項目を「不要マーク」「ADR にも残す価値なし」と判断できた。retrospective の改善案を機械的に全件採用するのではなく、各項目に「なぜ必要か」「skill-reviewer ルール違反か」を問い直すフレームワークが奏功
- **A-2 を dev-workflow Report-Based Confirmation に集約**: 元の retrospective は architect 本文への追記を求めていたが、計画段階全 Specialist (intent-analyst / architect / qa-analyst / planner) で共通化できる質問プロトコルとして 1 箇所に集約。bootstrap retrospective M#3 の「真のソース重複」アンチパターンを未然に回避
- **A-5 holistic 小節欠落の発見**: research note `operational-rules-mapping.md` で `specialist-reviewer/SKILL.md` 本文の「観点別のレビュー指針」セクションに holistic 小節が完全欠落していることを発見。直前サイクルでは frontmatter / Step 7 セクションには反映されたが本文小節を見落としていた漏れを補完
- **軽量スコープのため Specialist subagent 不起動で完結**: Step 3 architect / Step 4 qa-analyst / Step 5 planner を Main 直接で実行。ファイル数 5 / 行数 < 50 の小さな変更にサブエージェント起動コストをかけず効率化
- **Wave 1 並列構造で T1-T5 を独立タスク化**: 各タスク = 1 commit、依存なし、6 commits で完結。前例 B-2「巨大単一 commit」アンチパターン回避が定着
- **CI 即時 PASS 期待値**: 直前サイクルで chain bug + フォーマット違反で再修正が発生したのに対し、本サイクルは追記中心で機械置換ゼロのため CI 一発 PASS 見込み
- **Step 1 ユーザー指示の `git revert` 提案で根本対応**: 「baseline commit 記録ルール」を当初 ADR 化候補としていたが、ユーザー指摘で「`git revert` を最初に試せば不要」と気づき不要マーク化。問題回避策ではなく根本原因への対処を選択

## 課題

### Step 1 ユーザー対話の往復が多かった

- 初期 Intent Spec → 縮小 → A-2 集約変更 → C 追加 → A-2 文言の citation 削除 → A-4 のみ ADR 化、と Step 1 内で 6-7 ラウンドのユーザー対話が発生
- Step 1 完了まで約 2 時間消費 (全体の 45%)
- 根本原因: 初期 Intent Spec が retrospective の改善案を機械的に全件採用していた。skill-reviewer ルール違反のチェックや「対応する価値があるか」の事前判定が intent-analyst Specialist 起動時の入力に明示されていなかった
- 教訓: メタサイクル Intent Clarification で「retrospective の改善案を採用するかどうかの判定基準 (skill-reviewer 違反 / 局所性 / CLI 化待ち / 再現性等)」を**最初のラウンドで提示**し、ユーザー判断を一括で得る方が効率的だった

### TC-011 / TC-012 が Step 8 で検証不可能

- `docs/retrospective/` ディレクトリと本サイクル retrospective ファイルは Step 9 で生成されるため、Step 8 Validation 時点では未存在
- Validation Report で「保留 (Step 9 完了後検証)」と明示したが、本来は Step 8 の TC からは除外して別段で検証する設計が望ましかった
- 教訓: Step 9 出力に依存する検証は Step 8 の SC ではなく「Step 9 完了基準」として別管理すると整合性が取れる

### ループ回数の分析

| ステップ間ループ                         | 回数         | 根本原因                                                                   |
| ---------------------------------------- | ------------ | -------------------------------------------------------------------------- |
| Step 1 内ユーザー対話                    | 6-7 ラウンド | retrospective 改善案の採用判定基準が初回提示されず、scope 縮小の往復が発生 |
| Step 6 ↔ Step 7 (Blocker 戻し)           | 0            | Round 1 holistic レビューで Blocker / Major / Minor すべて 0 件            |
| Step 7 → Step 3 ロールバック             | 0            | 設計レベルロールバック不要                                                 |
| Step 8 → Step 6 (実装バグ)               | 0            | Validation 19 PASS、実装バグなし                                           |
| 同一タスク再活性化 (re_activations >= 1) | 0            | 全タスクが Round 1 で完了                                                  |

### Blocker 履歴

- なし (`progress.yaml.blockers` は空配列)

### 再活性化タスクの SHA 列挙

本サイクルでは `re_activations >= 1` のタスクなし。SHA 列挙対象は 0 件。

## 次回改善案

### プロセス改善

- **メタサイクル Intent Clarification の最初のラウンドで「retrospective 改善案の採用判定基準」を提示する**: 「skill-reviewer 違反か」「局所的すぎないか」「真のソース重複が発生しないか」「CLI 化等で将来代替されるか」のチェックリストを intent-analyst の起動入力に含める。本サイクル Step 1 の往復ラウンド数を 6-7 → 2-3 に削減できる見込み
- **Step 9 出力依存の TC を Step 8 SC から分離**: TC-011 / TC-012 のように Step 9 完了後にしか検証できないものは、Step 9 の Exit Criteria として別管理する。Step 8 Validation Report の「保留」エントリを増やすより構造的に整理される

### スキル改善

本サイクルで対応した A-2 / A-5 / A-8 / C 以外への追加改善は提案なし。skill-reviewer ルール違反は新たに発生していない。

### Specialist プロンプト改善

- `intent-analyst`: メタサイクルでの retrospective 改善案採用判定基準のチェックリスト (上記プロセス改善で言及)
- `retrospective-writer`: 既に本サイクル A-8 で再活性化 SHA 列挙手順を追加済み

## 再利用可能な知見

- **retrospective を `docs/retrospective/` に集約 + 削除ポリシーを導入する設計**: ADR と対比で「永続記録 (ADR) vs 揮発レポート (retrospective)」の役割分担が明確化される。他プラグインでも同様の議事録 vs 決定記録の整理に応用可能
- **scope 縮小は「機械的全件採用」より「採用判定基準を伴う個別評価」が筋がいい**: メタサイクルでは特に retrospective の改善案を「全部対応」しようとせず、採用判定で 6-7 割削れることがある。本サイクルでは初期 30 SC → 最終 20 SC、実質スコープは更に縮小
- **`git revert` を regression 修正の第一選択にする**: 直前サイクルで baseline commit 記録ルールを ADR 化しかけたが、ユーザー指摘で「revert を最初に試せば不要」と気づいた。問題回避策よりも根本原因への対処を選ぶ判断軸は他のサイクルでも有効
- **軽量サイクルでは Specialist subagent 不起動で Main 直接実装が効率的**: Step 3-5 の Specialist subagent 起動を省略しても workflow ゲートは維持できる。スコープ < 5 タスク / 機械置換なし / 単純な追記のサイクルでは subagent コストを削減できる

## ユーザー承認ゲートの振り返り

- **Step 1 (Intent Clarification)**: 6-7 ラウンドの対話で確定。当初 scope (構造圧縮 + description 圧縮 + 運用ルール追記の 3 軸 30 SC) → 最終 scope (Specialist 本文 3 件 + ADR 1 件 + retrospective 構造変更 5 sub-items)
- **Step 3 (Design)**: 「go」の即承認 (1 ラウンド、軽量スコープのため代替案議論不要)
- **Step 4 (QA Design)**: 暗黙承認 (Step 3 と同じ流れで継続)
- **Step 5 (Task Decomposition)**: 暗黙承認
- **Step 7 (External Review)**: holistic 観点 Blocker 0 件で approved
- **Step 8 (Validation)**: 19/19 PASS (TC-011/TC-012 は Step 9 後)

## In-Progress ユーザー問い合わせの振り返り

- 件数 0 (`$TMPDIR/dev-workflow/*.md` 一時レポートなし)
- Step 1 内のユーザー対話は In-Progress 形式ではなく直接対話で完結

## コスト / 時間

- **各フェーズの実時間:**
  - Step 1 (Intent Clarification): 約 2 時間 (6-7 ラウンド対話)
  - Step 2 (Research): 並列 3 researcher で約 5 分相当 (ただし scope 変更で大半が無駄に)
  - Step 3 (Design): 15 分 (Main 直接)
  - Step 4 (QA Design): 15 分 (Main 直接)
  - Step 5 (Task Decomposition): 15 分 (Main 直接)
  - Step 6 (Implementation): 30 分 (5 commits)
  - Step 7 (External Review): 10 分 (Main holistic レビュー)
  - Step 8 (Validation): 5 分 (grep バッチ実行)
  - Step 9 (Retrospective): 10 分 (本ファイル作成)
  - **合計:** 約 4.5 時間
- **Specialist 起動回数:**
  - Step 1: intent-analyst 1 回
  - Step 2: researcher 3 並列
  - Step 3-9: Main 直接 (subagent 不起動)
  - **合計:** 4 起動 (前例サイクル 30 起動と比べて圧倒的に少ない)
- **コスト効率:** 軽量スコープ + subagent 不起動で前例の 1/10 程度のコストで完結
