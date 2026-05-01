# Task Plan: 2026-04-29-retro-cleanup

- **Identifier:** 2026-04-29-retro-cleanup
- **Author:** Main (planner 兼任、軽量スコープのため)
- **Source:** `design.md`
- **Created at:** 2026-04-29T13:45:00Z
- **Status:** draft

## 前提

- Markdown のみ、機械置換 (gsed) は不要 (新規追記中心)
- 5 項目は独立しており Wave 1 並列配置可能
- Step 8 検証は Wave 2 で一括実行
- 各タスク = 1 commit (前例 B-2 単一巨大 commit アンチパターン回避)

## タスク一覧

### T1: A-2 dev-workflow/SKILL.md に 3-5 案推奨を追記

- **概要:** Report-Based Confirmation セクションに「選択肢と根拠は 3-5 案を推奨」1 行追記
- **対象ファイル:** `plugins/dev-workflow/skills/dev-workflow/SKILL.md`
- **依存:** なし (Wave 1 起点)
- **並列可:** yes (T2-T5 と完全並列)
- **見積り:** S
- **手順:**
  1. SKILL.md の `Report-Based Confirmation for In-Progress Questions` セクション (現状 L41-L52 付近) を Read
  2. 「レポート最小構成」行の直下に 1 行追加: `- 「選択肢と根拠」は **3-5 案を推奨**。2-3 案では選択肢を絞りすぎて事後修正が必要になりやすいため、複数アプローチを比較する場面では原則 3-5 案を提示する`
  3. commit `feat(dev-workflow): require 3-5 alternatives in Report-Based Confirmation`
- **success_check:** TC-001 (`ggrep -nE '3-5|3〜5|3 から 5' plugins/dev-workflow/skills/dev-workflow/SKILL.md` が 1 件以上、ヒット行が Report-Based Confirmation セクション内)

### T2: A-5 specialist-reviewer に holistic 小節を新設

- **概要:** 「観点別のレビュー指針」セクション末尾に `#### holistic` 小節を追加
- **対象ファイル:** `plugins/dev-workflow/skills/specialist-reviewer/SKILL.md`
- **依存:** なし
- **並列可:** yes
- **見積り:** S
- **手順:**
  1. specialist-reviewer/SKILL.md の `## 観点別のレビュー指針` セクション末尾 (api-design 小節の後) を Read
  2. `#### holistic` 小節を新設、4 項目チェックリスト追記:
     - `design.md と実装の整合性チェック (Round 1 必須項目)`
     - `Task Plan 完了判定 (TODO.md の全タスクが完了状態か)`
     - `Intent Spec 成功基準充足見込み (各 SC が観測可能な形で達成されているか)`
     - `明白な bug の早期検出 (リンク切れ / frontmatter 不整合 / yaml syntax error / Mermaid 図の壊れ等)`
  3. commit `feat(dev-workflow): add holistic subsection to specialist-reviewer review guideline`
- **success_check:** TC-002 (`#### holistic` が 1 件以上) + TC-003 (`design.md と実装|design.md.*整合|整合性チェック` が 1 件以上)

### T3: A-8 + C-3 specialist-retrospective-writer 修正

- **概要:** 再活性化 SHA 列挙手順を追記 + 出力先パスを `docs/retrospective/<id>.md` に更新
- **対象ファイル:** `plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md`
- **依存:** なし
- **並列可:** yes
- **見積り:** S
- **手順:**
  1. retrospective-writer/SKILL.md の作業手順「データ分析」項目を Read
  2. 既存項目に並列で追加: `- **再活性化タスクの SHA 列挙**: TODO.md で re_activations >= 1 のタスクについて、再活性化を引き起こした修正コミット SHA を列挙する (retrospective.md の「課題」セクションで参照)`
  3. 同ファイルの成果物テーブル L29 の `docs/dev-workflow/<identifier>/retrospective.md` を `docs/retrospective/<identifier>.md` に更新
  4. commit `feat(dev-workflow): teach retrospective-writer to list re-activation commit SHAs and use new path`
- **success_check:** TC-004 (`re_activations|再活性化.*SHA|SHA.*列挙` が 1 件以上) + TC-013 (該当ファイルに `docs/retrospective/` が 1 件以上)

### T4: ADR 新規作成 (A-4 保留記録)

- **概要:** `docs/adr/2026-04-29-researcher-project-skill-inventory-deferral.md` を新規作成
- **対象ファイル:** 新規 `docs/adr/2026-04-29-researcher-project-skill-inventory-deferral.md`
- **依存:** なし
- **並列可:** yes
- **見積り:** S
- **手順:**
  1. design.md の「ADR. A-4 の保留記録」セクションの本文構成案に従って ADR を作成
  2. frontmatter `confirmed: false`
  3. Decision / Impact / 再検討トリガー / 関連サイクル の 4 セクション必須
  4. commit `docs(adr): defer researcher project-specific skill inventory recommendation`
- **success_check:** TC-005 (file 存在) + TC-006 (キーワード grep) + TC-007 (`confirmed: false`)

### T5: C 構造変更 (新規ディレクトリ + 過去削除 + 残スキルの新パス参照 + 削除ポリシー)

- **概要:** retrospective 集約構造への移行。複数ファイルを 1 commit にまとめる (構造的に密結合のため)
- **対象ファイル:**
  - 削除: `docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md`
  - 削除: `docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md`
  - 削除: `docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md`
  - 修正: `plugins/dev-workflow/skills/dev-workflow/SKILL.md` (Step 一覧テーブル / 成果物パス / コミット規約表 / 削除ポリシー追記)
  - 修正: `plugins/dev-workflow/skills/shared-artifacts/SKILL.md` (成果物一覧テーブル / 保存構造 ASCII から削除 / サイクル外の成果物セクションに retrospective 追記)
  - 修正: `plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md` (ファイル位置 + 削除ポリシー)
  - 修正: `plugins/dev-workflow/agents/retrospective-writer.md` (概要セクションのパス)
- **依存:** なし
- **並列可:** yes (他 T1-T4 と並列)
- **見積り:** M
- **手順:**
  1. 過去 3 retrospective を `git rm`
  2. dev-workflow/SKILL.md の Step 9 セクション + 関連箇所を Edit (パス更新 + 削除ポリシー)
  3. shared-artifacts/SKILL.md の成果物一覧 + ASCII + サイクル外成果物セクション
  4. references/retrospective.md のファイル位置 + 削除ポリシー
  5. agents/retrospective-writer.md の概要パス
  6. commit `feat(dev-workflow): centralize retrospective.md under docs/retrospective/ and add delete policy`
- **success_check:** TC-008-014 全件 (削除確認 + ディレクトリ確認は Step 6 で実施せず Step 8 / Step 9 で検証、新パス記述検証 TC-013 / 削除ポリシー TC-014 を含む)
- **備考:** ディレクトリ `docs/retrospective/` は本サイクル Step 9 で本サイクル retrospective ファイル作成時に自動生成。明示的な mkdir は不要

### T6: Wave 2 Validation (機械検証)

- **概要:** TC-001..TC-020 を一括検証 (TC-012 は Step 9 完了後)
- **対象ファイル:** なし (検証のみ)
- **依存:** [T1, T2, T3, T4, T5] 全て
- **並列可:** no (全 Wave 1 完了後)
- **見積り:** S
- **手順:**
  1. qa-design.md の Step 8 一括実行スクリプトを実行
  2. validation-report.md に結果を記録
  3. commit `docs(dev-workflow/2026-04-29-retro-cleanup): complete Step 8 (Validation)`
- **success_check:** 全 TC で PASS (TC-012 は Step 9 完了後)

## Wave 構造

```
Wave 1 (並列実行、5 タスク):
  T1 (dev-workflow A-2) ─┐
  T2 (reviewer A-5) ─────┤
  T3 (retrospective-writer A-8 + C-3) ─┤── Wave 1 完了
  T4 (ADR 新規作成) ─────┤
  T5 (C 構造変更) ───────┘

Wave 2 (Wave 1 完了後、1 タスク):
  T6 (Step 8 Validation 一括実行)
```

## 依存グラフ

```
T1 ┐
T2 ├─→ T6
T3 ├
T4 ├
T5 ┘
```

## 設計参照

- T1: design.md「A-2. dev-workflow/SKILL.md ...」セクション
- T2: design.md「A-5. specialist-reviewer に holistic 小節を新設」
- T3: design.md「A-8. specialist-retrospective-writer ...」+「C-3 スキル本文の保存先パス更新」の retrospective-writer 行
- T4: design.md「ADR. A-4 の保留記録」
- T5: design.md「C. retrospective 構造変更」C-1..C-5 (C-3 の retrospective-writer 行は T3 と重複するため T3 で対応、それ以外は T5)
- T6: qa-design.md / qa-flow.md

## コミット粒度

- Wave 1: 5 commits (タスク単位、各 commit が小さく目視レビュー容易)
- Wave 2: 1 commit (Validation 結果)
- TODO.md 更新は各タスク完了時に同 commit に含める
- progress.yaml 更新は Wave 2 完了時に最終 commit に含める

## 後発追加タスク (`task-plan.md` 以降に発生したもの)

- なし (デフォルト)
