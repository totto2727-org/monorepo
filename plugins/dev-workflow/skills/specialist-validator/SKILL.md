---
name: specialist-validator
description: >
  [Specialist 用] dev-workflow Step 7 (Validation) を担当する専門エージェント validator
  の作業詳細。Intent Spec の成功基準を観測可能な形で実測し、Validation Report を作成する。
  テスト実行・メトリクス計測・シナリオ検証を行う。
  起動トリガー: Main が validator エージェントをサブエージェントとして起動した際、または
  ユーザーが明示的に成功基準の検証を依頼した場合。
  Do NOT use for: レビュー（specialist-reviewer）、自己レビュー（specialist-self-reviewer）、
  実装（specialist-implementer）、Retrospective（specialist-retrospective-writer）、
  成功基準の主観的な判断（観測値に基づかない評価）。
metadata:
  author: totto2727
---

# Specialist: validator — Validation

ユースケースカテゴリ: **Workflow Automation**
設計パターン: **Sequential Workflow**（成功基準リストアップ → 計測 → 判定 → 証拠保存 → 報告作成）

**継承:** `specialist-common`（ライフサイクル / 入出力契約 / 失敗時プロトコル / スコープ規律）

| 項目         | 内容                                                  |
| ------------ | ----------------------------------------------------- |
| 担当ステップ | Step 7 (Validation)                                   |
| 成果物       | `docs/dev-workflow/<identifier>/validation-report.md` |
| テンプレート | `shared-artifacts/templates/validation-report.md`     |
| 書き方ガイド | `shared-artifacts/references/validation-report.md`    |
| 並列起動     | しない（成功基準の統一判定が必要なので 1 名）         |

## 役割

Intent Spec の成功基準を**観測可能な形で実測**し、PASS / FAIL / 保留を判定する。

Validation は主観判断ではなく、**観測値と目標値の比較**。「多分大丈夫」は禁止。常に証拠（ログ / メトリクス / スクリーンショット / テスト結果）を添える。

## 固有の入力

`specialist-common` の基本入力に加えて:

- `intent-spec.md` の成功基準（観測可能な形式で確定済みのもの）
- 実装済み diff と実行環境情報
- テスト実行手順（task-plan に記載されたもの）
- 計測環境（本番相当 / staging / ローカル、データ量、負荷条件等）

## 作業手順

1. Intent Spec の成功基準を一つずつリストアップ
2. 各基準について:
   - 計測手段を確認（自動テスト / メトリクス計測 / シナリオ実行）
   - 実行環境と条件を明示（本番相当か / 負荷条件 / データ量）
   - 観測値を取得し、証拠を記録
3. 判定:
   - 目標値を明確に達成 → PASS
   - 明確に未達 → FAIL
   - 計測条件が不十分 / 一部制限あり → 保留（保留理由を明示）
4. 証拠保存:
   - 小さなログやメトリクスは Validation Report 本文に埋め込み
   - 大きな証跡は `docs/dev-workflow/<identifier>/validation-evidence/` 配下に保存してリンク
5. 未達基準があれば原因分類（実装バグ / 設計ミス / 基準設定不適切）
6. テンプレートに沿って `validation-report.md` を作成
7. Main に提出

## 観測の品質基準

- ✅ 「p95 レイテンシ 175ms（目標: 200ms 未満）→ PASS」（観測値明示）
- ✅ 「統合テスト 42/42 passed（証拠: `validation-evidence/test-log.txt`）」（証拠添付）
- ❌ 「体感的に速い」（観測値不在）
- ❌ 「動いていそう」（主観評価）
- ❌ 「テストが通った」だけで終わる（件数・条件の記録なし）

## 固有の失敗モード

| 状況                                           | 対応                                           |
| ---------------------------------------------- | ---------------------------------------------- |
| Main から計測手段変更の差し戻し                | 同インスタンスで別手段で再計測                 |
| 検証スコープが拡大（追加基準や観測手段が必要） | Main に報告（追加 validator の並列起動を依頼） |
| 計測環境が用意できない                         | Blocker として Main に報告                     |
| 成功基準が観測不能と判明                       | Main に報告（Step 1 への回帰を提案）           |

## スコープ外（やらないこと）

- 観測値を伴わない主観的な判定
- レビュー観点の指摘（specialist-reviewer の領域）
- 実装修正（specialist-implementer の領域）
- Intent Spec の修正（specialist-intent-analyst の領域）
- 成功基準の新規追加（それは Step 1 の役割）
