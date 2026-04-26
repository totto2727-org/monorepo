# Review Report: consistency

- **Identifier:** 2026-04-26-add-qa-design-step
- **Aspect:** consistency (整合性: step 番号 / 命名 / ファイル間相互参照)
- **Reviewer:** Main (reviewer 役を兼任)
- **Reviewed at:** 2026-04-26T19:15:00Z
- **Scope:** 8 commits (`8f716e0..a778066`) 全 diff、main-cycle 番号体系の整合性、ファイル間相互参照、命名規則

## サマリ

| 深刻度  | 件数 |
| ------- | ---- |
| Blocker | 0    |
| Major   | 0    |
| Minor   | 1    |

**Gate 判定:** `approved`

## 指摘事項

### #1 templates/self-review-report.md の Target 行が新番号体系のみ

- **深刻度:** Minor
- **該当箇所:**
  - Commit: `55b4bb2`
  - File: `plugins/dev-workflow/skills/shared-artifacts/templates/self-review-report.md`
  - Line: 4
- **問題の要約:** template の `Target: Step 6 (Implementation) diff` が新 10-step 体系で記述。旧 9-step 体系で動く本サイクルや既存サイクル (docs/ai-dlc/...) を再開する場合に番号ずれの認知負荷が発生する可能性
- **根拠:** template は次サイクル以降の正式な番号、本サイクル成果物 self-review-report.md では Step 5 を Target としている (Self-Review 自身が #1 で指摘済み、wontfix 判断)
- **推奨アクション:** 修正不要 (テンプレートは next-cycle 用途、現サイクルでは Self-Review が手動補正)
- **設計との関連:** design.md「アプローチの概要」(本サイクルはメタ作業、新仕様適用は次サイクルから)

## 観点固有の評価項目

### 番号シフト整合性

- `grep -nF "Step 5 (Implementation)" plugins/dev-workflow/` → **0 件** (T8 で確認済み)
- 旧 Step 5〜9 への参照 → 全て新番号 (Step 6〜10) にシフト済み
- 複合表現 (Step 5 ↔ Step 6, Step 5〜6, Step 5/6) → placeholder 経由で新値 (Step 6 ↔ Step 7, Step 6〜7, Step 6/7) に統一

### ファイル間相互参照

- `dev-workflow/SKILL.md` のステップ一覧テーブル → `specialist-qa-analyst` への参照 ✓
- `specialist-qa-analyst/SKILL.md` → `shared-artifacts/references/qa-design.md`, `qa-flow.md` への参照 ✓
- `agents/qa-analyst.md` → `specialist-qa-analyst`, `specialist-common` への参照 ✓
- `shared-artifacts/SKILL.md` 成果物テーブル → 新規 qa-design / qa-flow 行を含む ✓
- `task-plan.md` template → qa-design.md の TC-NNN を任意紐付け ✓
- `implementer SKILL.md` → qa-design.md / qa-flow.md / `references/qa-design.md` への参照 ✓
- `validator SKILL.md` → qa-design.md / qa-flow.md / カバレッジ表 への参照 ✓
- 全相互参照に**未到達リンク (Broken reference)** なし

### 命名規則

- TC-ID: `TC-NNN` (本質) / `TC-IMPL-NNN` (実装都合) — 3 桁ゼロ埋めで統一 ✓
- ファイル名: `qa-design.md` / `qa-flow.md` (kebab-case、既存命名 `intent-spec.md` `task-plan.md` 等と整合) ✓
- specialist 名: `qa-analyst` (既存 `intent-analyst` `architect` 等と整合) ✓
- enum 値: `automated/ai-driven/manual` × `assertion/scenario/observation/inspection` (英小文字 / hyphen-separated 統一) ✓
- 成功基準 ID: `SC-N` (1 桁、Intent Spec 規約と整合) ✓

## 他レビューとの整合性

- なし (本観点 = 整合性 はメタな観点、他観点と直交)
