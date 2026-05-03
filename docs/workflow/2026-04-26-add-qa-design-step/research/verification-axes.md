# Research Note: verification-axes

- **Identifier:** 2026-04-26-add-qa-design-step
- **Topic:** verification-axes
- **Researcher:** Main (intent-analyst → researcher 兼任、業界 test taxonomy 知識ベース)
- **Created at:** 2026-04-26T13:50:00Z
- **Scope:** 2 軸 (実行主体 `automated/ai-driven/manual` × 検証スタイル `assertion/scenario/observation/inspection`) の値域妥当性確認と、組み合わせ運用ガイド

## 調査対象

Intent Spec で確定済みの 2 軸抽象化 (実行主体 × 検証スタイル) について:

1. 各軸の値域が必要十分か (もれ・重複がないか)
2. 業界の既存 test taxonomy との対応関係
3. 12 通りの組み合わせ (3 × 4) のうち、推奨/非推奨の判別

## 発見事項

### 軸 A: 実行主体 (3 値)

| 値          | 意味                                                     | 想定具体ツール (qa-design.md には書かない)             |
| ----------- | -------------------------------------------------------- | ------------------------------------------------------ |
| `automated` | テストランナー / スクリプトが完全自動実行 (人間関与なし) | Vitest, Jest, pytest, go test, mocha, JUnit, ginkgo 等 |
| `ai-driven` | AI エージェントが対話的に手順を実行                      | Claude のブラウザ操作、AI による CLI 実行・ログ解釈 等 |
| `manual`    | 人間が手動で操作・確認                                   | 手順書ベースの目視確認、UAT 等                         |

**境界の判別基準:**

- `automated`: CI で 1 コマンドで完全再現可能、人間判断不要
- `ai-driven`: AI が判断を伴う手順を実行 (ブラウザ操作中の意思決定、結果の文脈解釈)
- `manual`: 人間の主観判断や物理操作が必要

**カバレッジ評価:** 3 値で必要十分。「半自動 (人間が手順実行)」のような中間値は、本質的には `manual` のサブカテゴリ (記録形式が手順書か checklist か) で運用上区別する必要が薄い。

### 軸 B: 検証スタイル (4 値)

| 値            | 意味                                                                          | 業界対応                                          |
| ------------- | ----------------------------------------------------------------------------- | ------------------------------------------------- |
| `assertion`   | 期待値と実測値の等価判定 (関数戻り値 / API レスポンス / 状態スナップショット) | TDD, Property-based testing, snapshot testing 等  |
| `scenario`    | 一連の操作フローの結果検証 (前提状態 → 操作列 → 終了状態)                     | BDD (Given-When-Then), E2E testing, smoke test 等 |
| `observation` | 数値・ログ・メトリクスの観測と閾値判定                                        | Performance testing, observability test 等        |
| `inspection`  | 主観・定性的な確認 (見た目、UX、ログレビュー、コード品質目視)                 | Exploratory testing, manual UX testing 等         |

**境界の判別基準:**

- `assertion` vs `scenario`: 単一呼び出し / 単一状態の検証は `assertion`、複数ステップの順次実行を伴う検証は `scenario`
- `assertion` vs `observation`: 値の等価判定は `assertion`、閾値超過/累積値判定は `observation` (例: `expect(latency).toBe(50)` は assertion、「p95 < 200ms」は observation)
- `observation` vs `inspection`: 機械的に数値化できるなら `observation`、人間/AI の解釈を要するなら `inspection`

**カバレッジ評価:** 4 値で必要十分。

- `assertion`: 単純な等価系すべて
- `scenario`: フロー系すべて
- `observation`: 計測系すべて
- `inspection`: 主観系すべて (機械的に判定不可能な領域)

「security testing」「accessibility testing」のような既存カテゴリは、本軸では「目的による分類」であって、本軸 (実行主体 × 検証スタイル) と直交する別次元。例: セキュリティスキャン = `automated × observation`、ペンテスト手動 = `manual × scenario`。

### 12 通りの組み合わせの妥当性

| 実行主体 \ 検証スタイル | `assertion`                            | `scenario`                                | `observation`                        | `inspection`                              |
| ----------------------- | -------------------------------------- | ----------------------------------------- | ------------------------------------ | ----------------------------------------- |
| `automated`             | ✓ 単体テスト等 (最も典型)              | ✓ E2E スクリプト                          | ✓ メトリクス自動計測 + 閾値          | ✗ 自動化困難 (主観判定の機械化は本質矛盾) |
| `ai-driven`             | △ 過剰 (assertion は automated で十分) | ✓ AI ブラウザ操作 / AI による複雑シナリオ | ✓ AI によるログ解析 / 異常検知       | ✓ AI による UX 評価 / コードレビュー      |
| `manual`                | △ 非効率 (人間が等価判定する場面少)    | ✓ 手動シナリオ / UAT                      | △ 計測は自動化が原則、手動は補助のみ | ✓ 目視確認 / UX レビュー                  |

**有効な組み合わせ (✓): 8 件**
**条件付きの組み合わせ (△): 3 件** (理由付きで採用可)
**本質矛盾 (✗): 1 件** (`automated × inspection` は採用しない)

`automated × inspection` の不採用根拠: 主観判定 (色味、UX 自然さ等) を機械が下せるなら、それは `observation` (機械化された定量指標) であって `inspection` ではない。両者の境界が曖昧になる組み合わせは採用しない。

### 業界 taxonomy との対応マッピング

| 業界カテゴリ                | 本 2 軸での表現                                       |
| --------------------------- | ----------------------------------------------------- |
| Unit test (TDD)             | `automated × assertion`                               |
| Integration test            | `automated × assertion` または `automated × scenario` |
| E2E test (Selenium 等)      | `automated × scenario`                                |
| BDD (Cucumber 等)           | `automated × scenario` (Given-When-Then を機械実行)   |
| Property-based testing      | `automated × assertion` (生成値 + 不変条件)           |
| Snapshot testing            | `automated × assertion`                               |
| Performance test            | `automated × observation`                             |
| Load / Stress test          | `automated × observation`                             |
| Security scan (SAST/DAST)   | `automated × observation`                             |
| Penetration test (manual)   | `manual × scenario`                                   |
| Accessibility test (axe 等) | `automated × observation`                             |
| Manual UX test              | `manual × inspection`                                 |
| Exploratory test            | `manual × scenario` または `manual × inspection`      |
| AI-assisted browser test    | `ai-driven × scenario`                                |
| AI による code review       | `ai-driven × inspection`                              |
| Smoke test                  | `automated × scenario` (軽量版)                       |

→ 既存業界 taxonomy はすべて 2 軸の組み合わせで表現可能。本 2 軸で十分網羅的。

## 引用元

- Mike Cohn "Test Pyramid" (Unit / Service / UI 階層の概念) — 本 2 軸では実行主体に階層的概念を持たない代わりに、検証スタイルで表現
- BDD (Cucumber, RSpec) ドキュメント — Given-When-Then を `scenario` の代表例として
- ISTQB Foundation Level Syllabus — テスト分類 (functional / non-functional / structural) のうち、本 2 軸は「functional / non-functional / structural」とは直交し、「どう実行・検証するか」を扱う
- 既存議論履歴 (本会話の Plan モードでの 2 軸抽象化決定)

## 設計への含意

1. **qa-design.md の必須列に軸 A (実行主体) と軸 B (検証スタイル) を独立列として持たせる** (1 列にまとめると組み合わせがマスクされる)
2. **値域は固定** (軸 A: 3 値、軸 B: 4 値)。reference に enum として明記
3. **`automated × inspection` は禁止組み合わせ**として reference に明記。レビューで該当を発見したら `observation` への振り分けを促す
4. **`△` 組み合わせは「理由付きで採用可」**として、qa-design.md の備考列に理由を書く運用 (例: `manual × assertion` を採用するなら「機械検証手段がまだない実験段階」等の理由)
5. **業界 taxonomy との対応表は reference に含める** (qa-analyst や implementer が「Unit test を書きたいけどどの組み合わせ?」と迷ったときの参照用)
6. **2 軸の値は qa-design.md の列に英小文字 (`automated`, `assertion` 等) で記録**。i18n 不要、enum として機械的に扱える形

## 残存する不明点

- **`scenario` と `observation` の境界の現実的な判別**: 例えば「API 呼び出し → レスポンス時間が 200ms 未満」は assertion (200 = 200) でも observation (時間計測) でもどちらにも振れる。設計判断として「閾値判定 = observation」を採用 (assertion は厳密な等価判定のみ) するか、Step 3 Design で確定
