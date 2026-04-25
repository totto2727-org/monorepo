---
name: main-verification
description: >
  [Main 用] AI-DLC Phase 3 (Verification) の詳細実行手順を定義する。
  外部レビュー・検証・振り返りの 3 ステップを Specialist 起動仕様付きで提供する。
  独立した観点からの品質レビューと成功基準の実測を行い、
  サイクルの学びを Retrospective に残して完了する。
  起動トリガー: "Verification フェーズを開始", "外部レビュー", "検証フェーズ",
  "Validation を実行", "振り返り", "Retrospective", "ai-dlc の verification"。
  Do NOT use for: ai-dlc ワークフロー全体の管理（main-workflow スキルを使う）、
  意図明確化・設計・タスク分解（main-inception スキルを使う）、
  実装・自己レビュー（main-construction スキルを使う）、
  Specialist 側の作業詳細（specialist-* スキルを使う）、
  自己レビュー未完了の状態での外部レビュー着手。
metadata:
  author: totto2727
  version: 1.0.0
---

# AI-DLC Phase 3 — Verification

ユースケースカテゴリ: **Workflow Automation**
設計パターン: **Sequential Workflow** + **Multi-Service Coordination**（並列レビュー → 統合検証 → 振り返りの段階的集約）

Verification フェーズは、Construction で完成した実装を**独立した観点**から検証し、サイクルの学びを残して完了する。
外部レビュー → 検証 → 振り返り の 3 ステップで、出力は `Review Report` / `Validation Report` / `Retrospective Note`。

**このスキルは `main-workflow` スキル配下で使用される。** `main-workflow` の基本方針・役割定義・調整プロトコル・ユーザー承認ゲート規則（Artifact-as-Gate-Review / Report-Based Confirmation for In-Progress Questions の区別）をすべて継承する。各 Specialist の作業詳細は `specialist-*` スキルに定義されている。

## フェーズ全体

| 項目         | 内容                                                                                                                                |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| 入力         | 実装済み diff（Git コミット）/ `design.md` / `intent-spec.md` / `self-review-report.md`                                             |
| 成果物       | `docs/ai-dlc/<identifier>/review/<aspect>.md` / `validation-report.md` / `retrospective.md`                                         |
| 保存先       | 全て `docs/ai-dlc/<identifier>/` 配下                                                                                               |
| 出口ゲート   | ユーザー承認（Validation 結果を基にした完了判断）                                                                                   |
| 想定ステップ | 7. External Review → 8. Validation → 9. Retrospective                                                                               |
| ロールバック | Blocker 指摘や実装バグは Construction Step 5 へ。設計ミスは Inception Step 3 へ。成功基準の設定自体が不適切なら Inception Step 1 へ |

**コミット方針:** 各成果物と `progress.yaml` を各ステップ完了時にコミット。最終コミットで `retrospective.md` とサイクル完了フラグを記録（詳細は `main-workflow` スキルの「成果物保存構造」参照）。

**対応エージェント・スキル・成果物:**

| Step               | Agent                  | Specialist Skill                  | 成果物（書き方 / テンプレート）                                                                        |
| ------------------ | ---------------------- | --------------------------------- | ------------------------------------------------------------------------------------------------------ |
| 7. External Review | `reviewer` (並列 N)    | `specialist-reviewer`             | `shared-artifacts/references/review-report.md` / `shared-artifacts/templates/review-report.md`         |
| 8. Validation      | `validator`            | `specialist-validator`            | `shared-artifacts/references/validation-report.md` / `shared-artifacts/templates/validation-report.md` |
| 9. Retrospective   | `retrospective-writer` | `specialist-retrospective-writer` | `shared-artifacts/references/retrospective.md` / `shared-artifacts/templates/retrospective.md`         |

Specialist 起動時には **reference（書き方ガイド）とテンプレートの両方のパス**を入力に含めること。各 Specialist は `specialist-common`（横断ルール）と上記の個別スキルを参照する。

---

## フェーズ開始前チェック

Construction の成果物が揃っていることを Main が確認する。

- [ ] 全 diff がコミット済み・レビュー可能な状態
- [ ] 型チェック・リント・既存テスト・新規テストが全て通過
- [ ] `Self-Review Report` に High 指摘がない
- [ ] `design.md` の設計判断に違反する実装がない

いずれか欠けていれば Verification に入らず `main-construction` スキルへ戻る。

---

## Step 7: External Review（外部レビュー）

**目的:** 実装者と独立した観点から品質を検証する

**起動する Specialist:** `reviewer` × N（観点ごとに並列）

**プロジェクト固有ルールの適用:** 各観点（security / performance / readability 等）の具体的な判定基準はプロジェクト固有スキルに従う。Main は `reviewer` 起動時に該当観点に関連するプロジェクトスキルのパスを入力に含める。矛盾時は `main-workflow` の「プロジェクト固有ルールとの関係」に従う。

**観点の例（プロジェクト性質に応じて Main が選定）:**

- セキュリティ（認証認可、入力検証、秘匿情報の取り扱い）
- パフォーマンス（計算量、I/O、メモリ、並行性）
- 可読性・保守性（命名、構造、責務分離、コメント）
- テスト品質（カバレッジ、エッジケース、mock 濫用）
- API 設計（後方互換性、契約の明確さ、エラーモデル）

**Main の作業:**

1. `design.md` と Intent Spec からレビュー観点を導出
2. 観点ごとに `reviewer` を **並列起動**
   - Step 5 / 6 で起動した `implementer` / `self-reviewer` とは**別個の新規インスタンス**として起動（ステップを跨いだ使い回し禁止）
3. 各 `reviewer` に以下を入力として渡す:
   - 全 diff
   - `design.md` の関連部分
   - Intent Spec
   - レビュー観点の明示（「セキュリティのみ」等、スコープ限定）
4. **全 Review Report そのものをユーザーに提示**して判断を仰ぐ（一時レポートは作成しない。各 Review Report 自体がレビュー材料）
5. Blocker 指摘があれば Step 5 に差し戻し（Step 7 の `reviewer` 群は Step 7 完了まで維持）

**Specialist の成果物:**

- 観点ごとに `docs/ai-dlc/<identifier>/review/<aspect>.md`
  - 内容: 指摘 / 深刻度 / 該当箇所（コミット SHA + ファイル行番号）/ 推奨アクション
  - `<aspect>` 例: `security.md`, `performance.md`, `readability.md`, `test-quality.md`, `api-design.md`

**Exit Criteria:**

- Blocker 指摘が 0 件
- Minor 指摘は記録のみで進行可（Retrospective の材料として残す）
- `review/*.md`（全観点）+ `progress.yaml` がコミット済み（1 ステップ = 1 コミット、全観点を 1 コミットにまとめる）
- コミット後、**次ステップ着手時に一時ファイル以外の差分がない状態**

**Gate:** ユーザー承認必須（Blocker 0 件の確認と、Minor 指摘の扱い方針）

**失敗時の挙動:**

- Blocker 指摘が発生 → Construction Step 5 に戻り修正（Construction 再活性化時は新規 `implementer` を起動）。戻り後は Step 6 → Step 7 を再実行（その際 Step 7 は新たに活性化するため新規 `reviewer` を起動）
- 観点が不足していた → **追加観点の `reviewer` を並列起動**（既存の `reviewer` は終了させず維持）
- 既存 `reviewer` のレポートが不明瞭 → **既存インスタンス**に詳細化・根拠追記を指示（差し戻し）
- 複数 `reviewer` の指摘が矛盾 → 両者の根拠を **In-Progress ユーザー問い合わせ形式**（一時レポート）で提示し判断を仰ぐ（両インスタンスとも維持。この場合は成果物が複数あり相互に競合するため、Main 側で判断材料を整理する必要がある）

---

## Step 8: Validation（検証）

**目的:** 成功基準の達成を**観測可能な形**で確認する

**起動する Specialist:** `validator` × 1

**Main の作業:**

1. `validator` に以下を渡して起動:
   - Intent Spec の成功基準
   - 実装済み diff と実行環境情報
   - テスト実行手順（Task Plan に記載されたもの）
2. `validator` に以下を指示:
   - テスト実行（自動テスト一式）
   - メトリクス計測（成功基準が定量的なもの）
   - シナリオ検証（成功基準が定性的なもの）
3. **Validation Report そのものをユーザーに提示**して判定の承認を得る（一時レポートは作成しない）
4. 未達成の成功基準があれば、対応方針を **In-Progress ユーザー問い合わせ形式**（一時レポート）で提示して判断を仰ぐ（ロールバック先の選定はステップ横断の意思決定のため一時レポートが適切）

**Specialist の成果物:**

- `docs/ai-dlc/<identifier>/validation-report.md`
  - 内容: 成功基準 / 観測値 / 判定 / 証拠（ログ / スクリーンショット / メトリクスへのパスや添付）
  - 大きな証拠データは `docs/ai-dlc/<identifier>/validation-evidence/` 配下にサブディレクトリで保存

**Exit Criteria:**

- Intent Spec の全成功基準が PASS、または明示的に保留理由付きで記録されている
- 観測値の**証拠（ログ / スクリーンショット / メトリクス）**が残されている
- `validation-report.md` + `validation-evidence/*`（該当あれば）+ `progress.yaml` がコミット済み
- コミット後、**次ステップ着手時に一時ファイル以外の差分がない状態**

**Gate:** ユーザー承認必須

**失敗時の挙動:**

- 成功基準未達 → 原因に応じてロールバック先を決定（Step 8 を抜ける時点で `validator` の役割終了。戻り先のステップ再活性化時は新規 Specialist を起動）:
  - 実装バグ → Construction Step 5
  - 設計ミス → Inception Step 3
  - 成功基準の設定自体が不適切 → Inception Step 1
- 検証手段が成功基準に対して不適切 → **既存の `validator` インスタンス**に計測手段を変更する指示を差し戻す（Step 8 完了まで同一インスタンスを維持）
- 検証スコープが拡大した → **追加の `validator` を並列起動**も可（既存は維持）

**注意:**

- `validator` は `reviewer` / `implementer` とは**別個の新規インスタンス**として起動（ステップを跨いだ使い回し禁止）
- Step 8 活性化期間中は `validator` の終了禁止。差し戻しまたは追加起動で対応
- Validation は「主観的な OK / NG 判断」ではなく「客観的な観測値との比較」であることを Main が Specialist 指示に含める

---

## Step 9: Retrospective（振り返り）

**目的:** 今サイクルの学びを次サイクルに残す

**起動する Specialist:** `retrospective-writer` × 1

**Main の作業:**

1. `retrospective-writer` に以下を渡して起動:
   - 全フェーズの進捗記録
   - 全成果物（Intent Spec / Research Notes / Design Document / Task Plan / diff / 各種 Report / サイクル中に起票したプロジェクト横断 ADR があれば）
   - Blocker 履歴（発生したもの、どう解決したか）
   - ループ回数（Implementation ↔ Self-Review の往復、External Review の差し戻し回数）
   - ユーザー承認ゲートでのやり取り（承認 / 却下の経緯）
2. 生成された Retrospective Note をユーザーに提示
3. 次サイクルで参照可能な形式でリポジトリに保存

**Specialist の成果物:**

- `docs/ai-dlc/<identifier>/retrospective.md`
  - 良かった点（うまく機能したパターン）
  - 課題（ループ回数が多かった箇所、Blocker の根本原因）
  - 次回改善案（プロセス改善、スキル改善、Specialist プロンプト改善）
  - 再利用可能な知見（他プロジェクトでも有効そうな学び）

**Exit Criteria:**

- `retrospective.md` + `progress.yaml`（`phase: Completed` に更新）がコミット済み（サイクル最終コミット）
- 次サイクル開始時に参照可能な場所・名称になっている
- コミット後、**ワークフロー完了時点でワーキングツリーにサイクル関連の差分がない状態**

**Gate:** Main 判定（ユーザーには情報共有のみ）

**失敗時の挙動:**

- 振り返り内容が抽象的すぎる → **既存の `retrospective-writer` インスタンス**に具体的エピソードを指示して再生成（Step 9 完了まで同一インスタンスを維持）
- 次回改善案が実行不可能 → **既存インスタンス**にアクション粒度まで分解するよう指示して再生成

---

## フェーズ完了判定

ワークフロー全体の完了をユーザーに報告する前に、Main は以下を確認する。

- [ ] `docs/ai-dlc/<identifier>/review/*.md`（全観点）に Blocker 指摘がなくコミット済み
- [ ] `docs/ai-dlc/<identifier>/validation-report.md` で全成功基準が PASS または明示的保留
- [ ] `docs/ai-dlc/<identifier>/retrospective.md` がコミット済み
- [ ] `progress.yaml` の `artifacts` に全成果物パスがリストアップ、`phase: Completed` に更新してコミット
- [ ] サイクル中に作成された In-Progress ユーザー問い合わせ用の一時レポート（`$TMPDIR` 配下）は削除せず残す（Retrospective の題材として参照可能。ただし**コミットはしない**）

完了後、Main はユーザーに**最終完了を成果物ベースで報告**する。
具体的には、`docs/ai-dlc/<identifier>/retrospective.md` / `validation-report.md` / `review/*.md` のパスを提示し、各成果物の要点を口頭で補足する。
一時レポートは作成しない（最終完了時点では判断すべき未解決事項はなく、成果物が完成しているため、成果物そのものが報告材料となる）。

---

## 並列起動のガイドライン（Verification 固有）

| ステップ        | 並列起動推奨度 | 並列軸                                    |
| --------------- | -------------- | ----------------------------------------- |
| External Review | 高             | レビュー観点ごと（セキュリティ / 性能等） |
| Validation      | 低             | 成功基準の統一判定が必要なので 1 名       |
| Retrospective   | 低             | 全体俯瞰が必要なので 1 名                 |

---

## このスキルが扱わないこと

- ワークフロー全体の管理 → `main-workflow` スキル
- 意図明確化・設計・タスク分解 → `main-inception` スキル
- 実装・自己レビュー → `main-construction` スキル
- 各 Specialist の作業詳細 → `specialist-*` スキル（`specialist-common` + 役割別）
- 個別のレビュー観点の技術詳細 → プロジェクト固有のレビュー方針ドキュメント
- リリース・デプロイ作業 → ワークフロー完了後の別プロセス
