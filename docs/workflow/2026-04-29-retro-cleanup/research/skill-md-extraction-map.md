# Research Note: skill-md-extraction-map

- **Identifier:** 2026-04-29-retro-cleanup
- **Topic:** skill-md-extraction-map <!-- existing-impl: dev-workflow/SKILL.md と specialist-common/SKILL.md の章節マッピング・切り出し境界・サイズ見積もり -->
- **Researcher:** researcher (Step 2 / 観点: SKILL.md extraction boundaries)
- **Created at:** 2026-04-29T11:30:00Z
- **Scope:** `plugins/dev-workflow/skills/dev-workflow/SKILL.md` (820 行) と `plugins/dev-workflow/skills/specialist-common/SKILL.md` (228 行) の現状章節マッピング、`references/` 切り出し候補セクションの境界・行数見積もり、本体に残すサマリの最小行数推定。Step 3 architect が機械的に切り出し設計を確定できる粒度まで掘り下げる。description 圧縮 (Intent Spec スコープ B) と本文追記 (スコープ C, D) は本観点の範囲外。

## 調査対象

Intent Spec の以下に対応する事実を整理する:

- **成功基準 #1**: `dev-workflow/SKILL.md` を 500 行以下に圧縮する根拠（820 → ≤500 = 320 行以上の純減が必要）
- **成功基準 #2**: `specialist-common/SKILL.md` を 180 行以下に圧縮する根拠（228 → ≤180 = 48 行以上の純減が必要）
- **成功基準 #3-4**: `references/` ディレクトリ新規作成（dev-workflow / specialist-common 双方）
- **成功基準 #5-6**: `references/` 配下に最低 2 ファイルずつ
- **未解決事項**: 切り出し粒度（2 ファイル vs 4 ファイル）、specialist-common の追加切り出し範囲（並列挙動 / 秘匿情報の取り扱いも含めるか）の確定材料を提供する

## 発見事項

### F-1. `dev-workflow/SKILL.md` は実測 820 行（Intent Spec の 820 行と一致）

`gwc -l plugins/dev-workflow/skills/dev-workflow/SKILL.md` の実測結果は 820 行。Intent Spec 記載の現状値と一致する。

### F-2. `specialist-common/SKILL.md` は実測 228 行（Intent Spec の 228 行と一致）

`gwc -l plugins/dev-workflow/skills/specialist-common/SKILL.md` の実測結果は 228 行。Intent Spec 記載の現状値と一致する。

### F-3. `dev-workflow/SKILL.md` の章節マップ（H2 単位、行範囲は次見出し直前まで）

| H2 セクション                                           | 開始行 | 終了行 |    行数 | 内容要約                                                                                                                                                                                                                                                        |
| ------------------------------------------------------- | -----: | -----: | ------: | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| (frontmatter)                                           |      1 |     16 |      16 | YAML frontmatter（description 含む）                                                                                                                                                                                                                            |
| `# dev-workflow — Multi-Agent Development Workflow`     |     18 |     23 |       6 | サブタイトル + 1 段落の概要                                                                                                                                                                                                                                     |
| `## 基本方針`                                           |     25 |     53 |      29 | 9 個の方針（箇条書き、各 2-7 行）。Main-Centric / Single-Source-of-Progress / One-Shot Specialist / Gate-Based / Artifact-Driven / Project-Rule Precedence / Commit-Based Resumability / Clean-Transition / Artifact-as-Gate-Review / Report-Based Confirmation |
| `## 役割定義`                                           |     56 |     95 |      40 | Main / Specialist の責務・原則。表形式ではなく箇条書き                                                                                                                                                                                                          |
| `## ワークフロー全体図`                                 |     97 |    121 |      25 | ASCII フローチャート（9 ステップ + ループ）                                                                                                                                                                                                                     |
| `## ステップ一覧`                                       |    123 |    139 |      17 | 9 行の Markdown 表（Step 番号 / 名称 / Specialist / Gate / 成果物 / 詳細スキル）                                                                                                                                                                                |
| `## ステップ詳細`                                       |    141 |    542 | **402** | 9 ステップ全ての詳細（最大の塊。L145-L542）                                                                                                                                                                                                                     |
| `## 調整プロトコル (Main ↔ Specialist)`                 |    545 |    611 |  **67** | 1. ワークフロー開始時 / 2. ステップ実行ループ / 3. ゲート通過時 / 4. Blocker 発生時 / 5. セッション再開時                                                                                                                                                       |
| `## 成果物テンプレート・保存構造・進捗記録フォーマット` |    614 |    631 |      18 | shared-artifacts への参照リンク集（既に切り出し済み、ASCII 図の重複なし）                                                                                                                                                                                       |
| `## プロジェクト固有ルールとの関係`                     |    633 |    682 |  **50** | 従う領域 / 優先する領域 / 適用手順 / 矛盾の判定例（5 行表）/ Specialist への伝達                                                                                                                                                                                |
| `## ステップ完了時のコミット規約`                       |    684 |    752 |  **69** | 原則 / ステップ別コミット内訳（11 行表）/ ユーザー承認ゲート通過時 / コミットメッセージ規約 / コミット前チェック / 一時ファイルの扱い                                                                                                                           |
| `## 並列起動のガイドライン`                             |    754 |    768 |      15 | 9 行の表（Step / 推奨度 / 並列軸）                                                                                                                                                                                                                              |
| `## 逸脱時のリカバリ`                                   |    770 |    810 |  **41** | スコープ変更 / 期待外成果物 / 整合性崩れ / ロールバック先早見表（17 行表 = L791-L809）                                                                                                                                                                          |
| `## このスキルが扱わないこと`                           |    812 |    820 |       9 | スキルの非対象事項 7 行                                                                                                                                                                                                                                         |

合計: 820 行（frontmatter 16 + コンテンツ 804）。

### F-4. `## ステップ詳細` セクション（L141-L542、402 行）の内訳

最大の塊なので、サブセクション別に分解する:

| サブセクション                                                      | 開始行 | 終了行 | 行数 |
| ------------------------------------------------------------------- | -----: | -----: | ---: |
| `### Step 1: Intent Clarification`                                  |    145 |    172 |   28 |
| `### Step 2: Research`                                              |    174 |    202 |   29 |
| `### Step 3: Design`（`#### ADR の起票条件` 含む）                  |    204 |    246 |   43 |
| `### Step 4: QA Design`                                             |    248 |    290 |   43 |
| `### Step 5: Task Decomposition`                                    |    292 |    319 |   28 |
| `### Step 6 着手前: タスクリスト反映`                               |    321 |    344 |   24 |
| `### Step 6: Implementation`                                        |    346 |    393 |   48 |
| `### Step 7: External Review`（`#### Step 6 ↔ Step 7 ループ` 含む） |    395 |    481 |   87 |
| `### Step 8: Validation`                                            |    483 |    515 |   33 |
| `### Step 9: Retrospective`                                         |    517 |    542 |   26 |

`### Step 7` が単独で 87 行と突出。Step 6 ↔ Step 7 のループ図（ASCII、L448-L473 = 26 行）が含まれる。

### F-5. `## 調整プロトコル` セクション（L545-L611、67 行）の内訳

| サブセクション                               | 開始行 | 終了行 | 行数 |
| -------------------------------------------- | -----: | -----: | ---: |
| `### 1. ワークフロー開始時`                  |    547 |    555 |    9 |
| `### 2. ステップ実行ループ (全ステップ共通)` |    557 |    570 |   14 |
| `### 3. ゲート通過時`                        |    572 |    585 |   14 |
| `### 4. Blocker 発生時`                      |    587 |    594 |    8 |
| `### 5. セッション再開時`                    |    596 |    611 |   16 |

### F-6. `## ステップ完了時のコミット規約` セクション（L684-L752、69 行）の内訳

| サブセクション                                      | 開始行 | 終了行 | 行数 |
| --------------------------------------------------- | -----: | -----: | ---: |
| 導入文                                              |    686 |    686 |    1 |
| `### 原則`                                          |    688 |    694 |    7 |
| `### ステップ別コミット内訳`（11 行表 + 補足 4 行） |    696 |    714 |   19 |
| `### ユーザー承認ゲート通過時`                      |    716 |    721 |    6 |
| `### コミットメッセージ規約`                        |    723 |    733 |   11 |
| `### コミット前チェック`                            |    735 |    744 |   10 |
| `### 一時ファイルの扱い`                            |    746 |    752 |    7 |

### F-7. `## プロジェクト固有ルールとの関係` セクション（L633-L682、50 行）の内訳

| サブセクション                             | 開始行 | 終了行 | 行数 |
| ------------------------------------------ | -----: | -----: | ---: |
| 導入文                                     |    635 |    635 |    1 |
| `### 本ワークフローに従う領域`             |    637 |    644 |    8 |
| `### プロジェクト固有ルールを優先する領域` |    646 |    654 |    9 |
| `### 適用手順`                             |    656 |    666 |   11 |
| `### 矛盾の判定例`（5 行表 + ヘッダ 2 行） |    668 |    676 |    9 |
| `### Specialist への伝達`                  |    678 |    682 |    5 |

### F-8. `## 逸脱時のリカバリ` セクション（L770-L810、41 行）の内訳

| サブセクション                                      | 開始行 | 終了行 | 行数 |
| --------------------------------------------------- | -----: | -----: | ---: |
| `### ユーザーが途中でスコープを変更した`            |    772 |    776 |    5 |
| `### Specialist が期待外の成果物を返した`           |    778 |    783 |    6 |
| `### ステップ間で整合性が崩れた`                    |    785 |    789 |    5 |
| `### ロールバック先早見表`（14 行表 + ヘッダ 3 行） |    791 |    810 |   20 |

### F-9. `specialist-common/SKILL.md` の章節マップ

| H2 セクション                                                   | 開始行 | 終了行 | 行数 | 内容要約                                         |
| --------------------------------------------------------------- | -----: | -----: | ---: | ------------------------------------------------ |
| (frontmatter)                                                   |      1 |     20 |   20 | YAML frontmatter（description 1276 文字）        |
| `# Specialist Common — 共通基盤ルール`                          |     22 |     30 |    9 | 概要 + 前提スキル節                              |
| `## 0. プロジェクト固有ルール優先`                              |     34 |     43 |   10 | 4 項目の箇条書き                                 |
| `## 1. ライフサイクル規則（必読）`                              |     47 |     59 |   13 | 存続ルール + ステップ跨ぎの禁止                  |
| `## 2. 入力契約（Main から渡されるべき情報）`                   |     63 |     77 |   15 | 7 行の表 + 補足文                                |
| `## 3. 出力契約`                                                |     81 |    104 |   24 | 成果物の作成 / 保存先 / Main への返却            |
| `## 4. 失敗時 / Blocker 発生時のプロトコル`                     |    108 |    144 |   37 | ケース A / B / C / D                             |
| `## 5. スコープ規律`                                            |    148 |    163 |   16 | やってよいこと / やってはいけないこと            |
| `## 6. 並列起動時の挙動`                                        |    167 |    174 |    8 | 4 項目の箇条書き                                 |
| `## 7. Git コミットに関する注意`（`### Git ガードレール` 含む） |    178 |    195 |   18 | 役割別注意 + implementer 向けガードレール 5 項目 |
| `## 8. プロンプトインジェクション耐性`                          |    197 |    207 |   11 | 命令とデータの区別                               |
| `## 9. 秘匿情報の取り扱い`                                      |    209 |    219 |   11 | 5 項目の禁止リスト + 誤包含時の対応              |
| `## 10. 命令形・具体性の原則`                                   |    221 |    228 |    8 | 4 項目の箇条書き                                 |

合計: 228 行（frontmatter 20 + 区切り線 + コンテンツ）。

### F-10. shared-artifacts への保存構造 ASCII 図の参照は既に解決済み

`dev-workflow/SKILL.md:L621` で `shared-artifacts` SKILL.md の「成果物保存構造」を参照する形式に既に置換済み。`ggrep '├──|└──' dev-workflow/SKILL.md` の結果は L459-L461（Step 6 ↔ Step 7 ループ図の一部）のみで、保存構造 ASCII 図の重複は存在しない。Intent Spec 記載のとおり、本サイクルでの再削除作業は不要（確認のみ）。

### F-11. Step 6 着手前 / Step 6 ↔ Step 7 ループは「ステップ詳細」内に深く埋め込まれている

`### Step 6 着手前: タスクリスト反映` (L321-L344, 24 行) と `#### Step 6 ↔ Step 7 ループ` (L444-L481, 38 行) は他のステップ詳細と異なり、**運用フロー** として横断的に参照される構造。本体に残すか references に切り出すかの選択肢が生じる。

## 引用元

- `plugins/dev-workflow/skills/dev-workflow/SKILL.md:L1-L820`（820 行全体）
- `plugins/dev-workflow/skills/specialist-common/SKILL.md:L1-L228`（228 行全体）
- `plugins/dev-workflow/skills/shared-artifacts/SKILL.md:L104-L138`（既に切り出し済みの保存構造 ASCII 図）
- `plugins/dev-workflow/skills/shared-artifacts/SKILL.md:L1-L212`（212 行、`gwc -l` 実測）
- Intent Spec: `docs/dev-workflow/2026-04-29-retro-cleanup/intent-spec.md:L57-L68`（A. 構造的圧縮の切り出し候補リスト）
- Intent Spec: `docs/dev-workflow/2026-04-29-retro-cleanup/intent-spec.md:L160-L166`（成功基準 A. 行数圧縮）
- Intent Spec: `docs/dev-workflow/2026-04-29-retro-cleanup/intent-spec.md:L243-L244`（未解決事項: 切り出し粒度）

## 設計への含意

architect が Step 3 で機械的に切り出し設計を確定できるよう、以下の含意を整理する。

### I-1. `dev-workflow/SKILL.md` の切り出し候補セクションと優先度

820 → 500 行を達成するには **320 行以上の純減** が必要。「サマリ + 詳細リンク」へ置換する場合、サマリは各 2-5 行と仮定すると、切り出し対象セクションのオリジナル行数の **80-90%** が純減として効く。

| 優先度   | 候補セクション                                         | 元行数 | サマリ後の見積行数 |   純減 | 切り出し先 (案)                                                           | 根拠                                                                                                                                                                  |
| -------- | ------------------------------------------------------ | -----: | -----------------: | -----: | ------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **必須** | コミット規約全般（L684-L752）                          |     69 |                  5 | **64** | `references/commit-policy.md`                                             | Intent Spec 明示候補。表 11 行 + サブ節 5 個。本体は「ステップ完了時にコミット必須。詳細は references/commit-policy.md 参照」+ 1 ステップ = 1 コミット原則のみ残す    |
| **必須** | プロジェクト固有ルールとの関係（L633-L682）            |     50 |                  5 | **45** | `references/project-rule-integration.md`                                  | Intent Spec 明示候補。`specialist-common` L34-L43 と一部重複（前提ルール優先順）。本体は「プロジェクト固有スキルを優先、矛盾時は In-Progress 問い合わせ」程度のサマリ |
| **必須** | 調整プロトコル（L545-L611）                            |     67 |                  6 | **61** | `references/coordination-protocol.md`                                     | Intent Spec 明示候補（条件付き）。5 サブ節（開始 / ループ / ゲート / Blocker / 再開）。本体には「ループ構造の概略 4 行 + 詳細は references」                          |
| **必須** | 逸脱時のリカバリ + ロールバック早見表（L770-L810）     |     41 |                  4 | **37** | `references/rollback-recovery.md`                                         | Intent Spec 明示候補（条件付き）。ロールバック早見表 14 行は重要だが本体直書き必須ではない。スコープ変更 / 期待外成果物 / 整合性崩れの 3 ケース + 表                  |
| 高       | Step 6 ↔ Step 7 ループ詳細（L444-L481、Step 7 サブ節） |     38 |                  6 | **32** | `references/step6-step7-loop.md` または `coordination-protocol.md` に統合 | ASCII フロー図 26 行が大半。本体には「Blocker 指摘で Step 6 を再活性化、ループ上限 3 周」程度に圧縮可能                                                               |
| 中       | 並列起動のガイドライン（L754-L768）                    |     15 |                  4 | **11** | `references/parallelization-guide.md` または保留                          | 9 行表のみ。圧縮効果が小さいので保留も可                                                                                                                              |

純減合計（必須 4 件のみ）: **64 + 45 + 61 + 37 = 207 行**。

純減合計（必須 4 件 + Step 6/7 ループ）: **207 + 32 = 239 行**。

純減合計（必須 4 件 + Step 6/7 ループ + 並列ガイド）: **239 + 11 = 250 行**。

**含意**: 必須 4 件の切り出しのみでは **820 - 207 = 613 行** で 500 行目標に **113 行不足**。Step 6 ↔ Step 7 ループも切り出すと **820 - 239 = 581 行** で **81 行不足**。並列ガイドも切り出すと **820 - 250 = 570 行** で **70 行不足**。

→ **目標 500 行に到達するには、`## ステップ詳細` セクション内の各ステップ詳細自体を圧縮する必要がある**。最有力は「ステップ詳細を `references/step-details.md` に全切り出し」案。各ステップは現状 28-87 行で合計 402 行 → サマリ表 + 各ステップ 5 行 (= 9 step × 5 = 45 行) で 402 - 45 = 約 357 行の純減が見込める。ただし「ステップ詳細」は本体核心であり、全切り出しは責務ずれの懸念がある。

**代替案**: ステップ詳細をステップ別に分割し、特に重い Step 7（87 行）/Step 6（48 行 + 着手前 24 行）/Step 4（43 行）/Step 3（43 行 + ADR 起票条件）を選択的に切り出す。

### I-2. ステップ詳細圧縮の代替設計（80 行純減ルート）

`## ステップ詳細` を本体に残しつつ、各ステップ内の長文部分（特に「失敗時 / ロールバック」「注意」「並列実行の注意」など、Exit Criteria 以降の補足）を `references/step-details/<step>.md` または `references/step-failure-recovery.md` 単一ファイルに切り出す案。

| ステップ      | 現状行数 | 切り出し対象（補足ブロック）            | 圧縮後想定 | 純減 |
| ------------- | -------: | --------------------------------------- | ---------: | ---: |
| Step 1        |       28 | 失敗時 / ロールバック (4 行)            |         24 |    4 |
| Step 2        |       29 | 失敗時 / ロールバック (5 行)            |         24 |    5 |
| Step 3        |       43 | ADR の起票条件 (11 行 + 表)             |         32 |   11 |
| Step 4        |       43 | 失敗時 (5 行) + 注意 (4 行)             |         34 |    9 |
| Step 5        |       28 | 失敗時 (3 行)                           |         25 |    3 |
| Step 6 着手前 |       24 | 永続化タスクリスト詳細 (12 行)          |         12 |   12 |
| Step 6        |       48 | 失敗時 (5 行) + 並列実行の注意 (4 行)   |         39 |    9 |
| Step 7        |       87 | Step 6 ↔ Step 7 ループ ASCII 図 (38 行) |         49 |   38 |
| Step 8        |       33 | 失敗時 (5 行)                           |         28 |    5 |
| Step 9        |       26 | 失敗時 (3 行)                           |         23 |    3 |

合計純減: **99 行**。これを必須 4 件と組み合わせると **820 - 207 - 99 = 514 行** で目標に **14 行不足**。さらに「並列起動のガイドライン」「ADR 起票条件」「ステップ別コミット内訳表」を切り出せば **500 行以下達成可能**。

### I-3. `dev-workflow/SKILL.md` 切り出し後の references ファイル構造案

architect が Step 3 で確定する選択肢として、以下 3 案を推奨する。

#### 案 A: 4 ファイル分割（最小構成、Intent Spec 通り）

```
plugins/dev-workflow/skills/dev-workflow/references/
├── commit-policy.md            # ステップ完了時のコミット規約 (L684-L752, 69 行)
├── project-rule-integration.md # プロジェクト固有ルールとの関係 (L633-L682, 50 行)
├── coordination-protocol.md    # 調整プロトコル + Step 6↔7 ループ (L545-L611 + L444-L481, 105 行)
└── rollback-recovery.md        # 逸脱時のリカバリ + ロールバック表 (L770-L810, 41 行)
```

純減見込: **64 + 45 + 61 + 32 + 37 = 239 行** → **820 - 239 = 581 行**（**目標 500 行に 81 行不足**、追加圧縮必須）

#### 案 B: 5 ファイル分割（推奨）

案 A に加えて `step-details-supplements.md`（各ステップの「失敗時 / ロールバック」「注意」「並列実行の注意」の補足ブロックを集約）を追加。

```
plugins/dev-workflow/skills/dev-workflow/references/
├── commit-policy.md
├── project-rule-integration.md
├── coordination-protocol.md
├── rollback-recovery.md
└── step-details-supplements.md  # 各ステップの失敗時 / 注意ブロックを集約
```

純減見込: **239 + 99 ≈ 338 行** → **820 - 338 = 482 行**（**目標 500 行を達成**、+18 行マージン）

#### 案 C: 6 ファイル分割（マージン重視）

案 B に加えて `parallelization-guide.md`（L754-L768, 15 行）も切り出し。

純減見込: **338 + 11 = 349 行** → **820 - 349 = 471 行**（**目標 500 行を 29 行下回る**、+29 行マージン）

**含意**: architect は **案 B または案 C** を採用すべき。案 A 単独では目標達成不可。

### I-4. `specialist-common/SKILL.md` の切り出し候補

228 → 180 行を達成するには **48 行以上の純減** が必要。各セクションの圧縮効果を測る:

| 優先度   | 候補セクション                                      | 元行数 | サマリ後 |   純減 | 切り出し先 (案)                                                      | 根拠                                                                                          |
| -------- | --------------------------------------------------- | -----: | -------: | -----: | -------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| **必須** | 5. スコープ規律（L148-L163）                        |     16 |        3 | **13** | `references/scope-discipline.md`                                     | Intent Spec 明示候補。やってよい / やってはいけない箇条書きが本体核心ではない                 |
| **必須** | 7. Git コミット注意 + Git ガードレール（L178-L195） |     18 |        4 | **14** | `references/git-guardrails.md`                                       | Intent Spec 明示候補。implementer 向け詳細ルール 5 項目を含む                                 |
| 中       | 10. 命令形・具体性の原則（L221-L228）               |      8 |        2 |  **6** | `references/imperative-style.md` または `git-guardrails.md` 等に統合 | Intent Spec 明示候補。8 行と短いので単独切り出しは効率悪い                                    |
| 中       | 6. 並列起動時の挙動（L167-L174）                    |      8 |        2 |  **6** | `references/parallel-instance-coordination.md`                       | Intent Spec 未解決事項として「追加切り出し範囲」要検討と記載                                  |
| 中       | 9. 秘匿情報の取り扱い（L209-L219）                  |     11 |        3 |  **8** | `references/secret-handling.md`                                      | Intent Spec 未解決事項。本体に残すべき可能性も。L213 の禁止リストは Specialist 全員必読の核心 |
| 低       | 8. プロンプトインジェクション耐性（L197-L207）      |     11 |        3 |  **8** | `references/prompt-injection-resistance.md`                          | Specialist 全員必読の核心。切り出すと本体が不完全になるリスク                                 |

純減合計（必須 2 件のみ）: **13 + 14 = 27 行** → **228 - 27 = 201 行**（**目標 180 行に 21 行不足**）

純減合計（必須 2 件 + 命令形 + 並列）: **27 + 6 + 6 = 39 行** → **228 - 39 = 189 行**（**目標 180 行に 9 行不足**）

純減合計（必須 2 件 + 命令形 + 並列 + 秘匿情報）: **39 + 8 = 47 行** → **228 - 47 = 181 行**（**目標 180 行に 1 行不足**）

純減合計（必須 2 件 + 命令形 + 並列 + 秘匿情報 + プロンプト耐性）: **47 + 8 = 55 行** → **228 - 55 = 173 行**（**目標 180 行を 7 行下回る**、+7 行マージン）

**含意**: specialist-common は **必須 2 件 + 命令形 + 並列 + 秘匿情報 + プロンプト耐性 = 6 件切り出し** で **目標 180 行達成可能**（173 行）。ただし秘匿情報とプロンプト耐性は Specialist 全員必読のため、本体に最小要約を残す形で切り出すこと。Intent Spec の **未解決事項「specialist-common の references 切り出し範囲は 180 行以下達成のため追加で『並列起動時の挙動』『秘匿情報の取り扱い』も切り出す必要があるか」** に対する答えは **YES（追加切り出し必須）**。

### I-5. `specialist-common/SKILL.md` 切り出し後の references ファイル構造案

#### 案 A: Intent Spec 通り 3 ファイル（不十分）

```
plugins/dev-workflow/skills/specialist-common/references/
├── scope-discipline.md       # L148-L163, 13 行純減
├── git-guardrails.md         # L178-L195, 14 行純減
└── imperative-style.md       # L221-L228, 6 行純減
```

純減見込: **33 行** → **228 - 33 = 195 行**（**目標 180 行に 15 行不足**、不採用）

#### 案 B: 5 ファイル分割（推奨）

```
plugins/dev-workflow/skills/specialist-common/references/
├── scope-discipline.md                    # L148-L163, 13 行純減
├── git-guardrails.md                      # L178-L195, 14 行純減
├── parallel-instance-coordination.md      # L167-L174, 6 行純減
├── prompt-injection-resistance.md         # L197-L207, 8 行純減
├── secret-handling.md                     # L209-L219, 8 行純減
└── (imperative-style は git-guardrails 末尾に統合 6 行純減)
```

純減見込: **13 + 14 + 6 + 8 + 8 + 6 = 55 行** → **228 - 55 = 173 行**（**目標 180 行を 7 行下回る**）

ただし「imperative-style を git-guardrails に統合」は責務がずれるため、**6 ファイル分割（imperative-style.md を独立）**も実用的:

#### 案 C: 6 ファイル分割（最終推奨）

案 B に加えて `imperative-style.md` を独立ファイル化。

純減見込: 同じく 55 行 → **173 行**。違いはファイル数のみ。1 ファイル = 1 観点の 1:1 対応として `imperative-style.md` 独立化が望ましい。

### I-6. 本体に残すべき「サマリ」の最小行数見積もり

各切り出しセクションを本体でどう要約するかの方針:

| セクション                                                          | サマリ最小行数 | サマリ内容                                                                                                                                     |
| ------------------------------------------------------------------- | -------------: | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `dev-workflow/SKILL.md` `## ステップ完了時のコミット規約`           |              5 | 「1 ステップ = 1 コミット原則 / Step 6 のみタスク単位 / 詳細は references/commit-policy.md」                                                   |
| `dev-workflow/SKILL.md` `## プロジェクト固有ルールとの関係`         |              5 | 「プロセス構造は dev-workflow / 作業内容はプロジェクト固有 / 矛盾時は In-Progress 問い合わせ / 詳細は references/project-rule-integration.md」 |
| `dev-workflow/SKILL.md` `## 調整プロトコル`                         |              6 | 「5 シナリオ概略（開始 / ループ / ゲート / Blocker / 再開）/ 詳細は references/coordination-protocol.md」                                      |
| `dev-workflow/SKILL.md` `## 逸脱時のリカバリ`                       |              4 | 「3 シナリオ + ロールバック早見表 / 詳細は references/rollback-recovery.md」                                                                   |
| `dev-workflow/SKILL.md` `## ステップ詳細` 各ステップ補足            |  （各 1-2 行） | 「失敗時 / 注意の詳細は references/step-details-supplements.md 参照」を各ステップ末尾に 1 行追加                                               |
| `specialist-common/SKILL.md` `## 5. スコープ規律`                   |              3 | 「やってよい・やってはいけないの一覧、詳細は references/scope-discipline.md」                                                                  |
| `specialist-common/SKILL.md` `## 7. Git コミット注意`               |              4 | 「役割別注意 + implementer ガードレール、詳細は references/git-guardrails.md」                                                                 |
| `specialist-common/SKILL.md` `## 6. 並列起動時の挙動`               |              2 | 「他並列インスタンスへの非干渉ルール、詳細は references/parallel-instance-coordination.md」                                                    |
| `specialist-common/SKILL.md` `## 8. プロンプトインジェクション耐性` |              3 | 「命令とデータの区別ルール（核心）、詳細は references/prompt-injection-resistance.md」                                                         |
| `specialist-common/SKILL.md` `## 9. 秘匿情報の取り扱い`             |              3 | 「禁止リストの存在と Specialist 全員必読、詳細は references/secret-handling.md」                                                               |
| `specialist-common/SKILL.md` `## 10. 命令形・具体性の原則`          |              2 | 「曖昧表現禁止、観測可能事実 + アクション可能提案、詳細は references/imperative-style.md」                                                     |

**含意**: 本体に残すサマリは「最小 2-6 行 + references/<name>.md 参照リンク」で構成可能。各サマリは「**何が書かれているか**」を 1 行 + 「**最重要原則**」を 1-3 行で示す。

### I-7. 切り出し時のリンク整合性とディレクトリ作成

成功基準 #3-4（references ディレクトリ新規作成）と #26-27（リンク整合性）に対応:

- `plugins/dev-workflow/skills/dev-workflow/references/` 新規作成（実装段階）
- `plugins/dev-workflow/skills/specialist-common/references/` 新規作成（実装段階）
- 本体からの相対パス参照: `references/<name>.md` 形式（Intent Spec 制約準拠）
- 切り出し先 references ファイルのフロントマター: 不要（references はスキル本体ではない、`shared-artifacts/references/` の既存ファイル形式に倣う）

### I-8. 本サイクルでの 行数達成見通し

architect が **dev-workflow 案 B + specialist-common 案 C** を採用した場合の最終見通し:

| 対象                         | 現状 | 目標 | 切り出し後想定 | マージン |
| ---------------------------- | ---: | ---: | -------------: | -------: |
| `dev-workflow/SKILL.md`      |  820 | ≤500 |            482 |      +18 |
| `specialist-common/SKILL.md` |  228 | ≤180 |            173 |       +7 |

両ファイルとも目標達成可能。ただしマージンが小さいため、本体追記（Intent Spec スコープ C）が走ると目標超過リスクがある。**追加圧縮の余地（案 C → さらに「並列起動のガイドライン」や「ADR 起票条件」も切り出し）を確保しておくべき**。

## 残存する不明点

### Q-1. ステップ詳細自体を「ステップ別 references」に分割するか

I-2 の代替設計で「ステップ詳細を補足ブロックのみ切り出す」案を提示したが、**ステップ詳細全体を `references/step-details/<step>.md` に分割**する選択肢もある。後者は本体行数を大幅削減できる（約 350 行純減）が、**ステップ詳細はスキル本体の核心**であり、他スキルから参照される頻度も高いため、切り出すと「責務ずれ」のリスクがある。

→ **architect が Step 3 で判断**。本 researcher の推奨は「補足ブロックのみ切り出し（案 B）」。全分割は責務上不適切と推測。

### Q-2. `imperative-style.md` を独立ファイル化するか統合するか

specialist-common 案 C（独立ファイル化）と案 B（git-guardrails への統合）の判断は architect 領域。本 researcher の推奨は **案 C（独立化）**。理由は「1 ファイル = 1 観点」の `shared-artifacts/references/` 既存設計との一貫性。

### Q-3. shared-artifacts と dev-workflow / specialist-common の references 命名規則の整合

`shared-artifacts/references/` は成果物ごとのファイル（`research-note.md` / `design.md` / `task-plan.md` 等）。一方、dev-workflow / specialist-common の `references/` はプロセス概念ごとのファイル（`commit-policy.md` / `coordination-protocol.md` 等）。両者で命名空間と粒度が異なる。

→ **architect は両者の責務分離を Step 3 で明示**。本 researcher 推奨命名は本 Note の I-3 / I-5 を参照。

### Q-4. references 切り出し時、本体にサマリすら残さない選択肢の可否

例えば `## ステップ完了時のコミット規約` を本体から完全削除し、`## 成果物テンプレート・保存構造・進捗記録フォーマット` セクションに「コミット規約は references/commit-policy.md」とだけ書く設計。これは更なる純減（純減 +5 行）が可能だが、**「ステップ完了時にコミット必須」は核心方針なので本体から消すと検索性低下** のリスクがある。

→ **architect が判断**。本 researcher 推奨は「最低 5 行のサマリは本体に残す」。

### Q-5. references/\* 内部のフロントマター・テンプレート要否

`shared-artifacts/references/<name>.md` は「成果物ごとの書き方ガイド」のため、各ファイルが独立した文書として完結する形式。一方、dev-workflow / specialist-common の `references/` は「本体スキルから抜き出した詳細ブロック」のため、フロントマターは不要、本文も連続性を持つ Markdown であれば良い、と推測。

→ **architect が Step 3 でフォーマットを確定**。
