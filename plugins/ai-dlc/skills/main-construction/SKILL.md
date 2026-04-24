---
name: main-construction
description: >
  [Main 用] AI-DLC Phase 2 (Construction) の詳細実行手順を定義する。
  実装・自己レビューの 2 ステップを Specialist 起動仕様付きで提供する。
  Task Plan に従って並列実装を行い、外部レビュー前に自己レビューで明らかな問題を潰す。
  起動トリガー: "Construction フェーズを開始", "実装フェーズ", "実装を進める",
  "自己レビュー", "ai-dlc の construction"。
  Do NOT use for: ai-dlc ワークフロー全体の管理（main-workflow スキルを使う）、
  意図明確化・設計・タスク分解（main-inception スキルを使う）、
  外部レビュー・検証（main-verification スキルを使う）、
  Specialist 側の作業詳細（specialist-* スキルを使う）、Task Plan がない状態での実装開始。
---

# AI-DLC Phase 2 — Construction

ユースケースカテゴリ: **Workflow Automation**
設計パターン: **Sequential Workflow** + **Iterative Refinement**（Step 5 で並列実装、Step 6 で検査→必要なら 5 へループバック）

Construction フェーズは、Inception で承認された `Task Plan` に従ってコードを実装し、外部レビュー前に自己レビューで明らかな問題を潰す。
出力は**型チェック・リント・既存テストを通過した diff 群**と `Self-Review Report` で、これが Verification フェーズの入力となる。

**このスキルは `main-workflow` スキル配下で使用される。** `main-workflow` の基本方針・役割定義・調整プロトコル・ユーザー承認ゲート規則（Artifact-as-Gate-Review / Report-Based Confirmation for In-Progress Questions の区別）をすべて継承する。各 Specialist の作業詳細は `specialist-*` スキルに定義されている。

## フェーズ全体

| 項目         | 内容                                                                                                           |
| ------------ | -------------------------------------------------------------------------------------------------------------- |
| 入力         | `docs/ai-dlc/<identifier>/task-plan.md` / `design.md` / `intent-spec.md` / Research Notes                       |
| 成果物       | タスクごとの Git コミット（diff）/ `docs/ai-dlc/<identifier>/TODO.md` / `docs/ai-dlc/<identifier>/self-review-report.md` |
| 保存先       | diff は通常の Git 履歴、自己レビューは `docs/ai-dlc/<identifier>/` 配下                                        |
| 出口ゲート   | Main 判定（High 指摘 0 件、設計ドキュメント整合性確認、成功基準を満たす見込みあり）                             |
| 想定ステップ | 5. Implementation → 6. Self-Review（High 指摘あれば Step 5 へループバック）                                    |
| ロールバック | High 指摘があれば Step 5 へ。設計ドキュメントとの整合性が崩れていれば Inception Step 3 へ戻り `design.md` 修正 |

**コミット方針:** 実装 diff はタスクごと・コミット単位で分割。`self-review-report.md` と `progress.yaml` は別コミットで追加（詳細は `main-workflow` スキルの「成果物保存構造」参照）。

**対応エージェント・スキル・成果物:**

| Step                     | Agent                    | Specialist Skill               | 成果物（書き方 / テンプレート）                                                                                       |
| ------------------------ | ------------------------ | ------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| 5. Implementation        | `implementer` (並列 N)   | `specialist-implementer`       | `shared-artifacts/references/implementation-log.md` / `shared-artifacts/templates/implementation-log.md`             |
| 6. Self-Review           | `self-reviewer`          | `specialist-self-reviewer`     | `shared-artifacts/references/self-review-report.md` / `shared-artifacts/templates/self-review-report.md`             |

**Main 維持成果物（Construction 開始時に生成）:**

- `TODO.md` → 書き方: `shared-artifacts/references/todo.md` / テンプレート: `shared-artifacts/templates/TODO.md`
  - Main が `task-plan.md` から生成するタスク状態の永続層

Specialist 起動時には **reference（書き方ガイド）とテンプレートの両方のパス**を入力に含めること。各 Specialist は `specialist-common`（横断ルール）と上記の個別スキルを参照する。

---

## フェーズ開始前チェック

Inception の成果物が揃っていることを Main が確認する。

- [ ] `docs/ai-dlc/<identifier>/task-plan.md` が存在しユーザー承認済み
- [ ] `docs/ai-dlc/<identifier>/design.md` が確定済み・ユーザー承認済み
- [ ] `Intent Spec` の成功基準が観測可能な形式で確定している

いずれか欠けていれば Construction に入らず `main-inception` スキルへ戻る。

---

## Construction 開始時: タスクリスト反映（Step 5 起動前の必須手順）

`planner` が Inception Step 4 で生成した `task-plan.md` は**不変な計画書**として保持し、Construction 内で追跡するタスク状態は **2 箇所**に反映する。

### 1. Main の内部タスクリスト（セッション内トラッキング）

Main は `TaskCreate` を使って Construction 内のタスクをすべてエージェント内部のタスクリストに登録する。これによりセッション内の進捗可視化とツール連携が有効になる。

**反映手順:**

1. `task-plan.md` を全タスク読み込む
2. 各タスク（T1, T2, ..., TN）を `TaskCreate` で登録
3. タスク状態は `TaskUpdate` で更新（`pending` → `in_progress` → `completed`）
4. 並列起動中のタスクは全て `in_progress` として保持

### 2. 永続化タスクリスト `TODO.md`（作業引き継ぎ用）

セッション内部のタスクリストは揮発性のため、**作業引き継ぎ・中断再開のために `docs/ai-dlc/<identifier>/TODO.md` に永続化**する。Construction 開始時に `task-plan.md` から生成し、タスク完了のたびに更新・コミットする。

**フォーマットと運用ルールの真のソース:** `shared-artifacts/references/todo.md`（書き方）+ `shared-artifacts/templates/TODO.md`（雛形）。main-construction では運用フロー（どのステップでどう反映するか）のみを定義する。

**Construction における運用フロー:**

- Construction 開始時: `task-plan.md` から TODO.md を生成（全タスク `status: pending`）してコミット
- `implementer` 起動時: 該当タスクを `in_progress` に更新、`started_at` と `implementer` を記録してコミット
- タスク完了時: `[x]` に変更、`completed_at`、`commit` SHA を記録してコミット
- タスク再活性化時（Self-Review High 指摘で Step 5 に戻った場合等）: `in_progress` に戻し、`re_activations` カウンタをインクリメントしてコミット

具体的なフィールドスキーマ・状態遷移ガイド・TaskCreate 同期ルールは `shared-artifacts/references/todo.md` を参照。

**コミット単位:**

- TODO.md は各タスク状態変化ごとにコミット（頻繁、タスク単位）
- コミットメッセージ例: `docs(ai-dlc/<identifier>): complete task T1`
- 進捗が細かくコミットされることで、中断後の復旧精度が上がる

### 3. TaskCreate と TODO.md の同期

**原則:** TODO.md が真のソース（永続層）、TaskCreate はそのビュー（揮発層）。状態変化時は TODO.md → コミット → TaskUpdate の順で進める。

詳細な同期ルール・セッション再開時の復元手順は `shared-artifacts/references/todo.md` を参照。

---

## Step 5: Implementation（実装）

**目的:** Task Plan に従ってコードを実装する

**起動する Specialist:** `implementer` × N（タスクごと、並列可）

**前提:** Construction 開始時に `TODO.md` と内部タスクリスト（TaskCreate）が `task-plan.md` から反映されていること（詳細は前述「Construction 開始時: タスクリスト反映」）。

**Main の作業:**

1. `TODO.md` から **並列起動可能なタスク群**を抽出（依存グラフの起点 / 独立タスク、`status: pending` のもの）
2. 起動予定の各タスクについて `TODO.md` と TaskCreate の状態を `in_progress` に更新してコミット
3. 独立タスクは `implementer` を **並列起動**（各 Specialist に 1 タスクのみ割り当て、`implementer` ID を TODO.md に記録）
4. 依存タスクは前段タスクの完了後に逐次起動
5. 各 `implementer` の diff と動作確認結果を集約
6. **タスク完了ごとに TODO.md を更新**（`[x]` チェック、`completed_at`、`commit` SHA 記録）→ コミット → TaskUpdate で `completed` に
7. 型チェック・リント・既存テスト実行を Main が指示（Specialist 側の責任範囲として明示）
8. Exit Criteria を判定し、全タスク完了（TODO.md 内の全タスクが `[x]`）を確認

**Specialist への入力仕様（必須項目）:**

- 担当タスク ID と Task Plan 該当部分の抜粋
- `design.md` のうち関連箇所
- Intent Spec（スコープ / 非スコープ）
- 成果物保存先（ブランチ / ファイル）
- テスト追加方針

**Specialist の成果物:**

- タスクごとの diff（通常の Git コミット、コミット単位で分割）
- 動作確認ログ（テスト実行結果、手動確認結果） — `progress.yaml` の該当 specialist エントリ に要約を記録、長大な場合は `docs/ai-dlc/<identifier>/implementation-logs/<task-id>.md` に保存してリンク

**Exit Criteria:**

- `TODO.md` 内の全タスクが `[x] completed` 状態
- 型チェック・リント・既存テストが通過
- 新規テストが該当タスクに追加されている（テスト不要と判断した場合は理由を記録）
- 各 diff が `design.md` の設計判断に従っている
- **タスクごとに分割された全コミット**がリポジトリに存在する（Implementation は 1 ステップ = 複数コミット、タスク単位）
- `TODO.md` + `progress.yaml` が最終状態で反映・コミット済み
- コミット後、**Step 6 着手時に一時ファイル以外の差分がない状態**

**Gate:** Main 判定

**失敗時の挙動:**

- 特定タスクの `implementer` が期待外の成果物を返した → **当該タスクを担当する `implementer` インスタンス**に指摘を差し戻して再試行（Step 5 完了まで同一インスタンスを維持、終了させない）。TODO.md の状態は `in_progress` のまま保持
- タスク数が不足していたと判明 → `implementer` を**追加並列起動**（既存インスタンスは維持）。新規タスクを TODO.md に追記し、`task-plan.md` も対応する変更があれば追記（ただし `task-plan.md` は不変運用のため、**新規タスクは TODO.md 側に追加し「後発タスク」として明示**。差分の理由を TODO.md 冒頭に記録）
- タスク定義自体が不適切 → Inception Step 4 にロールバック（Step 5 を抜ける時点で全 `implementer` の役割終了。再入後は新規 `implementer` を起動）。ロールバック後に再生成された `task-plan.md` から TODO.md を**再構築**（既存 TODO.md は `TODO.md.pre-rollback-<timestamp>` にリネームして履歴保持）
- `design.md` との整合性が崩れる判断が必要な場合 → 一時停止し、Inception Step 3 に戻るかを Main が判断

**並列実行の注意:**

- 並列 `implementer` 同士が同一ファイルを編集する場合、Task Plan の依存グラフで直列化されているはず。違反があれば Main が直列化し直す
- Git ブランチ戦略: タスクごとに feature branch を切るか、依存順で同一ブランチに逐次積むかを Main が決定（Task Plan の並列性に従う）
- 並列 `implementer` のうち特定インスタンスだけを終了させてはならない（Step 完了前は全員維持）。不要になっても Step 完了までは待機状態とする

---

## Step 6: Self-Review（自己レビュー）

**目的:** 外部レビュー前に明らかな問題を潰し、手戻りコストを下げる

**起動する Specialist:** `self-reviewer` × 1

**Main の作業:**

1. `self-reviewer` を起動し、以下を渡す:
   - 全 diff（Step 5 で生成されたもの）
   - `design.md`
   - Intent Spec（成功基準の確認用）
   - Task Plan（完了判定用）
2. 指摘事項を受け取り、深刻度別（High / Medium / Low）に整理
3. **High 指摘があれば Step 5 を再活性化**: 該当タスクを TODO.md で `[x]` → `[ ]` に戻し `status: in_progress`、`re_activations` カウンタをインクリメントしてコミット。前回の `implementer` は Step 5 完了時に役割終了済みのため、該当タスク担当の `implementer` を新規起動して修正させる
4. Medium / Low 指摘は Self-Review Report に記録し、Verification フェーズの判断材料とする
5. 最終的に High 0 件を確認して Exit Criteria を判定（Step 6 の `self-reviewer` は Exit Criteria 確定まで維持）

**Specialist の成果物:**

- `docs/ai-dlc/<identifier>/self-review-report.md`
  - 内容: 指摘 / 深刻度 / 該当 diff（コミット SHA + ファイル行番号）/ 推奨アクション

**Exit Criteria:**

- 深刻度 High の指摘が 0 件、または全て修正済み
- `design.md` との整合性が確認済み
- Intent Spec の成功基準を満たす見込みがある
- `self-review-report.md` + `progress.yaml` がコミット済み（1 ステップ = 1 コミット）
- コミット後、**次ステップ着手時に一時ファイル以外の差分がない状態**

**Gate:** Main 判定。High 指摘残があれば Step 5 に戻る（Verification へは進めない）

**失敗時の挙動:**

- High 指摘が繰り返し発生 → 設計レベルの問題の可能性。Inception Step 3（Design）への回帰を **In-Progress ユーザー問い合わせ形式**（一時レポート）で相談
- `self-reviewer` の指摘が実装者と矛盾 → **セカンドオピニオン用に `self-reviewer` を追加起動**（並列化）。既存の `self-reviewer` は終了させず維持し、両者の指摘を Main が突き合わせる
- `self-reviewer` の個別指摘に曖昧さがある → **既存の `self-reviewer` インスタンス**に詳細化を指示（差し戻し）

**注意:**

- `self-reviewer` は `implementer` と**異なる新規インスタンス**として起動する（Specialist はステップを跨いで使い回さない原則。Step 5 と Step 6 は別ステップ）
- Step 6 の `self-reviewer` は Step 6 の Exit Criteria が確定するまで維持する（Step 5 への差し戻し中も Step 6 を抜けきっていない場合は維持）
- ただし「自己レビュー」という呼称は「実装したエージェントチーム内のレビュー」の意。外部観点のレビューは Verification Step 7 で行う

---

## Implementation ↔ Self-Review ループ

High 指摘があった場合のループ構造を以下に定義する。Step 5 と Step 6 は別ステップなので、ステップを跨ぐ Specialist 再利用は行わないが、**各ステップの活性化期間中はインスタンスを維持**する。

```
[Step 5 活性化] implementer A1..AN (並列 N)
    ↓ Exit Criteria 満たす
[Step 5 完了] implementer A1..AN 役割終了
    ↓
[Step 6 活性化] self-reviewer B1 起動
    ↓
    B1 が指摘を生成 ─────┐
    │                     │
    (High 0)        High 指摘あり
    │                     │
Phase 出口へ    [Step 5 再活性化]
                 新規 implementer C1..Ck を
                 該当タスクのみに割り当て
                 （B1 は Step 6 継続のため維持）
                 C1..Ck が修正 diff を返却
                     ↓
                 [Step 5 再び完了] C1..Ck 役割終了
                     ↓
                 既存 B1 が再レビュー（差し戻し）
                     ↓
                 High 0 確認 → Phase 出口へ
                 （B1 はここで役割終了）
```

**ポイント:**

- 各ステップの活性化期間中は同一 Specialist を維持（ステップ完了時に役割終了）
- Step 6 の `self-reviewer` B1 は、Step 5 再活性化中も Step 6 を抜けきっていないため存続する（Step 5 の新規 implementer C1..Ck と共存）
- Step 5 を再活性化する際は新規 `implementer` を起動（前回の A1..AN は Step 5 完了時に役割終了済み）
- B1 への再レビュー依頼は既存インスタンスへの差し戻しで行う（新規 `self-reviewer` を起動しない）

**ループ上限の目安:**

- 同一 Self-Review Report の High 指摘で 3 周以上ループする場合、設計レベルの問題を疑い Inception Step 3 へロールバックを検討
- ループのたびに進捗記録へ回数と原因を記録する

---

## フェーズ出口チェックリスト

Verification フェーズへ遷移する前に、Main は以下を確認する。

- [ ] 全 diff が Git コミット済み・レビュー可能な状態
- [ ] 型チェック・リント・既存テスト・新規テストが全て通過
- [ ] `docs/ai-dlc/<identifier>/TODO.md` の全タスクが `[x] completed` 状態でコミット済み
- [ ] 内部タスクリスト（TaskCreate）と TODO.md に齟齬がない
- [ ] `docs/ai-dlc/<identifier>/self-review-report.md` に High 指摘がなくコミット済み
- [ ] `design.md` の設計判断に違反する実装がない
- [ ] Intent Spec の成功基準を満たす見込みが立っている（実測は Verification Step 8 で）
- [ ] `progress.yaml` の `phase` を Verification に更新してコミット

全項目チェック後、`main-verification` スキルへ移行する。

---

## 並列起動のガイドライン（Construction 固有）

| ステップ       | 並列起動推奨度 | 並列軸                                |
| -------------- | -------------- | ------------------------------------- |
| Implementation | 高             | Task Plan の独立タスクごと            |
| Self-Review    | 低             | 全体整合性が必要なので原則 1 名       |

---

## このスキルが扱わないこと

- ワークフロー全体の管理 → `main-workflow` スキル
- 意図明確化・設計・タスク分解 → `main-inception` スキル
- 外部レビュー・検証・振り返り → `main-verification` スキル
- 各 Specialist の作業詳細 → `specialist-*` スキル（`specialist-common` + 役割別）
- 個別の実装技術・言語仕様 → プロジェクト固有スキル（`effect-layer` 等）
- Git コミット規約 → プロジェクト固有スキル（`git-workflow` 等）
