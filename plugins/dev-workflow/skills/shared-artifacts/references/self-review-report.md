# Reference: `self-review-report.md` の書き方

## 目的

implementer チームが生成した**全 diff を統合的にレビュー**し、外部レビュー前に明らかな問題（`design.md` 違反、Intent Spec 未達見込み、明白な bug、テスト網羅不足等）を潰す。Step 8 の外部観点レビューとは別層。

## 作成者 / 作成タイミング

- **作成者:** `self-reviewer` Specialist（単一インスタンス）
- **作成ステップ:** Step 7 (Self-Review)
- **承認:** Main 判定。High 指摘残があれば Step 6 に戻る

## ファイル位置

`docs/dev-workflow/<identifier>/self-review-report.md`

## 各セクションの書き方

### サマリ

深刻度別件数表と Gate 判定:

| 深刻度 | 件数  |
| ------ | ----- |
| High   | {{n}} |
| Medium | {{n}} |
| Low    | {{n}} |

**Gate 判定:** `passed` / `failed` (High 残あり)

### 指摘事項

各指摘に以下を付記:

- **深刻度:** High / Medium / Low
- **該当箇所:** コミット SHA + ファイル + 行番号 + 該当タスク ID
- **問題の要約:** 何が問題か（1–2 文）
- **根拠:** なぜ問題か（`design.md` / `intent-spec.md` のどこと矛盾するか）
- **推奨アクション:** 具体的な修正方針
- **design.md との関連:** 該当章節
- **Status:** `open` / `fixed` / `wontfix_with_reason`

### 深刻度の判定基準

| 深刻度     | 対応                                            |
| ---------- | ----------------------------------------------- |
| **High**   | 修正必須。これを残したまま Step 8 に進めない    |
| **Medium** | 修正推奨。Retrospective で扱うか、Step 8 で判断 |
| **Low**    | 記録のみ（提案レベル）                          |

### ADR / Intent Spec との整合性チェック

- **Intent Spec 成功基準:** 満たす見込みあり / 懸念あり / 未達の恐れあり
- **Design Document との整合:** 準拠 / 部分的に逸脱 / 大きく逸脱
- **詳細:** 具体的にどこが整合していないか

### 修正ラウンド履歴

Self-Review → Implementation → Self-Review のループ履歴を記録:

- Round 1: High 3 件検出、Step 6 に差し戻し
- Round 2: High 0 件、Gate 通過

## Self-Review の焦点

外部観点（security / performance / readability 等）は **Step 8 `specialist-reviewer`** の領域。Self-Review の焦点は以下:

- `design.md` の設計判断に違反していないか
- `intent-spec.md` の成功基準を満たす見込みがあるか
- 明白な bug（null 参照、エッジケース漏れ、型の誤用など）
- Task Plan 内で発見された未対応事項
- テスト網羅性の明らかな不足
- 型安全性・エラーハンドリングの実装品質

## 品質基準

| ✅ よい                                        | ❌ 悪い                          |
| ---------------------------------------------- | -------------------------------- |
| 全指摘に具体的コミット SHA + 行番号がある      | 「〜の辺り」のような曖昧な位置   |
| 根拠が `design.md` の章節まで降りている        | 「違和感がある」など主観         |
| High / Medium / Low が妥当な判断で分かれている | 全てを High にして意味を失わせる |
| 推奨アクションが具体的で実装可能               | 「改善してほしい」のような抽象   |

## 関連成果物

- **入力:** 全 Git コミット diff、`design.md`、`intent-spec.md`、`task-plan.md`
- **出力先:** High 指摘 → `TODO.md` の該当タスクを `in_progress` に戻し `re_activations` カウントアップ
- **後続:** `retrospective.md` が High 指摘の根本原因を分析（設計レベルなら Step 1〜3 への回帰を提案）
