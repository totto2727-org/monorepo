# QA Flow: dev-workflow への Draft PR / PR 概要更新 / バックグラウンド CI 連携の統合

- **Identifier:** 2026-05-03-pr-ci-integration
- **Author:** qa-analyst (Step 4 専任、単一インスタンス)
- **Source:** `docs/workflow/2026-05-03-pr-ci-integration/qa-design.md`
- **Created at:** 2026-05-03
- **Last updated:** 2026-05-03
- **Status:** draft

このドキュメントは `qa-design.md` のテストケースを **Mermaid flowchart で可視化**した網羅性確認用の図集。テストの分岐構造をレビュアーが俯瞰できる形で図示することで、認知負荷を下げる。書き方の詳細は `plugins/dev-workflow/skills/shared-artifacts/references/qa-flow.md` を参照。

## 概要

本サイクルの本質ロジックは「ドキュメント改修の静的検証」と「PR / CI ライフサイクルの動的検証」の 2 系統に大別される。前者は SKILL.md 群の grep ベース、後者は本サイクル PR (#95 想定) の状態遷移ベース。

セクション分割:

1. **SKILL.md 改修の静的検証** — SC-1〜SC-4 を 1 つの flowchart に集約 (改修対象ファイル選択 → 観測点 → TC)
2. **Draft PR 作成フロー** — SC-5 を「既存 PR あり / なし / 既に Ready / 既に Draft」の 4 分岐で検証
3. **PR 概要更新フロー** — SC-6 を「ステップ完了時 / 適宜更新時」の 2 分岐で検証
4. **CI 確認 + リトライフロー** — SC-7 を「PASS / 1 回目 FAIL / 2 回目 FAIL / 3 回目 FAIL = Blocker 化」の境界値分岐で検証
5. **Ready 化フロー** — SC-8 を「`isDraft: true` / `false` (no-op)」の 2 分岐で検証
6. **横断的処理 (補助構造の前提検証)** — `(なし)` 系 TC (TC-009 / TC-010 / TC-011 / TC-022) を集約

実装都合分岐 (TC-IMPL-NNN) セクションは Step 4 では空とする (Step 6 で必要に応じて追加)。

---

## SKILL.md 改修の静的検証

このセクションがカバーする成功基準: SC-1, SC-2, SC-3, SC-4

```mermaid
flowchart TD
  Start([Step 8 Validator: SKILL.md 改修検証 開始]) --> Target{改修対象ファイル}
  Target -->|dev-workflow/SKILL.md| DW{検証観点}
  DW -->|Draft PR 言及| Q1{1 件以上ヒット?}
  Q1 -->|true| TC1[TC-001: Draft PR grep が 1+]
  Q1 -->|false| Fail1[Fail: SC-1 未充足]
  TC1 --> Q2{initialize cycle 文言?}
  Q2 -->|true 同一文脈| TC2[TC-002: initialize cycle と Draft PR 隣接]
  Q2 -->|false| Fail2[Fail: SC-1 未充足]
  DW -->|PR 概要言及| Q3{2 件以上ヒット?}
  Q3 -->|true| TC3[TC-003: PR 概要 grep が 2+]
  Q3 -->|false| Fail3[Fail: SC-2 未充足]
  TC3 --> Q4{両タイミング表現?}
  Q4 -->|完了時 AND 適宜| TC4[TC-004: 各ステップ完了時 + 適宜]
  Q4 -->|片方のみ| Fail4[Fail: SC-2 未充足]
  DW -->|CI 言及| Q5{3 件以上ヒット?}
  Q5 -->|true| TC5[TC-005: CI grep が 3+]
  Q5 -->|false| Fail5[Fail: SC-3 未充足]
  DW -->|リトライ言及| Q6{1 件以上ヒット?}
  Q6 -->|true| TC6[TC-006: リトライ/2 回 grep が 1+]
  Q6 -->|false| Fail6[Fail: SC-3 未充足]
  TC6 --> Q7{Blocker と接続?}
  Q7 -->|新セクション内で接続| TC7[TC-007: 同一セクションで Blocker 接続]
  Q7 -->|別セクションに分散| Fail7[Fail: SC-3 接続文中明示違反]
  DW -->|Step 9 内 Ready 化| Q8{1 件以上ヒット?}
  Q8 -->|true| TC8[TC-008: Step 9 内 Ready 化 grep が 1+]
  Q8 -->|false| Fail8[Fail: SC-4 未充足]
```

---

## Draft PR 作成フロー

このセクションがカバーする成功基準: SC-5

```mermaid
flowchart TD
  Start([Step 1 完了: initialize cycle commit + push]) --> Q1{既存 PR 状態}
  Q1 -->|未作成| Create[gh pr create --draft 実行]
  Q1 -->|既存 open かつ Draft| Reuse[既存 PR 再利用]
  Q1 -->|既存 open かつ Ready| Skip1[skip: 想定外ケース・本サイクル開始時点では発生しない]
  Q1 -->|既存 closed| Skip2[skip: 想定外ケース・サイクルブランチ新設前提のため発生しない]
  Create --> Verify{作成後の状態確認}
  Reuse --> Verify
  Verify -->|isDraft: true| TC12[TC-012: PR 作成時点で Draft]
  Verify -->|isDraft: false| Fail12[Fail: SC-5 未充足 ・Draft で作成されていない]
  TC12 --> Q2{含まれるコミット}
  Q2 -->|initialize cycle 含む| TC13[TC-013: initialize cycle commit が PR に含まれる]
  Q2 -->|含まれない| Fail13[Fail: SC-5 未充足]
  TC13 --> Q3{PR 本文構造}
  Q3 -->|Summary + Cycle artefacts + Progress checklist 全て含む| TC14[TC-014: PR 本文に必須見出し 3 つ]
  Q3 -->|一部欠如| Fail14[Fail: SC-5 部分未充足]
```

---

## PR 概要更新フロー

このセクションがカバーする成功基準: SC-6

```mermaid
flowchart TD
  Start([Step 1〜N 進行中]) --> Q1{description 更新トリガー}
  Q1 -->|ステップ完了時| Edit1["Main: TMPDIR の id-pr-body.md 再生成 → gh pr edit --body-file"]
  Q1 -->|適宜・内容変化時| Edit2[Main: 同上の手順で随時更新]
  Q1 -->|更新不要| Skip1[skip: 直近で description 変化を要する事象なし]
  Edit1 --> Timeline[GitHub timeline に編集イベント記録]
  Edit2 --> Timeline
  Timeline --> Q2{Step 8 検証時点での更新回数}
  Q2 -->|2 件以上| TC15[TC-015: description が複数回更新]
  Q2 -->|1 件 = 初期作成のみ| Fail15[Fail: SC-6 未充足]
  TC15 --> Q3{各 Step 完了との時系列整合}
  Q3 -->|全実施済み Step に紐付く更新あり| TC16[TC-016: Step 完了 → description 更新が時系列整合]
  Q3 -->|一部 Step で更新欠落| Fail16[Fail: SC-6 部分未充足]
```

---

## CI 確認 + リトライフロー

このセクションがカバーする成功基準: SC-7

```mermaid
flowchart TD
  Start([各 Step 完了 commit + push]) --> Watch[gh run watch RUN_ID --exit-status]
  Watch --> Q1{1 回目 conclusion}
  Q1 -->|success| TC17a[TC-017: 該当 SHA で最新 attempt success]
  Q1 -->|failure| Retry1[Main: 修正 → 新規 commit → push - ATTEMPT=1]
  Retry1 --> Watch2[再度 gh run watch]
  Watch2 --> Q2{2 回目 conclusion}
  Q2 -->|success| TC17b[TC-017: リトライ後最終 success]
  Q2 -->|failure| Retry2[Main: 修正 → 新規 commit → push - ATTEMPT=2]
  Retry2 --> Watch3[再度 gh run watch]
  Watch3 --> Q3{3 回目 conclusion}
  Q3 -->|success| TC17c[TC-017: 2 回リトライ後最終 success]
  Q3 -->|failure| Blocker[Blocker 化: progress.yaml.blockers 追記 + In-Progress 問い合わせ]
  TC17a --> Q4{リトライ回数集計}
  TC17b --> Q4
  TC17c --> Q4
  Q4 -->|0〜2 回| TC18[TC-018: リトライ 2 回以下]
  Q4 -->|3 回以上| Fail18[Fail: SC-7 規律違反]
  Blocker --> Q5{progress.yaml.blockers 記録}
  Q5 -->|該当エントリあり| TC19[TC-019: Blocker 記録あり]
  Q5 -->|エントリなし| Fail19[Fail: SC-7 記録欠落]
  Q5 -->|本サイクルで Blocker 化発生せず| Skip19[skip: TC-019 該当ケースなし - Blocker 未発生]
```

---

## Ready 化フロー

このセクションがカバーする成功基準: SC-8

```mermaid
flowchart TD
  Start([Step 9 retrospective.md commit + push]) --> View[gh pr view num --json isDraft]
  View --> Q1{現在の isDraft}
  Q1 -->|true| Ready[gh pr ready num 実行]
  Q1 -->|false| NoOp[no-op: 既に Ready - 冪等スキップ]
  Ready --> Verify{Ready 化後の確認}
  NoOp --> Skip1[skip: 想定外ケース・Step 9 完了前に Ready 化されていた]
  Verify -->|isDraft: false| TC20[TC-020: PR が Ready 状態]
  Verify -->|isDraft: true 失敗| Fail20[Fail: SC-8 未充足]
  TC20 --> Q2{ready_for_review event の created_at}
  Q2 -->|Step 9 commit 時刻以降| TC21[TC-021: Ready 化が Step 9 以降]
  Q2 -->|Step 9 commit 時刻より前| Fail21[Fail: SC-8 タイミング違反]
```

---

## 横断的処理 (補助構造の前提検証)

このセクションがカバーする成功基準: (なし) — 設計上必要な前提条件 / リグレッション防止 / 冪等性ガード

design.md で実施が確定している補助改修と冪等性ガードを観測する。SC に対応しないため独立セクションとして集約する。

```mermaid
flowchart TD
  Start([Step 8 Validator: 補助構造検証 開始]) --> Branch{検証対象}
  Branch -->|既存 SKILL.md 主要見出し| Q1{3 つの主要見出しが存続?}
  Q1 -->|true| TC9[TC-009: 既存セクション破壊なし]
  Q1 -->|false| Fail9[Fail: 既存セクション誤削除]
  Branch -->|specialist-common §7 PR Main 専属| Q2{1 行追記あり?}
  Q2 -->|true| TC10[TC-010: PR 操作 = Main 専属の追記]
  Q2 -->|false| Fail10[Fail: design.md 代替案 5 案 A 未実施]
  Branch -->|progress-yaml.md blockers CI 例| Q3{CI failure 例の追記?}
  Q3 -->|true 1 件以上| TC11[TC-011: CI failure 例追記]
  Q3 -->|false| Skip11[skip: design.md L92 で 任意・推奨 のため未追記でもサイクル成功は崩れない]
  Branch -->|Ready 化冪等性ガード| Q4{SKILL.md 内に if isDraft true 分岐あり?}
  Q4 -->|true 静的に確認| TC22[TC-022: 冪等性ガードが擬似コード内に存在]
  Q4 -->|false| Fail22[Fail: 冪等性ガード欠落 - gh-cli.md F-2 リスク残存]
```

---

## 実装都合分岐 (任意)

既存セクションの flowchart に組み込めない `TC-IMPL-NNN` をここに集約する。Step 6 で implementer が発見した分岐のうち、独立性が高く既存図に自然に入らないものを追記する。**Step 4 時点では空。**

```mermaid
flowchart TD
  Start([Step 6 implementer が発見した実装都合分岐があればここに追記]) --> Skip[skip: Step 4 時点では実装都合分岐なし]
```
