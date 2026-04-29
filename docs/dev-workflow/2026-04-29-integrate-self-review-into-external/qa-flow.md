# QA Flow: Integrate Self-Review (Step 7) into External Review

- **Identifier:** 2026-04-29-integrate-self-review-into-external
- **Author:** qa-analyst (Specialist instance #1)
- **Source:** `qa-design.md`
- **Created at:** 2026-04-29T15:00:00Z
- **Last updated:** 2026-04-29T15:00:00Z
- **Status:** draft <!-- draft | approved -->

このドキュメントは `qa-design.md` のテストケース 18 件を **Mermaid flowchart で可視化**した網羅性確認用の図集。本サイクルは Markdown プラグインの自己改修であるため、実行コードのフロー図ではなく **「変更ファイルの種別 × 検証種別」の決定木** を可視化する。書き方の詳細は `plugins/dev-workflow/skills/shared-artifacts/references/qa-flow.md` を参照。

## 概要

本ドキュメントは次の 4 関心領域に分割する。

1. **削除確認** (SC-1〜SC-4 / TC-001〜TC-004): 旧 Self-Review 関連 4 ファイルの非存在確認
2. **残存表記の根絶** (SC-5〜SC-8 / TC-005〜TC-008): grep ベースの旧表記 0 件確認
3. **構造的完全性** (SC-9〜SC-13 / TC-009〜TC-013): 主要更新ファイル群の構造再付番 / 観点追加 / フィールド削除
4. **メタ整合性** (SC-14〜SC-17 / TC-014〜TC-017): README / plugin.json / agents/ ディレクトリ / クロスリファレンスの整合
5. **横断的処理** (TC-018): 検証コマンドセット 1 セット連続実行のシナリオ

各葉に `qa-design.md` の TC-NNN または `skip [理由]` を割り付ける。ループは存在しない（Markdown 静的検証は 1 パスで完結）ため、すべて単純な分岐構造で表現可能。

---

## 削除確認

このセクションがカバーする成功基準: SC-1, SC-2, SC-3, SC-4

旧 Self-Review 関連の 4 ファイル（ディレクトリ + agent + template + reference）について、それぞれ独立に存在 / 非存在を判定する。

```mermaid
flowchart TD
  Start([Step 8 validator 起動]) --> Q1{削除対象の種別}
  Q1 -->|ディレクトリ specialist-self-reviewer/| TC1[TC-001: test ! -d で 0 終了]
  Q1 -->|agent self-reviewer.md| TC2[TC-002: test ! -f で 0 終了]
  Q1 -->|template self-review-report.md| TC3[TC-003: test ! -f で 0 終了]
  Q1 -->|reference self-review-report.md| TC4[TC-004: test ! -f で 0 終了]
  TC1 --> Done([削除確認完了])
  TC2 --> Done
  TC3 --> Done
  TC4 --> Done
```

---

## 残存表記の根絶

このセクションがカバーする成功基準: SC-5, SC-6, SC-7, SC-8

`plugins/dev-workflow/` 配下の Markdown / JSON / YAML を grep して旧表記が 0 件であることを確認する。4 種類の grep パターンを並列で実行し、AND 条件で合格判定する。

```mermaid
flowchart TD
  Start([grep セッション開始]) --> Q1{検索パターン}
  Q1 -->|self[-_]review / Self-Review| TC5[TC-005: 0 件で PASS]
  Q1 -->|self-reviewer / specialist-self-reviewer| TC6[TC-006: 0 件で PASS]
  Q1 -->|Step 10| TC7[TC-007: 0 件で PASS]
  Q1 -->|Step 9 Validation / Step 10 Retrospective| TC8[TC-008: 0 件で PASS]
  TC5 --> Agg{全 4 件 PASS?}
  TC6 --> Agg
  TC7 --> Agg
  TC8 --> Agg
  Agg -->|true| OK([残存表記 0 件 確認完了])
  Agg -->|false| NG[skip: いずれか 1 件でも 1 以上ヒット したら Step 6 再活性化対象 - validator が validation-report.md に記録]
```

---

## 構造的完全性

このセクションがカバーする成功基準: SC-9, SC-10, SC-11, SC-12, SC-13

dev-workflow / specialist-reviewer / shared-artifacts の 3 主要 SKILL.md および progress.yaml の構造 (テーブル行数 / セル内容 / フィールド有無) を確認する。**5 つの独立判定**で構成され、ループなし。

```mermaid
flowchart TD
  Start([構造検証フェーズ]) --> Q1{対象ファイル}
  Q1 -->|dev-workflow/SKILL.md ステップ表| Q9{ステップ表の行数 X}
  Q9 -->|X = 9 かつ Step 7 行が External Review| TC9[TC-009: PASS - 行数 + セル意味判定]
  Q9 -->|X != 9 または Step 7 行が外れている| NG9[skip: 構造ミス - implementer 修正]
  Q1 -->|dev-workflow/SKILL.md ロールバック表| Q10{Step 7/8/9 エントリ + 旧 Self-Review 知見の吸収}
  Q10 -->|3 エントリ揃い 旧知見 吸収済み| TC10[TC-010: PASS]
  Q10 -->|エントリ不足 または 知見未吸収| NG10[skip: 知見の追記が不足 - implementer 修正]
  Q1 -->|specialist-reviewer/SKILL.md| Q11{holistic / 全体整合性 / 整合性 ヒット数 N}
  Q11 -->|N gteq 5| TC11[TC-011: PASS]
  Q11 -->|N lt 5| NG11[skip: 観点追加の本文が薄い - implementer 修正]
  Q1 -->|shared-artifacts/SKILL.md 成果物表| Q12{self-review-report 行 削除 + 連番再付番}
  Q12 -->|削除 + 連番OK| TC12[TC-012: PASS]
  Q12 -->|残存 または 欠番| NG12[skip: 表 修正不足 - implementer 修正]
  Q1 -->|shared-artifacts/templates/progress.yaml| Q13{self_review: フィールド存在}
  Q13 -->|不在| TC13[TC-013: PASS]
  Q13 -->|残存| NG13[skip: フィールド削除漏れ - implementer 修正]
  TC9 --> Done([構造検証完了])
  TC10 --> Done
  TC11 --> Done
  TC12 --> Done
  TC13 --> Done
```

---

## メタ整合性

このセクションがカバーする成功基準: SC-14, SC-15, SC-16, SC-17

README / plugin.json / agents/ ディレクトリ全体 / クロスリファレンスのメタレベル整合を確認する。SC-14, SC-15, SC-16 は automated 補助 + 目視のハイブリッド、SC-17 のみ純粋に manual。

```mermaid
flowchart TD
  Start([メタ整合性フェーズ]) --> Q1{対象アーティファクト}
  Q1 -->|README.md| Q14{9-step 表記存在 + 10-step 表記不在 + ステップ列挙意味整合}
  Q14 -->|3 条件 全て 満たす| TC14[TC-014: PASS]
  Q14 -->|条件 不足| NG14[skip: README 旧構成残存 - implementer 修正]
  Q1 -->|.claude-plugin/plugin.json| Q15{Self-Review 表記 0 件 かつ 9-step 表記 1 件以上}
  Q15 -->|2 条件 満たす| TC15[TC-015: PASS]
  Q15 -->|条件 不足| NG15[skip: plugin.json description 旧記述 - implementer 修正]
  Q1 -->|agents/ ディレクトリ| Q16{ファイル数 = 9 かつ self-review 言及 0 件}
  Q16 -->|2 条件 満たす| TC16[TC-016: PASS]
  Q16 -->|条件 不足| NG16[skip: agents/ ファイル数違反 または 言及残存 - implementer 修正]
  Q1 -->|スキル間 クロスリファレンス| Q17{旧リンク 0 件 かつ 新リンクの 参照先 全て 実在}
  Q17 -->|2 条件 満たす 目視 確認| TC17[TC-017: PASS]
  Q17 -->|リンク切れ 1 件以上| NG17[skip: クロスリファレンス修正不足 - implementer 修正]
  TC14 --> Done([メタ整合性 確認 完了])
  TC15 --> Done
  TC16 --> Done
  TC17 --> Done
```

---

## 横断的処理 (シナリオ系)

このセクションがカバーする成功基準: (なし、TC-018 派生検証)

design.md L438–L494 の検証コマンドセット全体を 1 セッションで連続実行し、コマンド遂行性を確認する。**個別 TC-001〜TC-017 と二重カバレッジになるが、validator の実行手順遵守を独立に保証する目的**。

```mermaid
flowchart TD
  Start([Step 8 Validation 最終ステージ]) --> Cmd1[design.md L438–L444 削除確認 4 件]
  Cmd1 --> Cmd2[design.md L447–L450 self-review 表記 0 件]
  Cmd2 --> Cmd3[design.md L453–L456 self-reviewer 0 件]
  Cmd3 --> Cmd4[design.md L459–L462 Step 10 0 件]
  Cmd4 --> Cmd5[design.md L465–L468 旧番号 ステップ参照 0 件]
  Cmd5 --> Cmd6[design.md L471–L473 progress.yaml self_review 0 件]
  Cmd6 --> Cmd7[design.md L476–L478 holistic / 全体整合性 5 件以上]
  Cmd7 --> Cmd8[design.md L481–L483 agents 9 ファイル]
  Cmd8 --> Cmd9[design.md L485–L487 README 9-step]
  Cmd9 --> Cmd10[design.md L489–L493 plugin.json 9-step]
  Cmd10 --> Q{全コマンド期待値 一致?}
  Q -->|true| TC18[TC-018: PASS]
  Q -->|false| NG[skip: 個別 TC-001〜TC-017 の どこか で 失敗 - 該当 TC を 個別 修正]
  TC18 --> Done([全 17 SC + 派生 TC-018 検証 完了])
```

---

## 実装都合分岐

このセクションがカバーする成功基準: (なし、TC-IMPL-NNN 用、Step 4 時点では空)

Step 6 implementer が発見した実装都合分岐をここに集約する。Step 4 時点では空でよい。

`qa-design.md` の「実装都合テストケース」セクションに記載した予測ヒント (TC-IMPL 候補 A〜D: 番号繰り上げ後の Markdown 整合性 / frontmatter スキーマ違反 / agent description 文字数制約 / 内部リンク参照先存在検証) を Step 6 implementer が必要に応じて TC-IMPL-001〜 の連番で追記する。追記時は本セクションに対応する Mermaid flowchart を追加する。

```mermaid
flowchart TD
  Start([Step 6 で 発見した 実装都合 分岐]) --> Skip[skip: Step 4 時点では空 - Step 6 implementer が 必要に応じて 追記]
```

<!-- Step 6 で TC-IMPL-001 が追記されたら、上記 skip ノードを置き換えて以下のような分岐を記述する例:
```mermaid
flowchart TD
  Start([番号繰り上げ後の Markdown 整合性]) --> Q1{複合表現 Step 6 ↔ Step 7 の 7 が 旧 / 新 どちらの 番号体系か}
  Q1 -->|placeholder で 保護済み 文脈で意味 整合| TC_impl1[TC-IMPL-001: PASS]
  Q1 -->|意味 不整合 検出| NG_impl1[skip: implementer 再修正]
```
-->
