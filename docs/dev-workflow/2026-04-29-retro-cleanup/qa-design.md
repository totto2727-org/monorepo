# QA Design: 2026-04-29-retro-cleanup

- **Identifier:** 2026-04-29-retro-cleanup
- **Author:** Main (qa-analyst 兼任、軽量スコープのため)
- **Created at:** 2026-04-29T13:30:00Z
- **Status:** draft

## 概要

本サイクルは Markdown / YAML / JSON のみを対象とし、実行可能コードを含まない。検証は **静的観測** (file existence + grep + 行数 / 語数) に統一。Intent Spec の 20 成功基準 (SC-1..SC-20) を 20 本の TC に 1:1 マッピングする。

## 2 軸 enum

- **軸 A 実行主体**: `automated` (CI / スクリプト) / `manual` (人間)
- **軸 B 検証スタイル**: `existence` (file/dir 有無) / `count` (grep 件数) / `structural` (構造観測) / `inspection` (人間目視)

## 本質テストケース (TC-NNN)

### A. 本文への運用ルール追記 (4 件)

#### TC-001: A-2 — dev-workflow に 3-5 案ルールが追記されている

- **対象成功基準:** SC-1
- **軸 A:** automated
- **軸 B:** count
- **判定基準:** `ggrep -nE '3-5|3〜5|3 から 5' plugins/dev-workflow/skills/dev-workflow/SKILL.md` が **1 件以上**、かつヒット行が `Report-Based Confirmation` セクション内 (前後 30 行以内) であること
- **手順:** grep 実行 + 行番号確認

#### TC-002: A-5 — specialist-reviewer 本文に holistic 小節が新設されている

- **対象成功基準:** SC-2
- **軸 A:** automated
- **軸 B:** count
- **判定基準:** `ggrep -nE '^#### holistic' plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` が **1 件以上**
- **手順:** grep 実行

#### TC-003: A-5 — holistic 小節に design ↔ 実装整合性チェック記述がある

- **対象成功基準:** SC-3
- **軸 A:** automated
- **軸 B:** count
- **判定基準:** `ggrep -nE 'design\.md と実装|design\.md.*整合|整合性チェック' plugins/dev-workflow/skills/specialist-reviewer/SKILL.md` が **1 件以上**
- **手順:** grep 実行

#### TC-004: A-8 — specialist-retrospective-writer に再活性化 SHA 列挙手順が追記されている

- **対象成功基準:** SC-4
- **軸 A:** automated
- **軸 B:** count
- **判定基準:** `ggrep -nE 're_activations|再活性化.*SHA|SHA.*列挙' plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md` が **1 件以上**
- **手順:** grep 実行

### B. ADR 起票 (3 件)

#### TC-005: ADR ファイルが新規 1 件追加されている

- **対象成功基準:** SC-5
- **軸 A:** automated
- **軸 B:** existence
- **判定基準:** `ls docs/adr/*researcher*skill*.md 2>/dev/null` が 1 件、または内容が A-4 関連の新規 ADR ファイルが docs/adr/ 配下に存在
- **手順:** ファイル存在確認

#### TC-006: ADR 本文に必須キーワードが含まれている

- **対象成功基準:** SC-6
- **軸 A:** automated
- **軸 B:** count
- **判定基準:** ADR 本文に `Decision` / `Impact` / `再検討トリガー` / `2026-04-26-add-qa-design-step` の各キーワードが grep で検出される (各 1 件以上)
- **手順:** grep 実行 (ADR ファイル内)

#### TC-007: ADR の frontmatter が `confirmed: false`

- **対象成功基準:** SC-7
- **軸 A:** automated
- **軸 B:** structural
- **判定基準:** ADR の frontmatter (`---` で囲まれた YAML 部) に `confirmed: false` が含まれる
- **手順:** `head -5 <ADR ファイル>` で目視 + grep `^confirmed: false`

### C. retrospective 構造変更 (7 件)

#### TC-008: 過去 retrospective #1 が削除されている

- **対象成功基準:** SC-8
- **軸 A:** automated
- **軸 B:** existence
- **判定基準:** `test ! -f docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md`
- **手順:** ファイル不在確認

#### TC-009: 過去 retrospective #2 が削除されている

- **対象成功基準:** SC-9
- **軸 A:** automated
- **軸 B:** existence
- **判定基準:** `test ! -f docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md`
- **手順:** ファイル不在確認

#### TC-010: 過去 retrospective #3 が削除されている

- **対象成功基準:** SC-10
- **軸 A:** automated
- **軸 B:** existence
- **判定基準:** `test ! -f docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md`
- **手順:** ファイル不在確認

#### TC-011: docs/retrospective/ ディレクトリが存在する

- **対象成功基準:** SC-11
- **軸 A:** automated
- **軸 B:** existence
- **判定基準:** `test -d docs/retrospective`
- **手順:** ディレクトリ存在確認 (Step 9 で本サイクル分の retrospective 保存時に自動作成可)

#### TC-012: 本サイクル自身の retrospective が新パスに保存されている (Step 9 完了後検証)

- **対象成功基準:** SC-12
- **軸 A:** automated
- **軸 B:** existence
- **判定基準:** `test -f docs/retrospective/2026-04-29-retro-cleanup.md` (Step 9 完了後)
- **手順:** ファイル存在確認 (Step 9 完了後でないと検証不可、Step 8 では skip 可)

#### TC-013: スキル本文に新パス記述が反映されている

- **対象成功基準:** SC-13
- **軸 A:** automated
- **軸 B:** count
- **判定基準:** `ggrep -nF 'docs/retrospective/' plugins/dev-workflow/skills/dev-workflow/SKILL.md plugins/dev-workflow/skills/shared-artifacts/SKILL.md plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md` の結果が **各ファイル 1 件以上**
- **手順:** 4 ファイルそれぞれで grep 実行、各 1 件以上を確認

#### TC-014: 削除ポリシーが reference または skill 本文に記載されている

- **対象成功基準:** SC-14
- **軸 A:** automated
- **軸 B:** count
- **判定基準:** `ggrep -nE '削除|揮発|報告ボックス|temporary' plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md plugins/dev-workflow/skills/dev-workflow/SKILL.md` の結果が **1 件以上**
- **手順:** grep 実行

### D. 既存機能の維持 (6 件)

#### TC-015: dev-workflow/SKILL.md の語数が 5,000 語以下

- **対象成功基準:** SC-15
- **軸 A:** automated
- **軸 B:** structural
- **判定基準:** `gwc -w plugins/dev-workflow/skills/dev-workflow/SKILL.md` が 5000 以下 (現状 3733)
- **手順:** wc -w 実行

#### TC-016: 全 specialist-* SKILL.md の語数が 5,000 語以下

- **対象成功基準:** SC-16
- **軸 A:** automated
- **軸 B:** structural
- **判定基準:** `gwc -w plugins/dev-workflow/skills/specialist-*/SKILL.md` の各行が 5000 以下
- **手順:** wc -w 実行 + 各値確認

#### TC-017: 触る 3 specialist の本体行数が既存比 +30% 以内

- **対象成功基準:** SC-17
- **軸 A:** automated
- **軸 B:** structural
- **判定基準:**
  - architect: 100 行 → ≤ 130 行 (現状 architect は本サイクル non-touching、念のため check)
  - reviewer: 139 行 → ≤ 181 行
  - retrospective-writer: 99 行 → ≤ 129 行
- **手順:** wc -l 実行 + 計算
- **備考:** A-2 は dev-workflow に集約されたため architect 本体は本サイクル不変。実質チェック対象は reviewer / retrospective-writer のみ。dev-workflow 自体の +30% 制約は SC-15 の語数で代用

#### TC-018: 全 specialist の description が 1024 文字以内

- **対象成功基準:** SC-18
- **軸 A:** automated
- **軸 B:** structural
- **判定基準:** 各 SKILL.md の frontmatter description (改行込み) を `gwc -m` で測定し ≤ 1024
- **手順:** awk または gsed で frontmatter 抽出 + wc -m

#### TC-019: 既存 ADR `2026-04-26-dev-workflow-rename-and-flatten.md` のフラット構造方針に違反しない

- **対象成功基準:** SC-19
- **軸 A:** manual
- **軸 B:** inspection
- **判定基準:** ステップ削除 / 追加 / フェーズ概念再導入が発生していない
- **手順:** dev-workflow/SKILL.md の Step 構成を目視 + フェーズ概念キーワード grep が 0 件

#### TC-020: 既存 grep ベース成功基準パターンが破壊されていない

- **対象成功基準:** SC-20
- **軸 A:** automated
- **軸 B:** count
- **判定基準:** `ggrep -rnE -i 'self[-_]review|Self-Review' plugins/dev-workflow/` が **0 件** (直前サイクルの達成状態を維持)
- **手順:** grep 実行

## 実装都合テストケース (TC-IMPL-NNN)

Step 6 implementer が必要に応じて追記する。本サイクルは追記中心の単純な作業のため、現時点で予測される実装都合テストはなし。

## カバレッジ表

| Intent Spec SC | 対応 TC | 軸 A | 軸 B |
|---|---|---|---|
| SC-1 | TC-001 | automated | count |
| SC-2 | TC-002 | automated | count |
| SC-3 | TC-003 | automated | count |
| SC-4 | TC-004 | automated | count |
| SC-5 | TC-005 | automated | existence |
| SC-6 | TC-006 | automated | count |
| SC-7 | TC-007 | automated | structural |
| SC-8 | TC-008 | automated | existence |
| SC-9 | TC-009 | automated | existence |
| SC-10 | TC-010 | automated | existence |
| SC-11 | TC-011 | automated | existence |
| SC-12 | TC-012 | automated | existence |
| SC-13 | TC-013 | automated | count |
| SC-14 | TC-014 | automated | count |
| SC-15 | TC-015 | automated | structural |
| SC-16 | TC-016 | automated | structural |
| SC-17 | TC-017 | automated | structural |
| SC-18 | TC-018 | automated | structural |
| SC-19 | TC-019 | manual | inspection |
| SC-20 | TC-020 | automated | count |

**検証主体分布**: automated 19 件 (95%) / manual 1 件 (5%)

**禁止組み合わせ確認**: `automated × inspection` は使用していない (TC-019 のみ inspection で manual)

## Step 8 Validation 一括実行スクリプト案

```bash
#!/bin/bash
echo "=== TC-001..004 specialist 本文追記 ==="
echo "TC-001 A-2 3-5 案: $(ggrep -cnE '3-5|3〜5|3 から 5' plugins/dev-workflow/skills/dev-workflow/SKILL.md)"
echo "TC-002 A-5 holistic 小節: $(ggrep -cnE '^#### holistic' plugins/dev-workflow/skills/specialist-reviewer/SKILL.md)"
echo "TC-003 A-5 design 整合性: $(ggrep -cnE 'design\.md と実装|design\.md.*整合|整合性チェック' plugins/dev-workflow/skills/specialist-reviewer/SKILL.md)"
echo "TC-004 A-8 SHA 列挙: $(ggrep -cnE 're_activations|再活性化.*SHA|SHA.*列挙' plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md)"

echo "=== TC-005..007 ADR ==="
ls docs/adr/*researcher*skill*.md 2>/dev/null | head -1
echo "TC-006 ADR keywords: ..."
echo "TC-007 confirmed: false: ..."

echo "=== TC-008..014 retrospective 構造変更 ==="
[ ! -f docs/dev-workflow/2026-04-24-ai-dlc-plugin-bootstrap/retrospective.md ] && echo TC-008 PASS || echo TC-008 FAIL
[ ! -f docs/dev-workflow/2026-04-26-add-qa-design-step/retrospective.md ] && echo TC-009 PASS || echo TC-009 FAIL
[ ! -f docs/dev-workflow/2026-04-29-integrate-self-review-into-external/retrospective.md ] && echo TC-010 PASS || echo TC-010 FAIL
[ -d docs/retrospective ] && echo TC-011 PASS || echo TC-011 FAIL
echo "TC-013 new path refs:"
for f in plugins/dev-workflow/skills/dev-workflow/SKILL.md plugins/dev-workflow/skills/shared-artifacts/SKILL.md plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md; do
  cnt=$(ggrep -cF 'docs/retrospective/' "$f")
  echo "  $f: $cnt"
done
echo "TC-014 delete policy: $(ggrep -cnE '削除|揮発|報告ボックス|temporary' plugins/dev-workflow/skills/shared-artifacts/references/retrospective.md plugins/dev-workflow/skills/dev-workflow/SKILL.md)"

echo "=== TC-015..020 既存機能維持 ==="
echo "TC-015 dev-workflow words: $(gwc -w plugins/dev-workflow/skills/dev-workflow/SKILL.md | gawk '{print $1}')"
gwc -w plugins/dev-workflow/skills/specialist-*/SKILL.md
gwc -l plugins/dev-workflow/skills/specialist-reviewer/SKILL.md plugins/dev-workflow/skills/specialist-retrospective-writer/SKILL.md
echo "TC-020 self-review residue: $(ggrep -cnE -i 'self[-_]review|Self-Review' -r plugins/dev-workflow/)"
```

詳細は Step 8 で個別実行。
