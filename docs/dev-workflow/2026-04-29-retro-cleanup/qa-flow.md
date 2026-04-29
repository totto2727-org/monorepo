# QA Flow: 2026-04-29-retro-cleanup

本サイクルは静的観測のみのため、本質ロジック分岐は単純。ファイル存在 / grep 件数 / 行数の各観点から TC を分配。

## 全体フロー

```mermaid
flowchart TD
  Start[Step 8 Validation 開始] --> Cat1{TC カテゴリ}

  Cat1 -->|本文追記検証| GrepBody[A. Specialist 本文 grep]
  Cat1 -->|ADR 検証| GrepADR[B. ADR 存在 + 内容 grep]
  Cat1 -->|構造変更検証| GrepStructure[C. retrospective 削除 + 新パス + ポリシー]
  Cat1 -->|既存機能維持| GrepRegression[D. skill-reviewer 違反検出 + regression]

  GrepBody --> TC001[TC-001 dev-workflow 3-5 案]
  GrepBody --> TC002[TC-002 holistic 小節]
  GrepBody --> TC003[TC-003 design 整合性]
  GrepBody --> TC004[TC-004 SHA 列挙]

  GrepADR --> TC005[TC-005 ADR ファイル存在]
  GrepADR --> TC006[TC-006 ADR キーワード]
  GrepADR --> TC007[TC-007 confirmed: false]

  GrepStructure --> TC008[TC-008..010 過去 3 件削除]
  GrepStructure --> TC011[TC-011 新ディレクトリ存在]
  GrepStructure --> TC012[TC-012 本サイクル retrospective 新パス]
  GrepStructure --> TC013[TC-013 4 ファイルで新パス言及]
  GrepStructure --> TC014[TC-014 削除ポリシー記述]

  GrepRegression --> TC015[TC-015 dev-workflow ≤ 5000 語]
  GrepRegression --> TC016[TC-016 全 specialist ≤ 5000 語]
  GrepRegression --> TC017[TC-017 行数 +30% 以内]
  GrepRegression --> TC018[TC-018 description ≤ 1024 文字]
  GrepRegression --> TC019[TC-019 フラット構造方針]
  GrepRegression --> TC020[TC-020 self-review 0 件]

  TC001 --> AllPass{全 TC PASS?}
  TC002 --> AllPass
  TC003 --> AllPass
  TC004 --> AllPass
  TC005 --> AllPass
  TC006 --> AllPass
  TC007 --> AllPass
  TC008 --> AllPass
  TC011 --> AllPass
  TC012 --> AllPass
  TC013 --> AllPass
  TC014 --> AllPass
  TC015 --> AllPass
  TC016 --> AllPass
  TC017 --> AllPass
  TC018 --> AllPass
  TC019 --> AllPass
  TC020 --> AllPass

  AllPass -->|Yes| Complete[Step 8 完了 → Step 9 へ]
  AllPass -->|No| Backtrack[Step 6 に差し戻し]
```

## 過去 3 件削除分岐の詳細

```mermaid
flowchart LR
  Check1[2026-04-24 retrospective.md] -->|file exists| Fail1[FAIL]
  Check1 -->|file absent| Pass1[PASS TC-008]
  Check2[2026-04-26 retrospective.md] -->|file exists| Fail2[FAIL]
  Check2 -->|file absent| Pass2[PASS TC-009]
  Check3[2026-04-29-integrate-self-review retrospective.md] -->|file exists| Fail3[FAIL]
  Check3 -->|file absent| Pass3[PASS TC-010]
```

## 各葉の TC-ID 対応

| 分岐結果 | TC-ID または skip 理由 |
|---|---|
| 全 TC PASS | Step 8 完了 |
| 1 つでも FAIL | Step 6 に差し戻し (該当タスクの再活性化) |
| TC-012 (Step 8 時点) | skip [Step 9 完了後に検証可、Step 8 では未検証で OK] |
| TC-IMPL-NNN | skip [Step 6 implementer が必要時に追記、現時点で予測なし] |

## 補足

- 全 TC のうち `manual × inspection` は TC-019 のみ (1/20 件、5%)
- 残り 19 件は automated でバッチ実行可能
- Step 6 ↔ Step 7 ループ (Round 1 で Major 検出 → Round 2 修正) は本サイクルでも適用
