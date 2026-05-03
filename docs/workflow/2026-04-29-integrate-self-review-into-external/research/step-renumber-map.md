# Research Note: step-renumber-map

- **Identifier:** 2026-04-29-integrate-self-review-into-external
- **Topic:** step-renumber-map
- **Researcher:** researcher (Specialist instance #1)
- **Created at:** 2026-04-29T13:10:00Z
- **Scope:** `plugins/dev-workflow/` 配下の `Step 7` / `Step 8` / `Step 9` / `Step 10` 表記の全洗い出しと、10-step → 9-step (Self-Review 削除に伴う番号繰り上げ) のための置換マップ・連鎖二重置換リスク・複合表現保護戦略の整理

## 調査対象

Intent Spec の制約「ステップ番号置換は順序依存」「`Step 6 ↔ Step 7` のような複合表現や ASCII 図の枠線数字 / 一覧表の数値があるため、機械的な一括置換ではなく Edit ツールで文脈ごとに置換することを推奨」 (intent-spec L160-163) に対応する事前棚卸し。Step 6 (Implementation) で「機械的に作業可能なレベル」 (本ステップ完了条件) まで影響範囲を分解する。

対象は以下の 4 数字シフト:

- 旧 Step 8 (External Review) → 新 Step 7
- 旧 Step 9 (Validation) → 新 Step 8
- 旧 Step 10 (Retrospective) → 新 Step 9
- 旧 Step 7 (Self-Review) は削除 (Self-Review 文脈は別観点として扱うが、本観点では「Step 7 と書かれていた箇所が削除対象か再番号化対象か」だけ識別する)

## 発見事項

### 1. 全体ヒット件数

`grep -rnE 'Step (7|8|9|10)\b' plugins/dev-workflow/` で **93 行** ヒット (`/tmp/claude/step_hits.txt` に保管)。
複合表現 `grep -rnE 'Step [0-9]+ ↔ Step [0-9]+|Step [0-9]+/[0-9]+|Step [0-9]+→Step [0-9]+|Step [0-9]+〜[0-9]+|Step [0-9]+ → Step [0-9]+'` で **23 行** が複合表現として独立検出される (`/tmp/claude/compound_hits.txt`)。

### 2. ファイル別ヒット分布 (Step 7-10 単独参照)

| ファイル                                                                        | 行番号                                                                                                              | 件数 |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ---- |
| `plugins/dev-workflow/agents/reviewer.md`                                       | L3, L13, L24                                                                                                        | 3    |
| `plugins/dev-workflow/agents/self-reviewer.md`                                  | L3, L11, L22                                                                                                        | 3    |
| `plugins/dev-workflow/agents/retrospective-writer.md`                           | L3, L13, L24                                                                                                        | 3    |
| `plugins/dev-workflow/agents/validator.md`                                      | L3, L13, L24                                                                                                        | 3    |
| `plugins/dev-workflow/skills/shared-artifacts/SKILL.md`                         | L52, L53, L54, L55, L125, L126, L130, L131, L133                                                                    | 9    |
| `plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md`      | L75, L76, L77, L78                                                                                                  | 4    |
| `plugins/dev-workflow/skills/shared-artifacts/references/review-report.md`      | L10, L121                                                                                                           | 2    |
| `plugins/dev-workflow/skills/shared-artifacts/references/intent-spec.md`        | L36                                                                                                                 | 1    |
| `plugins/dev-workflow/skills/shared-artifacts/references/qa-design.md`          | L5, L90, L119, L193                                                                                                 | 4    |
| `plugins/dev-workflow/skills/shared-artifacts/references/qa-flow.md`            | L218                                                                                                                | 1    |
| `plugins/dev-workflow/skills/shared-artifacts/references/self-review-report.md` | L5, L10, L47, L48, L66                                                                                              | 5    |
| `plugins/dev-workflow/skills/shared-artifacts/references/validation-report.md`  | L10                                                                                                                 | 1    |
| `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md`      | L10, L38                                                                                                            | 2    |
| `plugins/dev-workflow/skills/shared-artifacts/templates/qa-design.md`           | L73                                                                                                                 | 1    |
| `plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml`          | L13                                                                                                                 | 1    |
| `plugins/dev-workflow/skills/shared-artifacts/templates/validation-report.md`   | L78                                                                                                                 | 1    |
| `plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md`       | L36, L38, L94, L95                                                                                                  | 4    |
| `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md`                      | L4, L11, L29, L128                                                                                                  | 4    |
| `plugins/dev-workflow/skills/specialist-self-reviewer/SKILL.md`                 | L4, L10, L28, L47, L68, L69, L95, L96                                                                               | 8    |
| `plugins/dev-workflow/skills/specialist-validator/SKILL.md`                     | L4, L25                                                                                                             | 2    |
| `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md`          | L4, L10, L28, L59                                                                                                   | 4    |
| `plugins/dev-workflow/skills/specialist-qa-analyst/SKILL.md`                    | L124                                                                                                                | 1    |
| `plugins/dev-workflow/skills/dev-workflow/SKILL.md`                             | L6, L398, L411, L412, L423, L434, L435, L437, L446, L452, L454, L461, L466, L488, L502, L507, L541, L549, L829-L835 | 22   |

### 3. 複合表現 (placeholder 化必須) の全件

| ファイル                                                   | 行   | 表現                                       | 新表現 (置換後)                                                                                                          |
| ---------------------------------------------------------- | ---- | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| `skills/shared-artifacts/SKILL.md`                         | L50  | `Step 6〜7 全体`                           | `Step 6〜7 全体` (変化なし: 旧 Implementation/Self-Review → 新 Implementation/External Review、Step 6〜7 区間自体は維持) |
| `skills/shared-artifacts/SKILL.md`                         | L209 | `Step 1〜5`                                | `Step 1〜5` (変化なし)                                                                                                   |
| `skills/shared-artifacts/references/progress-yaml.md`      | L100 | `Step 6〜7 中`                             | `Step 6〜7 中`                                                                                                           |
| `skills/shared-artifacts/references/task-plan.md`          | L12  | `Step 6〜7 中` / `Step 5`                  | `Step 6〜7 中` / `Step 5` (`Step 5` はそのまま)                                                                          |
| `skills/shared-artifacts/references/task-plan.md`          | L82  | `Step 6〜7 中`                             | `Step 6〜7 中`                                                                                                           |
| `skills/shared-artifacts/references/todo.md`               | L5   | `Step 6〜7 中`                             | `Step 6〜7 中`                                                                                                           |
| `skills/shared-artifacts/references/todo.md`               | L26  | `Step 6〜7 中`                             | `Step 6〜7 中`                                                                                                           |
| `skills/shared-artifacts/references/self-review-report.md` | L88  | `Step 1〜3 への回帰`                       | (ファイルごと削除のため不要)                                                                                             |
| `skills/shared-artifacts/templates/task-plan.md`           | L9   | `Step 5 で確定...Step 6〜7 中`             | 同上                                                                                                                     |
| `skills/shared-artifacts/templates/TODO.md`                | L4   | `Step 6〜7 (Implementation / Self-Review)` | `Step 6〜7 (Implementation / External Review)` ★ Self-Review 文字列削除を伴う                                            |
| `skills/shared-artifacts/templates/TODO.md`                | L14  | `Step 6〜7 中`                             | `Step 6〜7 中`                                                                                                           |
| `skills/shared-artifacts/references/retrospective.md`      | L38  | `Step 6 ↔ Step 7`                          | `Step 6 ↔ Step 7` (Implementation/External Review 間ループ意味は維持)                                                    |
| `skills/shared-artifacts/references/retrospective.md`      | L39  | `Step 6/7 → Step 3`                        | `Step 6/7 → Step 3`                                                                                                      |
| `skills/shared-artifacts/references/design.md`             | L5   | `Step 6〜7 中`                             | `Step 6〜7 中`                                                                                                           |
| `skills/shared-artifacts/templates/retrospective.md`       | L36  | `Step 6 ↔ Step 7`                          | `Step 6 ↔ Step 7` (意味再解釈: Self-Review→External Review)                                                              |
| `skills/shared-artifacts/templates/retrospective.md`       | L37  | `Step 6/7 → Step 3`                        | `Step 6/7 → Step 3`                                                                                                      |
| `skills/shared-artifacts/templates/retrospective.md`       | L38  | `Step 8 → Step 6`                          | `Step 7 → Step 6` ★ 数字シフト                                                                                           |
| `skills/dev-workflow/SKILL.md`                             | L437 | `#### Step 6 ↔ Step 7 ループ`              | (意味再解釈で Edit、文字列としては維持)                                                                                  |
| `skills/dev-workflow/SKILL.md`                             | L502 | `Step 7 → Step 8`                          | (Self-Review 削除に伴いセクション再構築。文字列維持なし)                                                                 |
| `skills/dev-workflow/SKILL.md`                             | L549 | `Step 6 ↔ Step 7 の往復`                   | `Step 6 ↔ Step 7 の往復` (意味再解釈)                                                                                    |
| `skills/specialist-retrospective-writer/SKILL.md`          | L59  | `Step 6 ↔ Step 7 の往復`                   | `Step 6 ↔ Step 7 の往復` (意味再解釈)                                                                                    |
| `skills/specialist-planner/SKILL.md`                       | L14  | `Step 6〜7 中`                             | `Step 6〜7 中`                                                                                                           |
| `skills/specialist-planner/SKILL.md`                       | L47  | `Step 6〜7 中`                             | `Step 6〜7 中`                                                                                                           |

**重要な観察:**

1. **`Step 6〜7` / `Step 6 ↔ Step 7` / `Step 6/7` の数値表現自体は不変** (Implementation 側の Step 6 が動かず、Step 7 は External Review に置き換わるだけ)。ただし**周辺テキストの意味変化** (例: `Step 6〜7 (Implementation / Self-Review)` → `Step 6〜7 (Implementation / External Review)`) は Edit で個別対応必須
2. `Step 8 → Step 6` (templates/retrospective.md L38) は **数字シフト対象**: 旧 External Review (Step 8) は新番号で Step 7 になるため `Step 7 → Step 6` に変える
3. `Step 1〜3 への回帰` / `Step 1〜5` のような Step ≤ 6 の範囲は不変

### 4. 単純 gsed 置換 OK の Step 7 単独表記 (Self-Review 文脈)

旧 Step 7 (Self-Review) を直接指している全 47 行は**単純 gsed 置換対象外**。Self-Review 削除サイクルなので、これらは:

- (a) 該当ファイル自体が削除対象 (`specialist-self-reviewer/`, `agents/self-reviewer.md`, `shared-artifacts/{templates,references}/self-review-report.md`) — gsed 不要、`git rm` で済む
- (b) Self-Review 言及自体を消す Edit が必要 (`specialist-implementer/SKILL.md`, `specialist-common/SKILL.md`, `specialist-intent-analyst/SKILL.md`, `dev-workflow/SKILL.md` の Step 7 セクション削除等)

該当行: `dev-workflow/SKILL.md` L398, L411, L412, L423, L434, L435, L437, L446, L452, L454, L461 (Step 7 セクション全体 = L398-L464) と、`agents/self-reviewer.md` L3, L11, L22 (削除)。

→ **本観点 (step-renumber) のスコープ外** だが識別のため記録。

### 5. 単純 gsed 置換 OK の Step 8 → 7 / Step 9 → 8 / Step 10 → 9

| 旧 → 新     | 該当ファイル / 行 (Self-Review 関連除く)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Step 8 → 7  | agents/reviewer.md L3, L13, L24 / shared-artifacts/SKILL.md L53 (テーブル列), L126 (ASCII 図), templates/progress.yaml L13 (`Step 8 Review`), templates/validation-report.md L78 (`Step 8 失敗時`) / specialist-reviewer/SKILL.md L4, L11, L29 / dev-workflow/SKILL.md L466 (見出し), L488, L502, L831 (ロールバック表) / shared-artifacts/references/review-report.md L10, references/qa-flow.md (なし) / templates/retrospective.md L94                                                                                                                                                         |
| Step 9 → 8  | agents/validator.md L3, L13, L24 / shared-artifacts/SKILL.md L54, L130, L131 (ASCII 図 2 行) / references/progress-yaml.md L77 / references/qa-design.md L5, L90, L119, L193 (`Step 9 validator`/`Step 9 で実測`) / references/qa-flow.md L218 / references/validation-report.md L10 / references/intent-spec.md L36 (`Validation Step 9`) / specialist-validator/SKILL.md L4, L25 / specialist-reviewer/SKILL.md L128 / specialist-qa-analyst/SKILL.md L124 / dev-workflow/SKILL.md L507 (見出し), L832-L835 (ロールバック表 4 行) / templates/qa-design.md L73 / templates/retrospective.md L95 |
| Step 10 → 9 | agents/retrospective-writer.md L3, L13, L24 / shared-artifacts/SKILL.md L55, L133 / references/progress-yaml.md L78 / references/retrospective.md L10 / specialist-retrospective-writer/SKILL.md L4, L10, L28 / dev-workflow/SKILL.md L541 (見出し)                                                                                                                                                                                                                                                                                                                                               |

### 6. 文脈考慮で Edit 必須 (gsed では危険)

| 該当箇所                                                       | 理由                                                                                                                                                                                                                |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `dev-workflow/SKILL.md` L100-L121 (ASCII フロー図)             | 旧 7. Self-Review ノードを削除し、後続を再配置。`7. Self-Review` 行削除 → 旧 8/9/10 を 7/8/9 に番号変更。**全体構造変更を伴うため Edit 必須**                                                                       |
| `dev-workflow/SKILL.md` L125-L138 (ステップ一覧テーブル)       | 9 行 → 9 行 (Self-Review 行削除 + 後続行の Step 番号繰り上げ)。テーブル末尾整列の都合上、Edit で行ごと書き換え                                                                                                      |
| `dev-workflow/SKILL.md` L437-L464 (`Step 6 ↔ Step 7` ループ図) | Self-Review 役割を External Review に移すため、本文と ASCII 図を全面再構築。「self-reviewer B1 起動」「Step 7 継続のため維持」等の文章を書き換え                                                                    |
| `dev-workflow/SKILL.md` L466-L505 (External Review セクション) | Step 番号 8 → 7、本文に「Self-Review が担っていた『全体整合性チェック』『implementer 直後の手戻り抑止』を本ステップで吸収する」追記                                                                                 |
| `dev-workflow/SKILL.md` L720-L734 (コミット規約テーブル)       | 行ごとの Step 番号を 7/8/9/10 → 7/8/9 に再番号化、Self-Review 行 (L731) を削除                                                                                                                                      |
| `dev-workflow/SKILL.md` L781-L792 (並列起動ガイドライン)       | 同上 (Self-Review 行 L789 削除 + 後続再番号化)                                                                                                                                                                      |
| `dev-workflow/SKILL.md` L819-L835 (ロールバック早見表)         | 行 L829-L830 (Step 7 = Self-Review 由来) を削除 OR 「External Review High 指摘」「設計レベル」のエントリに統合し、Step 8/9 は Step 7/8 に番号変更。`Step 9 → Step 4` (qa-flow カバレッジ不足) は Step 8 → Step 4 に |
| `shared-artifacts/SKILL.md` L48-L56 (成果物一覧テーブル)       | self-review-report.md 行を削除し、行番号 (L52 の `10`) を再付番、Step 7→7 (review)/Step 8→8/Step 9→9 と列再付番                                                                                                     |
| `shared-artifacts/SKILL.md` L117-L133 (保存構造 ASCII)         | self-review-report.md 行 L125 を削除、L126 のコメント `# Step 8 成果物` を `# Step 7 成果物` に                                                                                                                     |
| `templates/progress.yaml` L39                                  | `self_review: null` 行を削除                                                                                                                                                                                        |
| `references/progress-yaml.md` L75-L78                          | `self_review` 行 (L75) を削除し、後続 `review (Step 8)`/`validation (Step 9)`/`retrospective (Step 10)` を Step 7/8/9 に再番号                                                                                      |
| `templates/TODO.md` L4                                         | `Step 6〜7 (Implementation / Self-Review)` の `Self-Review` を `External Review` に書き換え                                                                                                                         |
| `templates/retrospective.md` L36-L38, L94-L95                  | ループ表とゲート列のステップ意味再解釈 (Self-Review 言及を External Review に) + `Step 8 → Step 6` を `Step 7 → Step 6` に                                                                                          |
| `references/retrospective.md` L38                              | 同上 (意味再解釈)                                                                                                                                                                                                   |
| `references/review-report.md` L121                             | `Self-Review レポート（Step 7）とは別層` を Self-Review 廃止文脈に書き換え (Self-Review 削除観点で別途扱う)                                                                                                         |
| `README.md` L5, L19                                            | `ten specialist subagents` / `flat 10-step lifecycle` / `Self-Review, External Review` を 9-step / 9 specialist / External Review (吸収表現) に                                                                     |
| `.claude-plugin/plugin.json` L3                                | `flat 9-step lifecycle (... → Self-Review → External Review → ...)` を正しい 9-step (Self-Review なし) に置換                                                                                                       |

### 7. 連鎖二重置換のリスク特定

旧サイクル `2026-04-26-add-qa-design-step` の retrospective L22, L30 と task-plan L161 で、**順方向 (8→9 → 9→10) の gsed 連鎖二重置換が発生** していたことが確認できる:

> 「`gsed` を順方向 (Step 4→5 → 5→6 → ...) で実行すると連鎖して二重置換される (Step 4 が結果として Step 6 になる)」(task-plan.md L161)

本サイクルの番号シフトでも同型のリスクがある:

- 順方向 `Step 8 → 7` → `Step 9 → 8` → `Step 10 → 9` を実行すると、**最初に `Step 8` を `Step 7` にした行が、次の `Step 9 → 8` 走行で再度 `Step 8` から `Step 7` に二重シフト**するわけではない (`Step 9` は `Step 8` ではない)
- ただし `Step 9 → 8` を先に走らせ、その後 `Step 10 → 9` を走らせると、元の `Step 9` だった行と新たに生まれた `Step 9` (旧 Step 10) が混在し、後段で区別できなくなる
- → **降順** (`Step 10 → Step 9` を先、次に `Step 9 → Step 8`、最後に `Step 8 → Step 7`) で実行することで、置換後の番号と元の番号が衝突しないことが保証される

具体的危険例 (順方向で起こる事故):

```text
原文: "Step 9 (Validation)" と "Step 10 (Retrospective)"
gsed 1: s/Step 8/Step 7/    → 影響なし
gsed 2: s/Step 9/Step 8/    → "Step 8 (Validation)" / "Step 10 (Retrospective)"
gsed 3: s/Step 10/Step 9/   → "Step 8 (Validation)" / "Step 9 (Retrospective)" ← 一見 OK
```

このケースは順方向でも壊れない。ただし**降順で実行する方がレビュー時に「この時点での文書状態」を頭の中で正しく保つコストが低い**ため、先例 retrospective に従い降順を採用すべき。

### 8. 旧サイクルの placeholder 戦略 (引用)

`2026-04-26-add-qa-design-step` のコミット `55b4bb2` メッセージ:

> Mass gsed reverse-order shift (9->10, 8->9, ..., 4->5) with placeholder protection for compound expressions (Step 5 ↔ Step 6 -> Step 6 ↔ Step 7, Step 5/6 -> Step 6/7, Step 5〜6 -> Step 6〜7).

retrospective L22:

> gsed の placeholder 経由による複合表現保護 (Step 5 ↔ Step 6 → Step 6 ↔ Step 7) → 連鎖二重置換の罠を回避できた

retrospective L56:

> gsed で機械置換する場合は事前に `Step \d+〜\d+|Step \d+ ↔ Step \d+|Step \d+\/\d+` を grep して全件 placeholder 化するルールを implementer reference に追記

**戦略の本質:**

1. 機械置換前に `Step (\d)+(〜|/| ↔ |→)Step?(\d)+` 系の複合表現を grep で全件特定
2. 各複合表現を `__STEP_PLACEHOLDER_<id>__` 等に一時置換 (sed 実行中の単独 `Step N` 置換から保護)
3. 単独 `Step 8` / `Step 9` / `Step 10` を**降順で** gsed 実行
4. placeholder を本来の表現 (新番号換算後) に戻す

### 9. 旧サイクルの教訓: shared-artifacts/references の取りこぼし

retrospective L31:

> shared-artifacts/references/\* の一部が T6 範囲外だったことが Step 5 中に発覚 (design.md, retrospective.md, todo.md など)。task-plan で漏れたため、追加 gsed バッチで対応する必要があった

→ 本サイクルの Step 5 (Task Decomposition) では、この時点で既に references/templates の全件を網羅した置換タスクとして分解する必要がある。

## 引用元

- 全件 grep 結果: `/tmp/claude/step_hits.txt` (93 行) / `/tmp/claude/compound_hits.txt` (23 行)
- 直前サイクル retrospective: `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md` L22, L30, L31, L56, L82
- 直前サイクル task-plan: `docs/dev-workflow/2026-04-26-add-qa-design-step/task-plan.md` L72, L161
- 直前サイクル research: `docs/dev-workflow/2026-04-26-add-qa-design-step/research/existing-structure.md` L105 (含意 1: 番号シフト順序)
- 直前サイクル設計: `docs/dev-workflow/2026-04-26-add-qa-design-step/design.md` L28
- 直前サイクル実装コミット: `git log --format='%B' 55b4bb2` (mechanical step number shift across all remaining files)
- Intent Spec 制約: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/intent-spec.md` L160-163
- 現在の dev-workflow/SKILL.md の各セクション: L100-L121 (ASCII), L125-L138 (テーブル), L398-L464 (Step 7), L466-L505 (Step 8), L507-L539 (Step 9), L541- (Step 10), L720-L734 (コミット規約), L781-L792 (並列度), L819-L835 (ロールバック早見表)
- macOS coreutils: `gsed` 必須 (memory `feedback_sandbox_git.md` 等)

## 設計への含意

### 含意 1: 推奨置換順序 (降順)

Step 6 (Implementation) では以下の順序で機械置換を行う:

1. **(削除フェーズ)** `git rm -r plugins/dev-workflow/skills/specialist-self-reviewer/`、`git rm plugins/dev-workflow/agents/self-reviewer.md`、`git rm plugins/dev-workflow/skills/shared-artifacts/{templates,references}/self-review-report.md`
2. **(複合表現 placeholder 化)** 残ファイルに対し以下を grep し、各ヒットを `__SR_KEEP_<n>__` 等に一時置換 (gsed -i):
   - `Step 6 ↔ Step 7` (4 件、文字列維持だが意味再解釈で Edit 後)
   - `Step 6〜7` (10 件以上、文字列維持)
   - `Step 6/7` (2 件、文字列維持)
   - **これらは置換後も文字列として `Step 6 ↔ Step 7` のままなので、placeholder 戦略は単純に「文字列を保護して単独数字置換から守る」目的でのみ機能する**
3. **(単独数字降順置換)** 単独 `Step N`(N=10,9,8) を降順で gsed:

   ```sh
   # macOS は gsed
   gsed -i 's/\bStep 10\b/Step 9/g' <files>
   gsed -i 's/\bStep 9\b/Step 8/g' <files>
   gsed -i 's/\bStep 8\b/Step 7/g' <files>
   ```

4. **(placeholder 復元)** `__SR_KEEP_<n>__` を元の `Step 6 ↔ Step 7` 等に戻す
5. **(意味再解釈の Edit)** placeholder 復元後、以下は文脈ごと書き換え:
   - `templates/TODO.md` L4 の `(Implementation / Self-Review)` → `(Implementation / External Review)`
   - `dev-workflow/SKILL.md` L437-L464 の Self-Review ループ図 → External Review ループ図 (本文・ASCII 共に書き換え)
   - `dev-workflow/SKILL.md` L466- (旧 Step 8 = External Review) の本文に Self-Review 役割吸収を追記
   - `references/review-report.md` L121 の「Self-Review レポート (Step 7) とは別層」 → Self-Review 廃止文脈に再構築
   - その他 Self-Review 削除観点 (別 Research Note) で扱う 全 Self-Review 言及

### 含意 2: gsed コマンドのドラフト (Step 6 で実行)

```sh
# === 0. 前提: 削除対象ファイルは既に git rm 済み ===

# === 1. 対象ファイルセットを変数化 (Step 7-10 を含むファイル全件) ===
TARGETS=$(grep -rlE 'Step (7|8|9|10)\b' plugins/dev-workflow/)

# === 2. 複合表現を placeholder 化 (順序は気にしなくてよい、衝突しない記号を使う) ===
gsed -i 's/Step 6 ↔ Step 7/__SRK_67ARROW__/g' $TARGETS
gsed -i 's/Step 6〜7/__SRK_67TILDE__/g'        $TARGETS
gsed -i 's/Step 6\/7/__SRK_67SLASH__/g'        $TARGETS
gsed -i 's/Step 1〜5/__SRK_15TILDE__/g'        $TARGETS
gsed -i 's/Step 1〜3/__SRK_13TILDE__/g'        $TARGETS
# ※ Step 5 ↔ や Step 7 ↔ 等の他複合表現が新規発生していないか事前再 grep を推奨

# === 3. 単独数字を降順で置換 ===
gsed -i 's/\bStep 10\b/Step 9/g' $TARGETS
gsed -i 's/\bStep 9\b/Step 8/g'  $TARGETS
gsed -i 's/\bStep 8\b/Step 7/g'  $TARGETS

# === 4. placeholder 復元 ===
gsed -i 's/__SRK_67ARROW__/Step 6 ↔ Step 7/g' $TARGETS
gsed -i 's/__SRK_67TILDE__/Step 6〜7/g'       $TARGETS
gsed -i 's/__SRK_67SLASH__/Step 6\/7/g'       $TARGETS
gsed -i 's/__SRK_15TILDE__/Step 1〜5/g'       $TARGETS
gsed -i 's/__SRK_13TILDE__/Step 1〜3/g'       $TARGETS

# === 5. 検証 grep (期待: 旧 Step 7 = Self-Review 残骸が出ない) ===
grep -rnE 'Step (8|9|10)\b' plugins/dev-workflow/ || echo "all renumbered"
```

### 含意 3: Edit ツール必須箇所のリスト (gsed では対応不可)

機械置換後も以下は Edit で個別対応する (Step 6 タスク分解の独立サブタスクにする):

| 項目                     | ファイル                                          | 行               | 作業内容                                                                                                                     |
| ------------------------ | ------------------------------------------------- | ---------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| ASCII フロー図           | `dev-workflow/SKILL.md`                           | L100-L121        | `7. Self-Review` ノード行削除 + ループ矢印再配置 + 後続番号繰り上げ (gsed が誤爆する `7` を回避)                             |
| ステップ一覧テーブル     | `dev-workflow/SKILL.md`                           | L125-L138        | Self-Review 行削除 + 「主要成果物」列の `self-review-report.md` 削除                                                         |
| Step 6 ↔ Step 7 ループ図 | `dev-workflow/SKILL.md`                           | L437-L464        | self-reviewer 言及を reviewer に書き換え + ループ意味再解釈                                                                  |
| External Review 本文     | `dev-workflow/SKILL.md`                           | L466-L505        | Self-Review 役割吸収を追記 + Step 8 → Step 7 セクション番号変更 (gsed 適用後の最終確認 Edit)                                 |
| コミット規約テーブル     | `dev-workflow/SKILL.md`                           | L720-L734        | Self-Review 行 (L731) 削除 + 後続行 Step 番号は gsed で済むがテーブル整列の調整 Edit                                         |
| 並列起動ガイド           | `dev-workflow/SKILL.md`                           | L781-L792        | Self-Review 行 (L789) 削除                                                                                                   |
| ロールバック早見表       | `dev-workflow/SKILL.md`                           | L819-L835        | L829-L830 (Step 7 = Self-Review) 削除 or External Review に統合、`Step 9 → Step 4` を `Step 8 → Step 4` に gsed 後の最終確認 |
| 成果物一覧テーブル       | `shared-artifacts/SKILL.md`                       | L48-L56          | L52 (`self-review-report.md`) 削除 + 番号列 (`10`,`11`,`12`,`13`) 再付番                                                     |
| 保存構造 ASCII           | `shared-artifacts/SKILL.md`                       | L117-L133        | L125 (`self-review-report.md` コメント行) 削除                                                                               |
| progress.yaml            | `shared-artifacts/templates/progress.yaml`        | L39              | `self_review: null` 行削除                                                                                                   |
| progress-yaml reference  | `shared-artifacts/references/progress-yaml.md`    | L75-L78          | L75 (`self_review (Step 7)`) 削除 + 後続行 Step 番号は gsed で済む                                                           |
| TODO テンプレ            | `shared-artifacts/templates/TODO.md`              | L4               | `Self-Review` → `External Review` 文字列置換                                                                                 |
| retrospective テンプレ   | `shared-artifacts/templates/retrospective.md`     | L36-L38, L94-L95 | gsed 後の意味整合性確認 + Self-Review 廃止に伴うループ意味のコメント追記                                                     |
| review-report reference  | `shared-artifacts/references/review-report.md`    | L121             | `Self-Review レポート (Step 7) とは別層` を Self-Review 吸収文脈に書き換え                                                   |
| README                   | `plugins/dev-workflow/README.md`                  | L5, L19          | `ten specialist subagents`/`10-step lifecycle`/`Self-Review, External Review` を一斉書き換え                                 |
| plugin.json              | `plugins/dev-workflow/.claude-plugin/plugin.json` | L3               | description 文字列の `Self-Review` 削除 + 9-step 列挙                                                                        |

### 含意 4: 数字以外の表記揺れにも注意

`9 ステップ` / `10 ステップ` / `flat 10-step` / `ten specialist subagents` といった**数字スペル/英語表記**は単独 `Step N` の gsed では拾えない。先例 retrospective L31 で「shared-artifacts/references の取りこぼし」が指摘されたのと同型の取りこぼしリスクとして、Step 6 タスク分解で**英語表記・スペル表記の専用 grep + Edit タスク**を独立サブタスクにすべき:

```sh
grep -rnE '10[ -]?step|ten specialist|10 ステップ' plugins/dev-workflow/
```

該当ヒット:

- `dev-workflow/SKILL.md` L6 (`Step 10 (Retrospective) までフラットな 10 ステップ`)
- `dev-workflow/SKILL.md` L23 (`10 ステップをゲート式で進行させる`)
- `dev-workflow/SKILL.md` L663 (`10 ステップ構成と各ステップのゲート判定`)
- `README.md` L5 (`ten specialist subagents` / `flat 10-step lifecycle`)
- `.claude-plugin/plugin.json` L3 (`flat 9-step lifecycle` ← **既に 9-step と書いてあるが内容は 10-step の列挙、Intent Spec L102 で typo 認定**)

### 含意 5: ロールバック早見表のロジック整合性チェック

現状 L829-L835 の以下のエントリは数字シフト + ロジック再解釈が必要:

| 旧                                                                 | 新 (推奨)                                                          |
| ------------------------------------------------------------------ | ------------------------------------------------------------------ |
| `Step 7 / High 指摘 / Step 6` (L829)                               | (Self-Review 削除に伴い行ごと削除 OR External Review に統合)       |
| `Step 7 / 設計レベルの問題 / Step 3` (L830)                        | (同上、削除または External Review High 指摘 → Step 3 に統合)       |
| `Step 8 / Blocker 指摘 / Step 6` (L831)                            | `Step 7 / High/Blocker 指摘 / Step 6` (旧 Self-Review High と統合) |
| `Step 9 / 実装バグ / Step 6` (L832)                                | `Step 8 / 実装バグ / Step 6`                                       |
| `Step 9 / 設計ミス / Step 3` (L833)                                | `Step 8 / 設計ミス / Step 3`                                       |
| `Step 9 / 成功基準が不適切 / Step 1` (L834)                        | `Step 8 / 成功基準が不適切 / Step 1`                               |
| `Step 9 / テスト設計漏れ (qa-flow カバレッジ不足) / Step 4` (L835) | `Step 8 / テスト設計漏れ (qa-flow カバレッジ不足) / Step 4`        |

**ロジック再解釈の論点** (Self-Review 廃止観点別 Research Note と Step 3 Design で詰めるべき): 旧 Self-Review の「High 指摘 → Step 6」と「設計レベル問題 → Step 3」のロールバック条件を、新 Step 7 (External Review) のロールバック表現にどう統合するか。Intent Spec 未解決事項にも記載あり (L193, L194)。

## 残存する不明点

1. **Step 6 ↔ Step 7 ループの意味再解釈の最終形**: `Step 6 ↔ Step 7` という文字列は新旧で同じだが、旧 (Self-Review との往復) と新 (External Review との往復) で意味が変わる。本研究 Note では「文字列維持 + 文脈ごと Edit」と判定したが、Step 3 Design で「ループ図のキャプションを書き換える際に文字列レベルでも見分けが付くようにするか」を検討する余地あり (Self-Review 削除観点の Research Note で扱う)
2. **`Step 6/7` (Step 6/7 → Step 3) の意味**: retrospective テンプレでロールバック条件として現存。新運用では Implementation / External Review 中の設計レベル問題発見 → Step 3 という意味になる。ロールバック早見表の整合性 (含意 5) と合わせて Step 3 Design で確認
3. **`shared-artifacts/SKILL.md` L52-L55 の行番号列の連番再付番**: 現状 `8`/`9`/`10`/`11`/`12`/`13` で `10` 行 (self-review-report.md) を削除すると `8`/`9`/`10`/`11`/`12` になる。ただし Intent Spec L144 では「行番号が連番（欠番なし）で再付番されている」が成功基準なので、この行番号列も Edit で更新が必要 (gsed では拾えない数字)
4. **placeholder 戦略の代替手法選定**: 旧サイクルの `__SRK_*__` 形式は使用済みだが、本サイクルでも同型で問題ないか、それとも新規 ID にするか。retrospective に再利用可能パターンとして登録済みなので踏襲推奨だが、Step 6 で衝突防止の `grep -F __SRK_` 事前確認が必要

→ いずれも Step 3 Design で確定可能なレベル。Step 2 完了として Main に返却し、Self-Review 削除観点の別 Research Note (もしあれば) と統合した上で Design に進む判断を仰ぐ。
