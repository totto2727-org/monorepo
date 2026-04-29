# Research Note: Self-Review 関連表記の残存マッピング

- **Identifier:** 2026-04-29-integrate-self-review-into-external
- **Topic:** self-review-references
- **Researcher:** researcher-self-review-references
- **Created at:** 2026-04-29T00:00:00Z
- **Scope:** `plugins/dev-workflow/` 配下のみ。`.git/` / `node_modules` / 過去サイクル成果物 (`docs/dev-workflow/<過去サイクル>/`) は対象外。

## 調査対象

Intent Spec の「成功基準 5–8（残存表記の根絶）」を達成するための前提として、`plugins/dev-workflow/` 配下に存在する Self-Review 関連表記を全件洗い出し、Step 6 Implementation 時に「削除」「置換（置換先明示）」「文脈次第（design.md で確定）」のいずれを行うべきかを各ヒットに対して分類する。具体的には以下のパターン:

- `self-review` / `Self-Review` / `self_review` / `SelfReview`（大文字小文字・ハイフン・アンダースコア混在）
- `self-reviewer` / `specialist-self-reviewer`
- `self-review-report.md`

合計検出件数（重複行含む、grep ベース）:

| パターン | コマンド | 件数 |
| --- | --- | --- |
| `self[-_]review` (大文字小文字無視) | `grep -rnE -i 'self[-_]review|Self-Review' plugins/dev-workflow/` | 93 |
| `self-reviewer` / `specialist-self-reviewer` | `grep -rnE 'self-reviewer|specialist-self-reviewer' plugins/dev-workflow/` | 34 |
| `self-review-report.md` (固定文字列) | `grep -rnF 'self-review-report.md' plugins/dev-workflow/` | 19 |
| `self_review` (yaml キー) | `grep -rnF 'self_review' plugins/dev-workflow/skills/shared-artifacts/` | 4 |

なお検出は重複（1 行に複数パターンマッチ）を含むため、後述の「ファイル別 全ヒット表」では行番号ベースで一意に整理した。

## 発見事項

### 削除対象ファイル（grep ヒットの一括消滅元）

以下 4 つは `git rm` 対象であり、Edit による文脈調整は不要（ファイル丸ごと消える）:

1. `plugins/dev-workflow/skills/specialist-self-reviewer/SKILL.md`（98 行、grep ヒット 16 行）
2. `plugins/dev-workflow/agents/self-reviewer.md`（38 行、grep ヒット 9 行）
3. `plugins/dev-workflow/skills/shared-artifacts/templates/self-review-report.md`（62 行、grep ヒット 2 行）
4. `plugins/dev-workflow/skills/shared-artifacts/references/self-review-report.md`（89 行、grep ヒット 8 行）

これらの**ファイル削除のみで grep 件数の約 38％（93 件中の 35 件相当）が即時消える**。残りは Edit による単語置換 / 行削除 / 文脈書き換えで対応する。

### 残存ヒットのファイル別マッピング（削除ファイルを除く）

各ヒットに分類タグを付与:

- **DEL**: 行・段落単位の削除
- **REPL→X**: 単純置換（X は置換先）
- **CTX**: 文脈次第（design.md で運用方針が確定してから書き換え。多くは「Self-Review が担っていた役割を External Review が吸収する」旨の追記が必要）

#### `plugins/dev-workflow/.claude-plugin/plugin.json`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 3 | `description` 内 `... → Self-Review → External Review → ...` | REPL→`Intent → Research → Design → QA Design → Task Decomposition → Implementation → External Review → Validation → Retrospective`（Intent Spec 成功基準 15 の通り 9-step 列挙に正規化。Self-Review 言及削除） |

#### `plugins/dev-workflow/README.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 5 | `ten specialist subagents` 列挙に `self-reviewer` を含む | REPL→`nine specialist subagents`、`self-reviewer` を列挙から削除 |
| 5 | `flat 10-step lifecycle` | REPL→`flat 9-step lifecycle` |
| 7 | ステップ列挙 `... 7. Self-Review → 8. External Review → 9. Validation → 10. Retrospective` | REPL→`6. Implementation → 7. External Review → 8. Validation → 9. Retrospective` |
| 19 | AI-DLC 比較段落 `Research, QA Design, Self-Review, External Review, and Retrospective` | CTX（design 確定後に「Self-Review 言及削除」または「External Review (which absorbs the role of an internal self-review)」のような統合表現に書き換え） |

#### `plugins/dev-workflow/agents/reviewer.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 7 | `Do NOT use for: 複数観点の統合レビュー（self-reviewer を使う）` | DEL（後段の Step 7 reviewer は単一観点と全体整合性の両方を担うため、この除外条件自体を削除） |

#### `plugins/dev-workflow/agents/retrospective-writer.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 8 | `Do NOT use for: ... （self-reviewer を使う）、成功基準の実測判定（validator を使う）` | DEL（self-reviewer 言及を除外条件から削除） |
| 34 | `Self-Review Report / Review Reports / Validation Report)` | REPL→`Review Reports / Validation Report`（Self-Review Report 列挙を削除） |

#### `plugins/dev-workflow/agents/validator.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 8 | `Do NOT use for: ... （self-reviewer を使う）、設計妥当性の検証...` | DEL（self-reviewer 言及を除外条件から削除） |

#### `plugins/dev-workflow/skills/specialist-common/SKILL.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 5 | description 内 Specialist 名列挙 `... implementer, self-reviewer, ...` | DEL（`self-reviewer,` トークンを削除） |
| 14 | description 内 `specialist-implementer / specialist-self-reviewer /` | DEL（`specialist-self-reviewer /` トークンを削除） |

#### `plugins/dev-workflow/skills/specialist-intent-analyst/SKILL.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 10 | `レビュー（specialist-self-reviewer / specialist-reviewer）` | REPL→`レビュー（specialist-reviewer）` |

#### `plugins/dev-workflow/skills/specialist-implementer/SKILL.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 10 | `レビュー（specialist-self-reviewer / specialist-reviewer）` | REPL→`レビュー（specialist-reviewer）` |
| 104 | `自己レビュー（specialist-self-reviewer の領域）` | REPL→`外部レビュー（specialist-reviewer の領域）`（Intent Spec 「更新対象」項に明記された推奨表現） |

#### `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 13 | description `Do NOT use for: ... （specialist-self-reviewer、全観点統合の事前レビュー）、検証...` | DEL（specialist-self-reviewer 言及を除外条件から削除） |
| 48 | `**1 Specialist = 1 観点**。`specialist-implementer` / `specialist-self-reviewer` とは別個の新規インスタンス` | REPL→`**1 Specialist = 1 観点**。`specialist-implementer` とは別個の新規インスタンス` |

なお、本ファイルには Intent Spec 成功基準 11 で要求される「全体整合性チェック」「implementer 直後の手戻り抑止」を吸収した旨の追記が必要だが、これは grep ヒットを伴わない**新規追加**作業のため本マッピングの対象外（Step 6 Implementation 時に別途差し込む）。

#### `plugins/dev-workflow/skills/specialist-validator/SKILL.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 9 | `Do NOT use for: レビュー（specialist-reviewer）、自己レビュー（specialist-self-reviewer）` | DEL（`、自己レビュー（specialist-self-reviewer）` トークンを削除） |

#### `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 12 | description 内 `... specialist-self-reviewer）、実装（specialist-implementer）、...` | DEL（`specialist-self-reviewer）、` トークンを削除し、直前の `specialist-reviewer` で除外条件を閉じる） |
| 49 | `Self-Review / Review Reports / Validation Report` | REPL→`Review Reports / Validation Report`（Self-Review 列挙を削除） |
| 51 | `TODO.md（re_activations カウンタ、タスク完了時間、Self-Review ループ履歴）` | REPL→`TODO.md（re_activations カウンタ、タスク完了時間、External Review ループ履歴）` |
| 97 | `実装の評価（Self-Review / External Review で既に完了済み）` | REPL→`実装の評価（External Review で既に完了済み）` |

#### `plugins/dev-workflow/skills/dev-workflow/SKILL.md`

ステップ番号繰り上げ（`Step 8→7` / `Step 9→8` / `Step 10→9`）と Self-Review セクションそのものの削除が混在するため、行ごとに分類:

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 112 | フロー図 ASCII `7. Self-Review ───────────┤──┘ (Gate: Main 判定)` | DEL（行ごと削除し、後続行の番号を 1 ずつ繰り上げ） |
| 135 | ステップ一覧テーブル行 `\| 7    \| Self-Review          \| ...` | DEL（テーブル行ごと削除し、後続 4 行を Step 7/8/9 に繰り上げ） |
| 343 | `タスク再活性化時 (Self-Review High 指摘で Step 6 に戻った場合等)` | REPL→`タスク再活性化時 (External Review High/Blocker 指摘で Step 6 に戻った場合等)`（深刻度ラベルの最終形は design.md で確定） |
| 398 | セクション見出し `### Step 7: Self-Review (自己レビュー)` | DEL（L398–L464 のセクション全体を削除。Intent Spec で明示） |
| 402 | `**起動 Specialist:** `self-reviewer` × 1` | DEL（同セクション削除に含まれる） |
| 408 | `1. `self-reviewer` を起動し、全 diff (Step 6 で生成)...` | DEL（同上） |
| 411 | `4. Medium / Low 指摘は Self-Review Report に記録し、Step 8 (External Review) の判断材料とする` | DEL（同上） |
| 412 | `5. 最終的に High 0 件を確認して Exit Criteria 判定 (Step 7 の `self-reviewer` は Exit Criteria 確定まで維持)` | DEL（同上） |
| 414 | `**成果物:** ... `self-review-report.md` ...` | DEL（同上） |
| 421 | `- `self-review-report.md` + `progress.yaml` がコミット済み` | DEL（同上） |
| 428 | `- `self-reviewer` の指摘が実装者と矛盾 → ...` | DEL（同上） |
| 429 | `- 個別指摘に曖昧さ → **既存の `self-reviewer` インスタンス**...` | DEL（同上） |
| 433 | `- `self-reviewer` は `implementer` と**異なる新規インスタンス**として起動する` | DEL（同上） |
| 434 | `- Step 7 の `self-reviewer` は Step 7 の Exit Criteria が確定するまで維持する...` | DEL（同上） |
| 437 | 見出し `#### Step 6 ↔ Step 7 ループ` | CTX（Intent Spec「更新対象」項により、見出しは「Step 6 ↔ Step 7 (External Review) ループ」として残し、本文を External Review ループの説明に書き換える方針） |
| 446 | ASCII 図内 `[Step 7 活性化] self-reviewer B1 起動` | CTX（ASCII 図を External Review 並列起動に書き換え。reviewer B1..Bn の表現になる見込み） |
| 464 | `**ループ上限の目安:** 同一 Self-Review Report の High 指摘で 3 周以上...` | CTX（Self-Review Report → External Review Reports に置換、深刻度ラベルは design 確定。知見そのものは外部レビューに移植） |
| 485 | `2. 観点ごとに `reviewer` を **並列起動** (Step 6 / 6 の `implementer` / `self-reviewer` とは**別個の新規インスタンス**)` | REPL→`2. 観点ごとに `reviewer` を **並列起動** (Step 6 の `implementer` とは**別個の新規インスタンス**)` |
| 697 | 矛盾判定例の表 `Self-Review の汎用観点、プロジェクトに固有のレビュー観点あり` | REPL→`External Review の汎用観点、プロジェクトに固有のレビュー観点あり` |
| 731 | コミット規約表 `\| 7. Self-Review          \| `self-review-report.md` + `progress.yaml`` | DEL（行ごと削除。後続テーブル行の番号を 1 つ繰り上げ） |
| 739 | `- Self-Review High 指摘で再実装する場合、**修正コミットも別途作成**` | REPL→`- External Review High/Blocker 指摘で再実装する場合、**修正コミットも別途作成**`（深刻度ラベルは design 確定） |
| 789 | 並列度表 `\| 7. Self-Review          \| 低             \| 全体整合性が必要なので原則 1 名` | DEL（行ごと削除。後続 3 行を Step 7/8/9 に繰り上げ） |
| 829–830 | ロールバック早見表 `\| Step 7       \| High 指摘                               \| Step 6` / `\| Step 7       \| 設計レベルの問題                        \| Step 3` | CTX（旧 Step 7 = Self-Review 由来エントリ。Intent Spec 成功基準 10 により、新 Step 7 = External Review に統合された形で記載すべき。「Step 7 \| Blocker 指摘 \| Step 6」「Step 7 \| 設計レベルの問題 \| Step 3」のような形に書き換える方針。深刻度ラベルは design.md で確定） |

加えて L831–L835（旧 Step 8 → Step 7、旧 Step 9 → Step 8）は grep にはヒットしないが、ステップ番号繰り上げの一環として Step 6 Implementation で Edit 対象。

#### `plugins/dev-workflow/skills/shared-artifacts/SKILL.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 52 | 成果物一覧テーブル行 `\| 10  \| `self-review-report.md`       \| Step 7         \| `self-reviewer` ...` | DEL（行削除。後続 3 行 #11/#12/#13 を #10/#11/#12 に繰り上げ。同時に各行の Step 列を 8→7 / 9→8 / 10→9 に更新） |
| 125 | 保存構造 ASCII 図 `├── self-review-report.md      # Step 7 成果物` | DEL（行削除。同時に L126 `review/` のコメントを `Step 7 成果物` に更新、L130 `validation-report.md` を Step 8、L133 `retrospective.md` を Step 9 に再付番） |

#### `plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 39 | `  self_review: null # self-review-report.md` | DEL（フィールドごと削除。Intent Spec 成功基準 13 で 0 件確認） |

#### `plugins/dev-workflow/skills/shared-artifacts/templates/TODO.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 4 | `- **Active Steps:** Step 6〜7 (Implementation / Self-Review)` | REPL→`- **Active Steps:** Step 6〜7 (Implementation / External Review)` |
| 27 | `re_activations: {{t1_re_activations}} <!-- Self-Review High 指摘で Step 6 に戻った回数 -->` | REPL→`re_activations: {{t1_re_activations}} <!-- External Review High/Blocker 指摘で Step 6 に戻った回数 -->`（深刻度ラベルは design 確定） |
| 47 | `- Self-Review High 指摘で戻す場合: `completed` → `in_progress` に戻し、`re_activations` をインクリメント` | REPL→`- External Review High/Blocker 指摘で戻す場合: `completed` → `in_progress` に戻し、`re_activations` をインクリメント` |
| 55 | `  - `docs(dev-workflow/{{identifier}}): re-activate task T1 (self-review feedback)`` | REPL→`  - `docs(dev-workflow/{{identifier}}): re-activate task T1 (external-review feedback)`` |

#### `plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 72 | `- `self-reviewer`: {{self_reviewer_improvement}}` | DEL（プレースホルダ行ごと削除。Intent Spec「更新対象」項に明記） |

#### `plugins/dev-workflow/skills/shared-artifacts/templates/implementation-log.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 56 | `Self-Review および Retrospective の材料となる。` | REPL→`External Review および Retrospective の材料となる。` |
| 64 | `逸脱がある場合は Self-Review で確認され、必要なら Design への差し戻し判断材料となる。` | REPL→`逸脱がある場合は External Review で確認され、必要なら Design への差し戻し判断材料となる。` |

#### `plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 75 | `- `self_review` (Step 7) — `self-review-report.md`` | DEL（フィールド説明行ごと削除。同時に L76 `review` を Step 7、L77 `validation` を Step 8、L78 `retrospective` を Step 9 に再付番。後者は grep ヒットなし） |

#### `plugins/dev-workflow/skills/shared-artifacts/references/review-report.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 5 | `Self-Review（全体整合性）とは別層で、観点固有の深い検査を行う。` | CTX（Intent Spec「更新対象」明記。Self-Review 廃止・吸収を反映し、たとえば「観点固有の深い検査と、全体整合性チェック（旧 Self-Review が担っていた役割）の両方を扱う」のような統合表現に書き換える方針。最終文言は design.md で確定） |
| 121 | `- Self-Review レポート（Step 7）とは**別層**。内容が重複することはあるが独立して作成` | DEL（外部レビューが Self-Review の役割を吸収するため、別層という記述自体が不整合。代わりに「観点固有の指摘と全体整合性チェックを兼ねる」旨を design 確定後に追記） |

#### `plugins/dev-workflow/skills/shared-artifacts/references/todo.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 61 | `- **re_activations**: Self-Review High 指摘で Step 6 に戻った回数` | REPL→`- **re_activations**: External Review High/Blocker 指摘で Step 6 に戻った回数` |
| 68 | `- Self-Review High 指摘で戻す場合: `completed` → `in_progress` に戻し、`re_activations` をインクリメント` | REPL→`- External Review High/Blocker 指摘で戻す場合: `completed` → `in_progress` に戻し、`re_activations` をインクリメント` |
| 91 | `- **参照:** Self-Review での High 指摘 → 該当タスクを `re_activations` カウントアップして `in_progress` に戻す` | REPL→`- **参照:** External Review での High/Blocker 指摘 → 該当タスクを `re_activations` カウントアップして `in_progress` に戻す` |

#### `plugins/dev-workflow/skills/shared-artifacts/references/implementation-log.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 51 | `Self-Review や Retrospective の材料となる。` | REPL→`External Review や Retrospective の材料となる。` |
| 55 | `逸脱がある場合は理由と Self-Review への引き継ぎを明記する。` | REPL→`逸脱がある場合は理由と External Review への引き継ぎを明記する。` |
| 69 | `- **出力先:** `self-review-report.md`（self-reviewer が参照）、`retrospective.md`（学びの抽出）` | REPL→`- **出力先:** `review/<aspect>.md`（reviewer が参照）、`retrospective.md`（学びの抽出）` |

#### `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md`

| 行 | 内容 | 分類 |
| --- | --- | --- |
| 98 | `- `self-review-report.md` の修正ラウンド履歴` | REPL→`- `review/<aspect>.md` の修正ラウンド履歴` |

加えて、`references/retrospective.md` 自体には grep でヒットしない箇所（Step 6 ↔ Step 7 ループ表 / `self_reviewer_improvement` プレースホルダ説明）も Intent Spec の「更新対象」項に明記されているが、それらはステップ番号変更の作業（Self-Review 直接表記ではない）として Step 6 Implementation で別途扱う。

### 表記揺れの観察事項

- 大文字小文字混在: `Self-Review`（タイトルケース、文中のステップ名表記）と `self-review`（ファイル名・yaml キー）が共存。`grep -i` で同時カバーされている
- アンダースコア表記 `self_review` は yaml フィールド名 (`progress.yaml` L39) と Reference 文 (`progress-yaml.md` L75) のみ。テンプレートのプレースホルダ `{{self_reviewer_instance_id}}` (templates/self-review-report.md L3) と `{{self_reviewer_improvement}}` (templates/retrospective.md L72) も同形（ただし前者は削除対象ファイル内なので無視可）
- `SelfReview` (キャメルケース) の検出は **0 件**。本サイクルで考慮不要
- `self-reviewer` 単独表記と `specialist-self-reviewer` 表記が混在。前者は agent 名、後者は skill 名。スキル名→消滅、エージェント名→消滅 という整理になるが、文中言及はそれぞれ異なる文脈

### Self-Review が担っていた知見の保存先（Intent Spec 未解決事項のヒント）

以下の知見は Self-Review に固有のため、削除しっぱなしにすると失われる。Step 3 Design で External Review 側に移植する設計判断が必要:

- `dev-workflow/SKILL.md:464` の「3 周以上ループしたら Step 3 ロールバック検討」ルール
- `references/self-review-report.md:11` の「Main 判定。High 指摘残があれば Step 6 に戻る」ループ運用
- `references/self-review-report.md:64–73` の Self-Review 焦点リスト（design 違反 / Intent Spec 未達 / 明白な bug / Task Plan 未対応 / テスト網羅 / 型・エラーハンドリング）
- `dev-workflow/SKILL.md:437–462` の Step 6 ↔ Step 7 ループ ASCII 図とインスタンス維持ルール

これらは削除ファイル本体に存在するため Step 6 Implementation 時に「先に design.md で吸収方針が確定していないと、知見ごと消える」リスクがある。

## 引用元

- `plugins/dev-workflow/.claude-plugin/plugin.json:3`
- `plugins/dev-workflow/README.md:5`
- `plugins/dev-workflow/README.md:7`
- `plugins/dev-workflow/README.md:19`
- `plugins/dev-workflow/agents/reviewer.md:7`
- `plugins/dev-workflow/agents/retrospective-writer.md:8`
- `plugins/dev-workflow/agents/retrospective-writer.md:34`
- `plugins/dev-workflow/agents/self-reviewer.md`（ファイル丸ごと削除対象、L3/5/9/11/16/22/23/24/25 にヒット）
- `plugins/dev-workflow/agents/validator.md:8`
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:112`
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:135`
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:343`
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:398–464`
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:485`
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:697`
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:731`
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:739`
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:789`
- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:829–830`
- `plugins/dev-workflow/skills/specialist-common/SKILL.md:5`
- `plugins/dev-workflow/skills/specialist-common/SKILL.md:14`
- `plugins/dev-workflow/skills/specialist-implementer/SKILL.md:10`
- `plugins/dev-workflow/skills/specialist-implementer/SKILL.md:104`
- `plugins/dev-workflow/skills/specialist-intent-analyst/SKILL.md:10`
- `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md:12`
- `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md:49`
- `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md:51`
- `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md:97`
- `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md:13`
- `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md:48`
- `plugins/dev-workflow/skills/specialist-self-reviewer/SKILL.md`（ファイル丸ごと削除対象）
- `plugins/dev-workflow/skills/specialist-validator/SKILL.md:9`
- `plugins/dev-workflow/skills/shared-artifacts/SKILL.md:52`
- `plugins/dev-workflow/skills/shared-artifacts/SKILL.md:125`
- `plugins/dev-workflow/skills/shared-artifacts/references/implementation-log.md:51`
- `plugins/dev-workflow/skills/shared-artifacts/references/implementation-log.md:55`
- `plugins/dev-workflow/skills/shared-artifacts/references/implementation-log.md:69`
- `plugins/dev-workflow/skills/shared-artifacts/references/progress-yaml.md:75`
- `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md:98`
- `plugins/dev-workflow/skills/shared-artifacts/references/review-report.md:5`
- `plugins/dev-workflow/skills/shared-artifacts/references/review-report.md:121`
- `plugins/dev-workflow/skills/shared-artifacts/references/self-review-report.md`（ファイル丸ごと削除対象）
- `plugins/dev-workflow/skills/shared-artifacts/references/todo.md:61`
- `plugins/dev-workflow/skills/shared-artifacts/references/todo.md:68`
- `plugins/dev-workflow/skills/shared-artifacts/references/todo.md:91`
- `plugins/dev-workflow/skills/shared-artifacts/templates/TODO.md:4`
- `plugins/dev-workflow/skills/shared-artifacts/templates/TODO.md:27`
- `plugins/dev-workflow/skills/shared-artifacts/templates/TODO.md:47`
- `plugins/dev-workflow/skills/shared-artifacts/templates/TODO.md:55`
- `plugins/dev-workflow/skills/shared-artifacts/templates/implementation-log.md:56`
- `plugins/dev-workflow/skills/shared-artifacts/templates/implementation-log.md:64`
- `plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml:39`
- `plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md:72`
- `plugins/dev-workflow/skills/shared-artifacts/templates/self-review-report.md`（ファイル丸ごと削除対象）
- Intent Spec: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/intent-spec.md`（特に「スコープ → 削除対象 / 更新対象」「成功基準 → 残存表記の根絶」）

grep ベースの全件を取得した一次データ:

- `/tmp/claude/grep_self_review_all.txt`（93 行、`-i` で `self[-_]review|Self-Review` 全網羅）
- `/tmp/claude/grep_self_reviewer.txt`（34 行、`self-reviewer|specialist-self-reviewer`）
- `/tmp/claude/grep_self_review_report.txt`（19 行、固定文字列 `self-review-report.md`）
- `/tmp/claude/grep_self_review_yaml.txt`（4 行、shared-artifacts 配下の `self_review`）

## 設計への含意

### 機械置換可能 vs 文脈考慮が必要 の整理

Step 6 Implementation を効率化するため、各ヒットを 3 種に再分類:

#### A. 機械置換可能（Edit の `replace_all` または gsed で一括処理可能）

すべて単発の単語置換。ステップ番号の繰り上げや前後コンテキストへの影響がないもの:

- `specialist-self-reviewer / specialist-reviewer` → `specialist-reviewer`（specialist-implementer/SKILL.md:10, specialist-intent-analyst/SKILL.md:10）
- `自己レビュー（specialist-self-reviewer の領域）` → `外部レビュー（specialist-reviewer の領域）`（specialist-implementer/SKILL.md:104）
- `Self-Review や Retrospective` → `External Review や Retrospective`（implementation-log.md:51, templates/implementation-log.md:56）
- `Self-Review への引き継ぎ` → `External Review への引き継ぎ`（implementation-log.md:55）
- `Self-Review で確認され` → `External Review で確認され`（templates/implementation-log.md:64）
- `Self-Review の汎用観点` → `External Review の汎用観点`（dev-workflow/SKILL.md:697）
- `(self-review feedback)` → `(external-review feedback)`（templates/TODO.md:55）
- `self-review-report.md` の修正ラウンド履歴 → `review/<aspect>.md` の修正ラウンド履歴（references/retrospective.md:98）

#### B. 行・段落単位の削除

- `agents/self-reviewer.md` 全削除
- `skills/specialist-self-reviewer/` ディレクトリ全削除
- `templates/self-review-report.md` / `references/self-review-report.md` 全削除
- `dev-workflow/SKILL.md:398–464`（Step 7 Self-Review セクションと Step 6 ↔ Step 7 ループ説明の旧版）
- `dev-workflow/SKILL.md:135` のステップ一覧テーブル行
- `dev-workflow/SKILL.md:112` のフロー図 Self-Review 行
- `dev-workflow/SKILL.md:731` のコミット規約表行
- `dev-workflow/SKILL.md:789` の並列度表行
- `shared-artifacts/SKILL.md:52` の成果物一覧テーブル行
- `shared-artifacts/SKILL.md:125` の保存構造 ASCII 行
- `templates/progress.yaml:39` の `self_review:` フィールド
- `templates/retrospective.md:72` の `self-reviewer` プレースホルダ
- `references/progress-yaml.md:75` の `self_review` 説明行
- 各 agent / specialist スキルの description 内 `（self-reviewer を使う）` / `specialist-self-reviewer` トークン削除（agents/reviewer.md:7, agents/retrospective-writer.md:8, agents/validator.md:8, specialist-validator/SKILL.md:9, specialist-reviewer/SKILL.md:13, specialist-retrospective-writer/SKILL.md:12, specialist-common/SKILL.md:5/14）

#### C. 文脈考慮が必要（design.md 確定後に Edit で書き換え）

設計判断が前提となる箇所。design.md でこれらの方針が決まらないと書き換えられない:

- `README.md:19` の AI-DLC 比較段落の Self-Review 言及（残す/消す/統合表現の選択）
- `dev-workflow/SKILL.md:343/411/412/421/428/429/433/434/437/446/464/485/697/739/789/829–830` のうち、深刻度ラベル統合と外部レビュー吸収の文言が必要なもの
- `dev-workflow/SKILL.md:437–464` の Step 6 ↔ Step 7 ループ ASCII 図の書き換え
- `dev-workflow/SKILL.md:829–830` のロールバック早見表 Step 7 エントリ統合
- `references/review-report.md:5` の「Self-Review（全体整合性）とは別層」を「外部レビューが両役割を担う」に書き換える文言
- `references/review-report.md:121` の「Self-Review レポート（Step 7）とは別層」削除
- `specialist-reviewer/SKILL.md` への「全体整合性チェック」「implementer 直後の手戻り抑止」吸収の追記（grep ヒットを伴わない新規追加だが、design 確定が前提）
- `agents/retrospective-writer.md:34` および `specialist-retrospective-writer/SKILL.md:49/51/97` の Self-Review 言及削除（深刻度ラベル統合の影響を受ける）

#### D. ステップ番号繰り上げに付随する作業（grep `self-review` には直接ヒットしないが Step 6 Implementation で同時に対処すべき）

成功基準 7（`Step 10` 0 件）と 8（`Step 9 (Validation)` / `Step 10 (Retrospective)` 0 件）達成のため:

- `dev-workflow/SKILL.md` 内のステップ番号 `Step 8` → `Step 7`、`Step 9` → `Step 8`、`Step 10` → `Step 9`（Intent Spec 制約で**降順置換**が必須。不用意な一括置換は連鎖二重置換を起こす）
- `agents/reviewer.md`（Step 8 → Step 7）、`agents/validator.md`（Step 9 → Step 8）、`agents/retrospective-writer.md`（Step 10 → Step 9）の description / 本文
- `specialist-reviewer/SKILL.md` / `specialist-validator/SKILL.md` / `specialist-retrospective-writer/SKILL.md` の description / 本文
- `shared-artifacts/SKILL.md`（成果物一覧テーブル / 保存構造 ASCII）
- `references/progress-yaml.md`（フィールド説明行の Step 番号）
- `references/intent-spec.md:36`（Step 9 言及）など

これらは本研究の主題（self-review 表記の根絶）とは別タスクだが、**同一行で両方が混在するケースが多い**ため、Step 6 Implementation では Self-Review 削除 → ステップ番号繰り上げの順で 1 ファイルずつ処理することを推奨。逆順だと番号繰り上げ後に Self-Review 行を削除した際の連番再付番が複雑化する。

### 削除順の推奨フロー

1. **Phase 1: ファイル削除**（4 ファイル / 1 ディレクトリの `git rm`）→ grep 件数が約 38％減
2. **Phase 2: 機械置換可能な単純置換**（A 群）→ 文脈非依存で安全
3. **Phase 3: 行・段落削除**（B 群）→ ステップ一覧テーブル / コミット規約表 / 並列度表 / フロー図 / yaml フィールドなど構造的箇所。同時にテーブル番号の連番再付番
4. **Phase 4: ステップ番号繰り上げ**（D 群）→ Intent Spec 制約に従い**降順**で `Step 10 → 9 → 8 → 7` に置換
5. **Phase 5: 文脈考慮の書き換え**（C 群）→ design.md の運用判断を反映した最終文言を Edit で投入
6. **Phase 6: 検証**（後述 grep コマンド）→ 0 件確認

### 検証用 grep コマンドの最終形（Intent Spec 成功基準 5–8）

成功基準 5–8 を Step 8 Validation で機械的に検証可能にするため、以下のコマンドセットを推奨。`.git/` 除外と隠しディレクトリ無視を厳密化:

```bash
# 成功基準 5: self-review 表記の全消し
grep -rnE -i 'self[-_]review|Self-Review' \
  --exclude-dir=.git --exclude-dir=node_modules \
  plugins/dev-workflow/

# 成功基準 6: self-reviewer / specialist-self-reviewer の全消し
grep -rnE 'self-reviewer|specialist-self-reviewer' \
  --exclude-dir=.git --exclude-dir=node_modules \
  plugins/dev-workflow/

# 成功基準 7: Step 10 表記の全消し
grep -rnF 'Step 10' \
  --exclude-dir=.git --exclude-dir=node_modules \
  plugins/dev-workflow/

# 成功基準 8: 旧番号での Step 9 (Validation) / Step 10 (Retrospective) 表記が二重存在しない
grep -rnE 'Step 9 \(Validation\)|Step 10 \(Retrospective\)' \
  --exclude-dir=.git --exclude-dir=node_modules \
  plugins/dev-workflow/

# 成功基準 13 補助: progress.yaml の self_review フィールド非存在
grep -nE '^\s*self_review:' \
  plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml

# 削除確認: 4 つの削除対象が消えたか
test ! -d plugins/dev-workflow/skills/specialist-self-reviewer && \
test ! -f plugins/dev-workflow/agents/self-reviewer.md && \
test ! -f plugins/dev-workflow/skills/shared-artifacts/templates/self-review-report.md && \
test ! -f plugins/dev-workflow/skills/shared-artifacts/references/self-review-report.md && \
echo "DELETED OK"
```

すべて 0 件 / `DELETED OK` が出力される状態を成功条件とする。

### 削除対象ファイルとマッピングの重複整理

`grep -rnE -i 'self[-_]review' plugins/dev-workflow/` の 93 件のうち、**35 件以上は削除対象 4 ファイル内のヒット**。Phase 1 でファイルを `git rm` した時点で grep 件数は約 58 件まで自動的に減る。残りの 58 件のうち、機械置換可能な約 25–30 件を Phase 2 で処理し、文脈考慮（C 群）が必要な 10–15 件を Phase 5 で処理することで、全体作業時間の 70％は文脈非依存で安全に進められる見込み。

特に **`dev-workflow/SKILL.md` の L398–L464 の Self-Review セクション全体（67 行）の DEL** は単一 Edit で完了するため、これだけで grep ヒットの大部分が消える。実装順序として「先にこのセクションを削除 → その後個別ヒットを処理」が効率的。

### Self-Review 知見の保存責任の前置き

「設計への含意」として最も重要なのは、削除対象ファイルに含まれる**運用知見**（特に `references/self-review-report.md` の Self-Review 焦点リストと、`dev-workflow/SKILL.md:464` の「3 周以上ループしたら Step 3 ロールバック」ルール）が**消滅前に design.md / specialist-reviewer/SKILL.md に移植**されている必要がある点。Step 6 Implementation 着手前に design.md で「外部レビューが吸収する旧 Self-Review の知見一式」を明文化しておかないと、ファイル削除と同時に知見が失われる。

これは Intent Spec 未解決事項の「旧 Step 7 (Self-Review) のループ知見の保存先」と直結する。design.md でこの保存先（specialist-reviewer 本文 / retrospective.md / dev-workflow/SKILL.md の External Review セクション）を確定する必要がある。

## 残存する不明点

- **深刻度ラベル統合の最終形**: 旧 Self-Review は `High/Medium/Low`、旧 External Review は `Blocker/Major/Minor` の可能性。本研究では便宜上「High/Blocker」「Medium/Major」のように併記してマッピングしたが、Intent Spec 未解決事項で明示の通り design.md で統一が必要。確定後に C 群の文脈書き換えが可能になる
- **`reviewer` 観点列の最終形**: 「全体整合性観点」を独立観点として追加するか既存観点に分散吸収するかが design 未確定。前者の場合、`shared-artifacts/SKILL.md:52` の review 行や `dev-workflow/SKILL.md` の External Review 観点例（L477–L481）に新観点を追加する作業が C 群に追加される
- **`progress.yaml` の `review:` 構造**: リスト形式維持か別フィールド分離かが未確定。本研究では既存リスト構造を仮定したが、構造変更があれば `templates/progress.yaml` / `references/progress-yaml.md` への影響範囲が広がる
- **`dev-workflow/SKILL.md:437–464` ASCII 図の最終構造**: External Review が並列で複数 reviewer を持つため、Self-Review 単体の B1 図とは構造が大きく変わる。design.md で External Review ループの ASCII 表現が確定するまで C 群として保留
- **過去サイクル成果物 (`docs/dev-workflow/2026-04-*/`) を grep 検証から除外する仕組み**: Intent Spec 制約「過去サイクル遡及修正禁止」と整合させるため、検証用 grep は `plugins/dev-workflow/` 配下のみを対象にしている（成功基準コマンドもそうなっている）。万一 `docs/` 配下の過去サイクル文書に Self-Review 表記が残っていてもそれは**意図的に保持**する点を Step 8 Validation で明文化する必要がある（本研究のスコープ外）
