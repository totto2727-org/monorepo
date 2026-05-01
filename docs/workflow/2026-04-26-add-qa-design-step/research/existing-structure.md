# Research Note: existing-structure

- **Identifier:** 2026-04-26-add-qa-design-step
- **Topic:** existing-structure
- **Researcher:** Main (intent-analyst → researcher 兼任)
- **Created at:** 2026-04-26T13:35:00Z
- **Scope:** dev-workflow の既存構造を網羅し、Step 4 挿入による影響範囲 (旧 Step 4〜9 → 新 Step 5〜10 シフト) を特定する

## 調査対象

Intent Spec の未解決事項「旧 Step 5〜9 を参照する箇所の網羅的な棚卸し」と、planner からのテスト記述剥離・implementer/validator への qa-design.md 入力追加の準備として、現状の dev-workflow ファイル群を grep ベースで網羅調査。

## 発見事項

### 1. 旧 Step 番号への参照 (シフト対象)

#### `plugins/dev-workflow/skills/dev-workflow/SKILL.md` (最多参照、L99-783)

- **L6**: `Step 9 (Retrospective) までフラットな 9 ステップ`
- **L104-116**: ワークフロー全体図 (Step 1-9 を ASCII 図で表現)
- **L125-135**: ステップ一覧テーブル (現 9 行)
- **L204, 248, 302, 351, 419, 460, 494**: ステップ別詳細セクション見出し (`### Step N: <Name>`)
- **L296**: `Self-Review High 指摘で Step 5 に戻った場合等`
- **L363, 376, 380**: Step 5/7 への差し戻し言及
- **L390-417**: "Step 5 ↔ Step 6 ループ" セクション (図 + 説明、新番号では Step 6↔7)
- **L417**: ループ上限・Step 3 ロールバック検討
- **L438, 455, 486**: Step 7 Blocker → Step 5、Step 8 失敗時のロールバック先
- **L676-686**: ステップ別コミット規約テーブル
- **L733-743**: 並列起動ガイドライン (現 9 行)
- **L768-783**: ロールバック早見表 (Step 2-8 を発見ステップとした表)

#### `plugins/dev-workflow/skills/specialist-*/SKILL.md`

| ファイル                                   | Step 言及行                       |
| ------------------------------------------ | --------------------------------- |
| `specialist-planner/SKILL.md`              | L4, L12, L28, L44                 |
| `specialist-implementer/SKILL.md`          | L4, L25                           |
| `specialist-self-reviewer/SKILL.md`        | L4, L10, L28, L47, L68-69, L95-96 |
| `specialist-reviewer/SKILL.md`             | L4, L11, L29, L128                |
| `specialist-validator/SKILL.md`            | L4, L25                           |
| `specialist-retrospective-writer/SKILL.md` | L4, L10, L28, L59                 |

#### `plugins/dev-workflow/skills/shared-artifacts/`

- `SKILL.md` L47-53 (成果物一覧テーブル)、L98, L101-102, L117-129 (保存構造コメント)
- `templates/progress.yaml` L13: Step 2/7 の comment 言及
- `templates/task-plan.md` L9, L59: `Step 4 で確定する不変な計画書`
- `templates/TODO.md` L4: `Active Steps: Step 5〜6`
- `templates/self-review-report.md` L4: `Target: Step 5 (Implementation) diff`
- `templates/retrospective.md` L36-38: ループテーブル `Step 5 ↔ Step 6` / `Step 5/6 → Step 3` / `Step 7 → Step 5`

### 2. planner のテスト関連記述 (剥離対象)

- `specialist-planner/SKILL.md` L6: `テスト方針を明示した不変の Task Plan`
- `specialist-planner/SKILL.md` L42: タスク一覧の必須項目「テスト追加方針」
- `specialist-planner/SKILL.md` L61: `各タスクに見積り規模 (S/M/L 等) とテスト方針を付与`
- `specialist-planner/SKILL.md` L70: 粒度ガイドの「テスト追加方針が決められる粒度」
- `shared-artifacts/references/task-plan.md` L33: `テスト追加方針: ユニット / 統合 / E2E のどれを追加するか、カバレッジの方針` ← 単体/統合/E2E 分類が現存、本サイクルで除去
- `shared-artifacts/templates/task-plan.md` L26, L36: `{{task_N_test_strategy}}` プレースホルダ

### 3. implementer / validator の現状入力欄

- `specialist-implementer/SKILL.md` L42-50: 「固有の入力」セクション (テスト追加方針は task-plan から引用)
  - → ここに `qa-design.md` / `qa-flow.md` を追加
- `specialist-validator/SKILL.md` L37-44: 「固有の入力」セクション (テスト実行手順は task-plan に記載)
  - → ここに `qa-design.md` / `qa-flow.md` を追加し、「カバレッジ検証責任」明記

### 4. shared-artifacts スキーマの現状

- `templates/progress.yaml`: `artifacts` セクションにテスト関連フィールドなし (現状: intent_spec / research / design / external_adrs / task_plan / todo / self_review / review / validation / retrospective)
  - → 追加必要: `qa_design: null` / `qa_flow: null`
- `references/progress-yaml.md`: artifacts 説明部分も同様の更新必要
- `templates/task-plan.md`: 「テスト追加方針」が各タスク定義の必須項目として現存
  - → 「テスト追加方針」削除、「カバーする TC-ID」(任意 or 推奨) 追加
- `references/task-plan.md`: 同上

### 5. dev-workflow/SKILL.md 内の番号シフト箇所 (要注意)

ステップ番号を含む全テーブル・全図・全本文セクション:

- ステップ一覧テーブル (現 L125-135): 9 行 → 10 行に拡張、Step 4 = QA Design 挿入、旧 Step 4〜9 を Step 5〜10 にリナンバー
- ワークフロー全体図 (L104-116): ASCII 図の各ノードを更新
- ステップ別詳細セクション見出し: `### Step 4: Task Decomposition` → `### Step 5: Task Decomposition` 等、見出しレベルでの番号更新
- "Step 5 ↔ Step 6 ループ" → "Step 6 ↔ Step 7 ループ" (図 + 説明)
- ステップ別コミット規約テーブル: 1 行追加 (Step 4 QA Design) + 既存行を 1 行ずつ下シフト
- 並列起動ガイドライン: 同上
- ロールバック早見表: 全行を 1 ステップずつ下シフト + Step 4 関連エントリ 2 件追加 (例: 「Step 4 で観測不能 → Step 1」「Step 4 で振る舞い未定 → Step 3」)

## 引用元

- `plugins/dev-workflow/skills/dev-workflow/SKILL.md` (L99-783 全体)
- `plugins/dev-workflow/skills/specialist-planner/SKILL.md` (全体)
- `plugins/dev-workflow/skills/specialist-implementer/SKILL.md` (L42-50)
- `plugins/dev-workflow/skills/specialist-validator/SKILL.md` (L37-44)
- `plugins/dev-workflow/skills/shared-artifacts/SKILL.md` (L47-53)
- `plugins/dev-workflow/skills/shared-artifacts/templates/progress.yaml` (全体)
- `plugins/dev-workflow/skills/shared-artifacts/templates/task-plan.md` (L9, L26, L36, L59)
- `plugins/dev-workflow/skills/shared-artifacts/references/task-plan.md` (L33)
- `plugins/dev-workflow/skills/shared-artifacts/templates/TODO.md` (L4)
- `plugins/dev-workflow/skills/shared-artifacts/templates/self-review-report.md` (L4)
- `plugins/dev-workflow/skills/shared-artifacts/templates/retrospective.md` (L36-38)

## 設計への含意

1. **番号シフトの順序**: gsed 等で機械置換する場合、Step 9 → 10 から先に処理しないと連鎖二重置換が発生する (Step 5 → 6 を先にやると、その後 Step 6 → 7 で新規の Step 6 まで Step 7 になる)。**逆順 (9→10, 8→9, ..., 4→5)** で実行
2. **planner からの剥離は機械置換+部分削除**: 「テスト追加方針」「test_strategy」などの語句は機械的に削除可能だが、削除後の行構造を維持するため、template と reference は別途 Edit で再構築
3. **shared-artifacts/SKILL.md の成果物テーブル**: qa-design / qa-flow の 2 行を挿入する位置は「Step 4 の成果物として」、すなわち task-plan の前
4. **`templates/task-plan.md` の「カバーする TC-ID」**: 任意列 (推奨) として追加。プレースホルダは `{{task_N_covered_test_cases}}` 形式が既存命名規則に整合
5. **ロールバック早見表に Step 4 を 2 行追加**: 「Step 4 で観測不能基準発見 → Step 1」「Step 4 で振る舞い未定 → Step 3」を Intent Spec 成功基準 9 で要求済み
6. **ループ図の書き換え**: "Step 5 ↔ Step 6" → "Step 6 ↔ Step 7" の機械置換だけでは図の文章説明 (「Step 5 を再活性化」など) が崩れるため、Edit で文脈ごと書き換えが必要

## 残存する不明点

なし (機械的に網羅できた)。Step 3 Design で具体的な書き換え戦略 (どのファイルに何行追加/削除するか) を確定する。
