# Research Note: column-and-tcid-policy

- **Identifier:** 2026-04-26-add-qa-design-step
- **Topic:** column-and-tcid-policy
- **Researcher:** Main (intent-analyst → researcher 兼任、既存 task-plan template 確認 + 設計判断)
- **Created at:** 2026-04-26T13:55:00Z
- **Scope:** qa-design.md のテストケース表に持たせる列の必須/任意境界、および task-plan.md における「カバーする TC-ID」フィールドの必須/推奨判断

## 調査対象

Intent Spec の未解決事項:

- 「`qa-design.md` のテストケース表に持たせる必須列 vs 任意列の境界」
- 「task-plan.md の『カバーするテストケース ID』を**必須**にするか**推奨**にとどめるか」

## 発見事項

### qa-design.md の候補列

設計検討した候補列 (case 表の column):

| 列名                 | 内容                                                                  | 必須 / 任意 / 条件付き必須 |
| -------------------- | --------------------------------------------------------------------- | -------------------------- |
| `ID`                 | テストケース識別子 (TC-001, TC-002, ...)                              | **必須**                   |
| `対象成功基準`       | intent-spec.md の成功基準 ID (例: SC-1) または「(なし)」              | **必須**                   |
| `期待される振る舞い` | 振る舞いの記述 (コードがない時点なので、観察可能な事象として書く)     | **必須**                   |
| `実行主体`           | 軸 A: `automated` / `ai-driven` / `manual`                            | **必須** (enum)            |
| `検証スタイル`       | 軸 B: `assertion` / `scenario` / `observation` / `inspection`         | **必須** (enum)            |
| `判定基準`           | 合格条件の具体的記述 (例: 「HTTP ステータスが 200」「p95 < 200ms」)   | **必須**                   |
| `必要理由`           | 「対象成功基準 = (なし)」の場合に必要理由を明示                       | **条件付き必須**           |
| `備考`               | △組み合わせ採用理由 / 配置ポリシー逸脱の説明 / その他補足             | 任意                       |
| `配置候補`           | テストファイル配置の hint (具体パスは task-plan で確定)               | 任意                       |
| `担当 implementer`   | Step 5 / Step 7 で割り当てられた implementer ID (qa-analyst では空欄) | 任意 (Step 7 で埋まる)     |
| `実装状況`           | `pending` / `implemented` / `passed` / `failed` (Step 9 で埋まる)     | 任意 (Step 9 で埋まる)     |

### TC-ID 命名規則

- 本質テスト: `TC-NNN` (3 桁ゼロ埋め、例: TC-001, TC-002)
- 実装段階で追加されたテスト: `TC-IMPL-NNN` (区別明示)
- スキップ用の擬似 ID は不要 (qa-flow.md 上の skip 葉は ID を持たない)

### 必要理由欄の運用

- 「対象成功基準 = (なし)」のケース例:
  - 防御的プログラミング (例: 不正引数で例外を投げる)
  - 内部不変条件の検証 (例: キャッシュ整合性)
  - リグレッション防止 (過去バグの再発防止)
  - セキュリティ要件 (Intent Spec で明示されないが必要)
- 必要理由が空欄なら **Step 4 レビューで差し戻し**。すべての非対応テストには明示的根拠を要求

### task-plan.md の TC-ID フィールド

#### 必須にした場合

メリット:

- planner が qa-design.md を完全把握する → トレーサビリティ強固
- implementer が「どのテストを実装すべきか」を即座に把握

デメリット:

- planner の責任を「分解」に純化したい本サイクルの目的と相反 (テスト設計まで意識する必要)
- task-plan が冗長化 (各タスクに TC-ID リストを書くと長大)
- qa-design 変更時に task-plan の同期が必要 (二重管理)
- planner が TC-ID を割り当て忘れた場合に Step 5 開始がブロック

#### 推奨 (任意) にした場合

メリット:

- planner は分解に集中、TC-ID は implementer 起動時に Main / implementer が qa-design.md を読んで判断
- task-plan が軽量に保たれる
- qa-design 変更が task-plan に伝播する必要なし (二重管理回避)

デメリット:

- トレーサビリティが Step 7 (Implementation) 開始時まで暗黙的
- 大規模タスクで「このタスクが何のテストをカバーするか」を planner レベルで議論できない

#### 推奨

**「任意」(推奨にとどめる)** を採用。理由:

1. planner の責任純化が本サイクルの主目的であり、TC-ID 必須化はそれと矛盾
2. Step 7 (Implementation) で implementer が qa-design.md を直接参照するため、トレーサビリティは保証される (Step 6 ではなく Step 7 で TC-ID が確定する運用)
3. 二重管理リスクの回避は、長期メンテナンスにおいて重要
4. 大規模タスクで TC-ID 紐付けが有用な場合、planner が任意で書く運用で十分柔軟

### 既存 task-plan.md template の構造

確認したファイル: `plugins/dev-workflow/skills/shared-artifacts/templates/task-plan.md`

- L26, L36 に `{{task_N_test_strategy}}` プレースホルダ (削除対象)
- L9 / L59 に Step 4 / Step 5 言及 (本サイクルで Step 5 / Step 6 にシフト)
- 各タスクの構造: `### Task N: <name>` 見出し + 概要 / 成果物 / 依存関係 / 並列可否 / 見積り規模 / **テスト追加方針 (削除予定)**

→ 「テスト追加方針」を削除し、**任意項目**として「カバーするテストケース ID (該当があれば)」を追加。プレースホルダは `{{task_N_covered_test_cases}}` (空欄可)。

## 引用元

- `plugins/dev-workflow/skills/shared-artifacts/templates/task-plan.md` (現状)
- `plugins/dev-workflow/skills/shared-artifacts/references/task-plan.md` L33 (「テスト追加方針」記述)
- 過去の議論: 本会話の Plan モード議論 (実装都合のテストは Step 7 で `qa-design.md` 追記方針確定)

## 設計への含意

### qa-design.md template に組み込む列構造

**必須 6 列:**

`ID | 対象成功基準 | 期待される振る舞い | 実行主体 | 検証スタイル | 判定基準`

**条件付き必須 1 列:**

`必要理由` (`対象成功基準 = (なし)` の場合のみ必須)

**任意列:**

- `備考` (組み合わせ理由 / 配置ポリシー逸脱の説明 / その他)
- `配置候補` (テストファイル配置の hint)
- `担当 implementer` (Step 7 で埋まる、Step 4 では空欄)
- `実装状況` (Step 9 で埋まる)

→ qa-design.md template には**必須 6 列 + 条件付き必須 1 列 + 任意 4 列**を持たせ、reference で各列の運用を明示。

### task-plan.md の「カバーする TC-ID」

**任意 (推奨) として追加**:

- プレースホルダ: `{{task_N_covered_test_cases}}`
- 値: TC-ID のカンマ区切りリスト (例: `TC-001, TC-005, TC-012`) または空欄
- reference に「Step 7 で implementer が qa-design.md を直接参照するため、Step 6 で planner が TC-ID を確定する義務はない」旨を明記

### 命名規則と運用

- TC-ID 本質テスト: `TC-NNN` (3 桁ゼロ埋め)
- TC-ID 実装段階追記: `TC-IMPL-NNN`
- 必要理由が空欄なら Step 4 レビューで差し戻し
- 「対象成功基準 = (なし)」の頻発 → Intent Spec の成功基準が不足している可能性。Step 1 ロールバック検討

## 残存する不明点

- **TC-ID の重複防止運用**: 異なる qa-flow.md セクション間で同一 TC-ID を参照する場合の管理方針 (qa-design.md が単一テーブルなので重複は発生しないが、TC-IMPL-NNN との連番衝突を避ける運用) → Step 3 Design で軽く触れる
- **Step 4 を再活性化した場合の TC-ID 採番**: 既存 TC-NNN を残しつつ新規 ID を発番する運用が望ましい (削除→再発番は混乱を招く) → Step 3 Design / qa-analyst の reference で明記
