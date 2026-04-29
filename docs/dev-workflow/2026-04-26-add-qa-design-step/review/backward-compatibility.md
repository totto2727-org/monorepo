# Review Report: backward-compatibility

- **Identifier:** 2026-04-26-add-qa-design-step
- **Aspect:** backward-compatibility (後方互換: 既存サイクル / 既存 specialist / 既存 ADR との互換性)
- **Reviewer:** Main (reviewer 役を兼任)
- **Reviewed at:** 2026-04-26T19:25:00Z
- **Scope:** 既存 ai-dlc サイクル成果物 (`docs/ai-dlc/2026-04-24-ai-dlc-plugin-bootstrap/`) との非破壊性、前 ADR の決定との非矛盾、既存 specialist スキルの責務分離維持

## サマリ

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 0    |
| Minor   | 1    |

**Gate 判定:** `approved`

## 指摘事項

### #1 現サイクル中の番号体系が新旧混在 (本サイクル成果物自身が混在を認知)

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `4fddb96` (Self-Review)
  - File: `docs/dev-workflow/2026-04-26-add-qa-design-step/self-review-report.md`
  - Line: 4
- **問題の要約:** 本サイクル成果物 self-review-report.md は `Target: Step 5 (Implementation)` (旧番号) と書かれているが、template は `Step 6 (Implementation)` (新番号) になっている。本サイクルは旧 9-step 体系で進行中だが、template が更新されたため本サイクル成果物が template と乖離
- **根拠:** Intent Spec 制約「メタサイクルの過渡期」(本サイクル中に dev-workflow を変更するため、本サイクル中は旧体系、次サイクル以降は新体系)
- **推奨アクション:** 修正不要 (Intent Spec で明示されているメタサイクル特有の過渡状態)
- **設計との関連:** intent-spec.md「制約」「組織的制約」(本サイクルは現行 9-step で進行)

## 観点固有の評価項目

### 既存 ai-dlc サイクル成果物との非破壊性

- `docs/ai-dlc/2026-04-24-ai-dlc-plugin-bootstrap/` 配下 (intent-spec.md / research/_ / design.md / task-plan.md / TODO.md / self-review-report.md / review/_ / validation-report.md / retrospective.md / progress.yaml) → **本サイクルで一切変更していない** ✓
- 既存サイクル成果物が参照する旧 dev-workflow 構造 (旧 Step 1〜9、ai-dlc プラグイン名) は履歴として正常に保存されている ✓
- 旧 dev-workflow を引き継いだ既存サイクル成果物は、新仕様 (Step 4 QA Design 追加) を後付けで適用する義務なし ✓

### 前 ADR (`2026-04-26-dev-workflow-rename-and-flatten.md`) との整合性

- フラット step リスト構造を維持 (フェーズ概念は再導入していない) ✓
- specialist 配置の責務分離原則を維持 (qa-analyst 追加は責務分離の延長) ✓
- 9 specialist → 10 specialist に増加するが、原典 AWS AI-DLC の「責務収束」原則に意図的に反する点は前 ADR で明示済み (本サイクルは前 ADR の方針内で specialist を 1 名追加) ✓
- フェーズ概念非導入 / DDD/BDD/TDD flavor 選択非導入 / Operations 非導入 → 全て維持 ✓

### 既存 specialist スキルの責務分離

- intent-analyst / researcher / architect: **入出力契約の変更なし** (qa-analyst が後段に挿入されただけで、これらは intent-spec.md / research/\*.md / design.md を出力する役割のまま) ✓
- planner: テスト方針の責務を qa-analyst に委譲 (剥離) → 責務がより純化、前 ADR の specialist 責務分離原則と整合 ✓
- implementer: qa-design.md / qa-flow.md への追記責任を追加 → スコープ拡大だが、本質テスト + 実装都合テストの判断フローが明示されているため運用可能 ✓
- self-reviewer / reviewer / retrospective-writer: 番号シフトのみで責務変更なし ✓
- validator: qa-design.md / qa-flow.md カバレッジ実測責任を追加 → 既存責務 (Intent Spec 成功基準実測) と直交、相互補強 ✓

### 既存 progress.yaml / task-plan の互換性

- `artifacts.qa_design` / `artifacts.qa_flow` フィールドを新規追加 → **既存 progress.yaml は `null` でも動作可** (フィールド未定義扱い、互換性維持) ✓
- task-plan の `test_strategy` を削除し `covered_test_cases` を任意追加 → 既存 task-plan が test_strategy を持っている場合、新フォーマットでは無視される (削除推奨だが破壊的ではない) ✓

## 他レビューとの整合性

- なし (本観点は破壊的変更の検知に特化、他観点と直交)
