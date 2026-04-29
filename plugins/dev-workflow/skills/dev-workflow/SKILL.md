---
name: dev-workflow
description: >
  [Main 用] マルチエージェント前提の開発ワークフロー全体を管理するルール集。
  Main が進捗管理とエージェント起動を兼ね、Step 1 (Intent Clarification) から
  Step 9 (Retrospective) までフラットな 10 ステップを順次実行する。
  各 Specialist の作業詳細は specialist-* スキルに、成果物仕様は shared-artifacts
  スキルに委譲する。
  起動トリガー: "開発ワークフローを開始", "新機能を dev-workflow で進める",
  "意図から実装まで通したい", "dev-workflow で設計から実装まで"。
  Do NOT use for: 単発のコード修正、特定 Specialist のみの直接利用
  (specialist-* スキルを参照)、成果物仕様の参照のみ (shared-artifacts スキル)。
metadata:
  author: totto2727
  version: 2.0.0
---

# dev-workflow — Multi-Agent Development Workflow

ユースケースカテゴリ: **Workflow Automation**
設計パターン: **Sequential Workflow** + **Multi-Service Coordination** (ゲート付き順次実行 + Main / Specialist 2 層調整)

このスキルはマルチエージェント前提の開発ワークフロー全体を司る。人間との対話・進捗管理・エージェント起動を担う **Main** と、各ステップを実行する **Specialist** の 2 層構成で、10 ステップをゲート式で進行させる。各 Specialist の作業詳細・成果物仕様は個別スキルに委譲する。

## 基本方針

- **Main-Centric Orchestration**: Main が人間との対話・進捗管理・Specialist 起動・ゲート判定を全て担う。Specialist はステップ実行のみに専念する
- **Single-Source-of-Progress**: ワークフローの進捗は Main が唯一の真実として保持する。Specialist は自分で次のステップを決めない
- **One-Shot Specialist & Within-Step Persistence**: 各 Specialist は **1 ステップ限定**でステップを跨いで使い回さない。一方、**同一ステップ内では原則として同じ Specialist インスタンスを維持**する
  - ステップ完了までの間、Specialist の**終了 (kill / replace) は禁止**。期待外の成果物が返っても、既存 Specialist にフィードバックを差し戻して再試行させる
  - ステップ完了までの間、Specialist の**追加**は容認される (スコープ拡大・観点追加・並列タスク追加のため)
  - ステップの Exit Criteria が満たされ次ステップへ進む時点で Specialist の役割は終了する
- **Gate-Based Progression**: 各ステップには明確な完了基準 (Exit Criteria) があり、それを満たさない限り次ステップに進まない
- **Artifact-Driven Handoff**: ステップ間の受け渡しは人間が読める成果物 (ドキュメント、設計書、計画書、diff) で行う。口伝や暗黙知に頼らない
- **Project-Rule Precedence for Details**: 本ワークフローは**プロセス全体の構造** (ステップ・成果物形式・ゲート判定) を提供するが、**実装パターン・テストルール・コミット/ブランチ規約・設計規約・コードレビュー観点・命名規則**など**具体的な作業内容**はプロジェクト固有のルール・スキル (`effect-layer` / `git-workflow` / プロジェクト CLAUDE.md 等) を優先する。両者が矛盾する場合は独断で解決せず、**In-Progress ユーザー問い合わせ形式でユーザーに判断を仰ぐ** (詳細は後述「プロジェクト固有ルールとの関係」参照)
- **Commit-Based Resumability**: サイクルの成果物と進捗記録は `docs/dev-workflow/<identifier>/` に集約し、**各ステップ完了時に必ずコミット**する。これにより別セッション/別ユーザーがコミットを取得して作業を再開できる (詳細は後述「ステップ完了時のコミット規約」参照)
- **Clean-Transition Between Steps**: 次ステップ着手時には、**一時ファイル (`$TMPDIR/dev-workflow/*.md`) 以外は差分がない状態**とする。前ステップで作った成果物は全てコミット済みであること。これにより「ステップ完了の認識ずれ」「中途半端なファイルが次ステップに混入」を防ぐ
- **Artifact-as-Gate-Review**: ステップ末尾の**ユーザー承認ゲートでは、そのステップの成果物そのものをレビュー対象とする** (Intent Spec / Design Document / Task Plan / Review Report / Validation Report 等)。一時レポートは作成しない。成果物こそが承認判断の材料である
  - Main は該当成果物のパスを案内し、要点を口頭で補足する
  - 端的な質問 (「これでいいですか？」) は禁止だが、解消は**成果物の質**で行う (成果物に必要な情報が書かれていれば、それを読めば判断できる)
- **Report-Based Confirmation for In-Progress Questions**: **作業途中でユーザーに判断や情報提供を求める際**は、**必ず詳細な文脈レポートを一時ファイルとして作成**し、それを提示したうえで確認を取る
  - 対象ケース (いずれも成果物が未完成の状態でユーザー判断が必要な場面):
    - Blocker 発生時の方針相談 (前ステップへのロールバック可否、代替案の選定等)
    - スコープ変更の意思確認
    - Specialist 同士の指摘が矛盾し、ユーザー判断が必要な場合
    - ステップ内で複数アプローチが競合し、推奨案を提示して決定を仰ぐ場合
  - 対象外: **ステップ末尾のユーザー承認ゲート** (成果物そのもので代用できるため一時レポート不要)
  - 端的な質問は禁止。ユーザーが文脈を把握できず、適切な判断ができないため
  - レポートは**最終成果物 (設計ドキュメント / 各種レポート / コード) には含めない**。判断のための一時資料
  - 保存先: `$TMPDIR/dev-workflow/step<N>-<purpose>.md` (例: `$TMPDIR/dev-workflow/step5-rollback-query.md`)
  - レポート最小構成: `# 目的` / `# これまでの経緯` / `# 選択肢と根拠` / `# 推奨案` / `# 確認したい事項`
  - ユーザーには「レポートを `<path>` に作成しました。確認のうえ指示してください」と案内し、口頭で要点をかいつまんで提示する

---

## 役割定義

### Main (メインエージェント = オーケストレーター兼務)

**責務:**

- 人間 (ユーザー) との直接対話
- ワークフロー全体の進捗管理 (現在ステップ・ゲート・Blocker)
- 各ステップの Specialist 起動 (入力・期待成果物の指定を含む)
- 各ステップのゲート判定 (Exit Criteria 充足確認)
- ユーザー承認ゲートでのレポート作成と確認取得

**原則:**

- Main は**実装作業を自分で行わない** (対話・判断・割り当てに専念)
  - 例外: ワークフロー開始前の初期確認、Specialist 未起動時の軽微な質問回答、進捗記録の更新
- Specialist 起動時は以下を明示する:
  - 役割 (例: `researcher` / `implementer`)
  - 入力 (Intent Spec, Research Notes, 該当タスク定義など)
  - 期待成果物 (フォーマットと保存先)
  - スコープ境界 (これをやる / これはやらない)
- 進捗状態 (`progress.yaml`) を各ターンで更新し、必要に応じてユーザーに可視化する

### Specialist (専門エージェント)

**責務:**

- 割り当てられた 1 ステップ (または 1 タスク) を完遂する
- 成果物を Main に返却する (次ステップに持ち運び可能な形式)

**原則:**

- Specialist は**自分のスコープ外を触らない** (例: Researcher は実装しない)
- 次ステップを勝手に開始しない (完了報告のみ)
- 1 Specialist = 1 ステップ (ステップを跨いで使い回さない)
- **同一ステップ内では存続を維持する**: ステップ完了まで Main は Specialist を終了させない。期待外の結果が出ても同じ Specialist にフィードバックを差し戻して再試行する
- 同一ステップ内で並列実行可能 (例: 複数観点の調査、複数タスクの並列実装)。ステップ途中での **追加起動も容認** (スコープ拡大時)
- Blocker に遭遇した場合は独断で回避策を取らず、**作業を中断して Main に報告**する

---

## ワークフロー全体図

```
1. Intent Clarification ──┐
                          │ (Gate: ユーザー承認)
2. Research ──────────────┤
                          │ (Gate: Main 判定)
3. Design ────────────────┤
                          │ (Gate: ユーザー承認)
4. QA Design ─────────────┤
                          │ (Gate: ユーザー承認)
5. Task Decomposition ────┤
                          │ (Gate: ユーザー承認 = 実装開始合意)
6. Implementation ────────┤◄─┐
                          │  │ (High 指摘ループ)
7. Self-Review ───────────┤──┘ (Gate: Main 判定)
                          │
8. External Review ───────┤ (Gate: ユーザー承認)
                          │
9. Validation ────────────┤ (Gate: ユーザー承認)
                          │
10. Retrospective ────────┘ (Gate: Main 判定)
                          │
                          ▼ 完了
```

---

## ステップ一覧

| Step | 名称                 | Specialist (起動形態)          | Gate | 主要成果物                                             | 詳細スキル                        |
| ---- | -------------------- | ------------------------------ | ---- | ------------------------------------------------------ | --------------------------------- |
| 1    | Intent Clarification | `intent-analyst` × 1           | User | `intent-spec.md`                                       | `specialist-intent-analyst`       |
| 2    | Research             | `researcher` × N (並列)        | Main | `research/<topic>.md`                                  | `specialist-researcher`           |
| 3    | Design               | `architect` × 1                | User | `design.md` (+ 横断 ADR)                               | `specialist-architect`            |
| 4    | QA Design            | `qa-analyst` × 1               | User | `qa-design.md` + `qa-flow.md`                          | `specialist-qa-analyst`           |
| 5    | Task Decomposition   | `planner` × 1                  | User | `task-plan.md`                                         | `specialist-planner`              |
| 6    | Implementation       | `implementer` × N (タスク並列) | Main | コード diff + `TODO.md` + qa-design.md/qa-flow.md 追記 | `specialist-implementer`          |
| 7    | Self-Review          | `self-reviewer` × 1            | Main | `self-review-report.md`                                | `specialist-self-reviewer`        |
| 8    | External Review      | `reviewer` × N (観点並列)      | User | `review/<aspect>.md`                                   | `specialist-reviewer`             |
| 9    | Validation           | `validator` × 1                | User | `validation-report.md` + `validation-evidence/*`       | `specialist-validator`            |
| 10   | Retrospective        | `retrospective-writer` × 1     | Main | `retrospective.md`                                     | `specialist-retrospective-writer` |

各 Specialist 起動時には **reference (書き方ガイド) とテンプレートの両方のパス**を入力に含めること。各 Specialist は `specialist-common` (横断ルール) と上記の個別スキルを参照する。

---

## ステップ詳細

各ステップの目的・Main の作業・Specialist 起動仕様・Exit Criteria・Gate・失敗時挙動・ロールバック先を定義する。Specialist の内部作業は対応する `specialist-*` スキルに委譲する。

### Step 1: Intent Clarification (意図明確化)

**目的:** ユーザーが本当に解きたい問題を言語化し、スコープ・制約・成功基準を確定する

**起動 Specialist:** `intent-analyst` × 1

**Main の作業:**

1. `intent-analyst` を起動し、初期ユーザー要求と現在のリポジトリ状態の要約を渡す
2. `intent-analyst` の質問を受け取り、ユーザーに提示
3. ユーザー回答を `intent-analyst` に戻し、Intent Spec を確定させる
4. **確定した Intent Spec そのものをユーザーに提示**して承認を得る (一時レポートは作成しない)

**成果物:** `docs/dev-workflow/<identifier>/intent-spec.md` (背景 / 目的 / スコープ / 非スコープ / 成功基準 / 制約)

**Exit Criteria:**

- スコープと非スコープが明文化されている
- 成功基準が観測可能な形式で記述されている (「速くなる」ではなく「p95 < 200ms」等)
- ユーザーが Intent Spec に同意済み
- `intent-spec.md` がコミット済み、`progress.yaml.completed_steps` に追記済み

**Gate:** ユーザー承認必須

**失敗時 / ロールバック:**

- ユーザー回答が曖昧で確定しない → **同じ `intent-analyst` インスタンスに追加質問を指示**して対話継続
- 成功基準が観測不能 → ユーザーに計測手段を相談して再定義 (Specialist は維持)

### Step 2: Research (調査)

**目的:** 既存コード・既存設計・外部制約を把握し、設計の前提を揃える

**起動 Specialist:** `researcher` × N (観点ごとに並列)

**Main の作業:**

1. Intent Spec から調査観点を導出 (例: 既存実装、依存関係、類似事例、既存 ADR、外部仕様)
2. 観点ごとに `researcher` を **並列起動** (各々に固有のスコープと成果物フォーマットを指定)
3. 全 Researcher の成果物を集約し、Exit Criteria を判定
4. 未解決の不明点があれば Blocker として進捗記録に反映

**成果物:** 観点ごとに `docs/dev-workflow/<identifier>/research/<topic>.md` (対象 / 発見事項 / 引用元 / 設計への含意)

**Exit Criteria:**

- Intent Spec で示された制約が裏付けされている
- 既存実装との接続点・衝突点が列挙されている
- 未解決の不明点が Blocker として明示されている (残っても良いが記録する)
- 全 Research Note がコミット済み、`progress.yaml` に反映

**Gate:** Main 判定 (ユーザー確認は任意。重大な Blocker がある場合のみ In-Progress ユーザー問い合わせ)

**失敗時 / ロールバック:**

- 粒度不足 → **既存の `researcher` インスタンスに深掘り指示を差し戻す**
- 観点不足 → `researcher` を**追加並列起動** (既存は維持)
- Intent Spec と根本矛盾 → Step 1 へロールバック (Step 2 を抜ける時点で全 `researcher` の役割終了)

### Step 3: Design (設計)

**目的:** アーキテクチャと実装アプローチを体系的に設計し、設計ドキュメントを作成する

**起動 Specialist:** `architect` × 1

**プロジェクト固有ルールの適用:** 設計規約 (関数型 / OOP、依存注入手法、エラーモデル等) はプロジェクト固有スキル (例: `effect-layer`, `effect-runtime`, `effect-hono`, `totto2727-fp`) を優先する。Main は `architect` 起動時に該当スキルのパスを入力に含めること。矛盾する場合は「プロジェクト固有ルールとの関係」セクションに従いユーザー判断を仰ぐ。

**Main の作業:**

1. `architect` に Intent Spec、Research Notes、関連プロジェクト固有スキルのパスを渡して起動
2. 生成された設計ドキュメントを**そのままユーザーに提示**してフィードバックを得る
3. ユーザーフィードバックを `architect` に戻し反復改善 (同一インスタンス継続)
4. 確定版を `docs/dev-workflow/<identifier>/design.md` に保存・コミット
5. 設計判断でユーザー判断が必要な場面 (複数候補の優劣が拮抗する等) は **In-Progress ユーザー問い合わせ形式**で一時レポート作成
6. **サイクル中に「プロジェクト全体に及ぶ横断的な意思決定」が発生した場合のみ**、`adr` スキルを使って別途 ADR を起票

**成果物:** `docs/dev-workflow/<identifier>/design.md` (設計目標 / アプローチ / コンポーネント構成 / データフロー / 代替案比較 / 拡張ポイント / 運用上の考慮事項 / プロジェクト横断 ADR へのリンク)

**Exit Criteria:**

- `design.md` + `progress.yaml` がコミット済み (横断 ADR を起票した場合は ADR 本体も同コミット)
- 主要な設計判断について代替案と採用理由が記録されている
- ユーザーが設計方針に同意済み

**Gate:** ユーザー承認必須

**失敗時 / ロールバック:**

- 設計案が意図と乖離 → **同じ `architect` インスタンス**に再検討させる。根本乖離なら Step 1 へ
- Research Notes が支えきれない → Step 2 へ (現 `architect` は維持し追加 Research を待つ)

#### ADR の起票条件

`design.md` とは別に ADR を起票するのは、**サイクル内で発生した意思決定がプロジェクト全体に及ぶ場合に限る**。

| 起票する (プロジェクト横断)          | 起票しない (サイクル内完結)                 |
| ------------------------------------ | ------------------------------------------- |
| 「プロジェクト全体で Effect を採用」 | 「この機能のキャッシュ戦略を LRU にする」   |
| 「全サービスで gRPC を使う」         | 「この API のページネーションは cursor 型」 |
| 「認可レイヤを OpenFGA に統一」      | 「この画面のバリデーションは zod で書く」   |

ADR を起票した場合: `progress.yaml.artifacts.external_adrs` にパス追記、`design.md` から該当 ADR にリンク。

### Step 4: QA Design (テスト設計)

**目的:** Intent Spec の成功基準を観測可能なテストケース集合 (`qa-design.md`) と本質ロジックの分岐図 (`qa-flow.md`) に展開する。各テストケースには「実行主体 × 検証スタイル」の 2 軸を独立に付与し、特定のテストフレームワーク (Vitest / Playwright 等) に依存しない抽象レベルで記述する。

**起動 Specialist:** `qa-analyst` × 1

**プロジェクト固有ルールの適用:** テスト基盤 (vitest / moonbit test 等) の選定はプロジェクト固有スキル (`vite-plus`, `effect-*` 系, `moonbit-bestpractice` 等) を優先する。Main は `qa-analyst` 起動時に該当スキルのパスを入力に含める。`qa-design.md` には抽象化された 2 軸カテゴリのみを記載し、具体ツール名は持たない。

**Main の作業:**

1. `qa-analyst` に Intent Spec、`design.md`、`shared-artifacts/references/qa-design.md` / `qa-flow.md`、`templates/qa-design.md` / `qa-flow.md`、関連プロジェクト言語固有テストスキル (TS なら `vite-plus`、MoonBit なら `moonbit-bestpractice` 等) を渡して起動
2. `qa-analyst` が成功基準を深掘りし、テストケース表 (TC-NNN) と Mermaid 分岐図 (`qa-flow.md`) を作成
3. **確定した qa-design.md / qa-flow.md そのものをユーザーに提示**して承認を得る (一時レポートは作成しない)

**成果物:**

- `docs/dev-workflow/<identifier>/qa-design.md` (本質テスト TC-NNN + 実装都合テスト TC-IMPL-NNN セクション + カバレッジ表 + 2 軸 enum 適用)
- `docs/dev-workflow/<identifier>/qa-flow.md` (本質ロジックの Mermaid flowchart 複数ブロック、各葉に TC-ID または `skip`)

**Exit Criteria:**

- 全成功基準が少なくとも 1 つの TC-NNN でカバーされている (カバレッジ表で確認)
- 「対象成功基準 = (なし)」の TC には必要理由が記載されている
- 各 TC に実行主体 (軸 A) と検証スタイル (軸 B) が enum 値で付与されている
- 禁止組み合わせ (`automated × inspection`) が使われていない
- qa-flow.md の各葉が TC-ID または `skip [理由]` で埋まっている
- ユーザーが qa-design.md / qa-flow.md に同意済み
- `qa-design.md` + `qa-flow.md` + `progress.yaml` がコミット済み

**Gate:** ユーザー承認必須

**失敗時 / ロールバック:**

- 観測不能な成功基準を発見 (テスト化できない) → Step 1 (Intent Clarification) へロールバック
- design.md が振る舞いを定めきれない (テスト設計に必要な詳細がない) → Step 3 (Design) へロールバック
- 自動 / 手動の判断材料が不足 → architect / Main に問い合わせ
- 1 成功基準に対応する TC が 0 件 → Step 1 へロールバック (テスト設計漏れ + 成功基準不明確の可能性)

**注意:**

- `qa-analyst` は本質テストのみ設計 (TC-NNN)。実装都合テスト (TC-IMPL-NNN) は Step 6 implementer が追記 (Step 4 では空欄)
- qa-flow.md の Mermaid 図は本質テスト + 実装都合テスト両方を網羅 (区別は ID prefix で十分、認知負荷軽減のため網羅図示)
- 詳細は `shared-artifacts/references/qa-design.md` および `qa-flow.md` を参照

### Step 5: Task Decomposition (タスク分解)

**目的:** 設計ドキュメントを実装可能な粒度のタスクに分解し、並列性と依存関係を明示する

**起動 Specialist:** `planner` × 1

**Main の作業:**

1. `planner` に `design.md` と Intent Spec を渡して起動
2. 生成された Task Plan の粒度・順序・並列性を Main が検証
3. 不十分なら **同じ `planner` インスタンス**に不足点を差し戻して再分解
4. **確定版 Task Plan そのものをユーザーに提示**して実装開始の承認を得る

**成果物:** `docs/dev-workflow/<identifier>/task-plan.md` (タスク ID / 概要 / 成果物 / 依存関係 / 並列可否 / 見積り規模)

**Exit Criteria:**

- 各タスクが 1 人の Implementer で完遂可能な粒度
- タスク間の依存関係がグラフとして明示されている
- 並列実行可能なタスク群が識別されている
- `task-plan.md` + `progress.yaml` がコミット済み

**Gate:** ユーザー承認必須 (実装開始の合意)

**失敗時 / ロールバック:**

- 粒度が不適切 → **同じ `planner` インスタンス**に粒度基準を明示して再分解
- 依存関係が解決不能 → Step 3 に戻り `design.md` 見直し

### Step 6 着手前: タスクリスト反映 (必須手順)

`planner` が Step 5 で生成した `task-plan.md` は**不変な計画書**として保持し、Step 6 以降で追跡するタスク状態は **2 箇所**に反映する。

#### 1. Main の内部タスクリスト (セッション内)

`TaskCreate` でエージェント内部タスクリストに登録。タスク状態は `TaskUpdate` で更新 (`pending` → `in_progress` → `completed`)。並列起動中のタスクは全て `in_progress`。

#### 2. 永続化タスクリスト `TODO.md`

セッション内部リストは揮発性のため、**作業引き継ぎ・中断再開のために `docs/dev-workflow/<identifier>/TODO.md` に永続化**。Step 6 開始時に `task-plan.md` から生成し、タスク完了のたびに更新・コミット。

**フォーマット詳細:** `shared-artifacts/references/todo.md` + `shared-artifacts/templates/TODO.md`。

**Step 6 における運用:**

- Step 6 開始時: `task-plan.md` から TODO.md を生成 (全タスク `status: pending`) してコミット
- `implementer` 起動時: 該当タスクを `in_progress` に更新、`started_at` と `implementer` ID を記録してコミット
- タスク完了時: `[x]` に変更、`completed_at`、`commit` SHA を記録してコミット
- タスク再活性化時 (Self-Review High 指摘で Step 6 に戻った場合等): `in_progress` に戻し、`re_activations` カウンタをインクリメントしてコミット

**コミット単位:** TODO.md は各タスク状態変化ごとにコミット (頻繁、タスク単位)。例: `docs(dev-workflow/<identifier>): complete task T1`

**同期原則:** TODO.md が真のソース (永続層)、TaskCreate はそのビュー (揮発層)。状態変化時は TODO.md → コミット → TaskUpdate の順で進める。

### Step 6: Implementation (実装)

**目的:** Task Plan に従ってコードを実装する

**起動 Specialist:** `implementer` × N (タスクごと、並列可)

**前提:** Step 6 開始時に `TODO.md` と内部タスクリスト (TaskCreate) が `task-plan.md` から反映されていること (前項参照)。

**プロジェクト固有ルールの適用:** 実装パターン・テスト基盤・命名規則・コミット規約はプロジェクト固有スキル (`effect-layer`, `effect-hono`, `effect-runtime`, `totto2727-fp`, `git-workflow`, `macos-cli-rules` 等) を優先。Main は `implementer` 起動時に該当スキルのパスを入力に含める。

**Main の作業:**

1. `TODO.md` から **並列起動可能なタスク群**を抽出 (依存グラフの起点 / 独立タスク、`status: pending`)
2. 起動予定の各タスクについて `TODO.md` と TaskCreate の状態を `in_progress` に更新してコミット
3. 独立タスクは `implementer` を **並列起動** (各 Specialist に 1 タスクのみ割り当て、`implementer` ID を TODO.md に記録)
4. 依存タスクは前段タスクの完了後に逐次起動
5. 各 `implementer` の diff と動作確認結果を集約
6. **タスク完了ごとに TODO.md を更新** (`[x]` チェック、`completed_at`、`commit` SHA 記録) → コミット → TaskUpdate で `completed`
7. 型チェック・リント・既存テスト実行を Main が指示 (Specialist 側の責任範囲として明示)
8. Exit Criteria 判定し、全タスク完了 (TODO.md 内の全タスクが `[x]`) を確認

**Specialist への入力仕様 (必須項目):** 担当タスク ID と Task Plan 該当部分 / `design.md` 関連箇所 / Intent Spec (スコープ / 非スコープ) / 成果物保存先 / テスト追加方針

**成果物:** タスクごとの diff (Git コミット、コミット単位で分割) + 動作確認ログ (`progress.yaml` に要約 / 大きい場合は `docs/dev-workflow/<identifier>/implementation-logs/<task-id>.md`)

**Exit Criteria:**

- `TODO.md` 内の全タスクが `[x] completed`
- 型チェック・リント・既存テストが通過
- 新規テストが該当タスクに追加されている (テスト不要と判断した場合は理由を記録)
- 各 diff が `design.md` の設計判断に従っている
- **タスクごとに分割された全コミット**がリポジトリに存在する (Step 6 = 複数コミット、タスク単位)
- `TODO.md` + `progress.yaml` が最終状態で反映・コミット済み

**Gate:** Main 判定

**失敗時 / ロールバック:**

- 特定タスクの `implementer` が期待外の成果物 → **当該タスク担当の `implementer` インスタンス**に指摘を差し戻して再試行 (Step 6 完了まで同一インスタンス維持)。TODO.md は `in_progress` のまま保持
- タスク数が不足 → `implementer` を**追加並列起動** (既存は維持)。**`task-plan.md` は Step 6 中を通じて不変**のため、新規タスクは TODO.md の「後発追加タスク」セクションにのみ追記する。差分の理由も TODO.md 冒頭に記録。多発する場合は Step 5 へのロールバック検討
- タスク定義が不適切 → Step 5 にロールバック (Step 6 を抜ける時点で全 `implementer` 役割終了。再入後は新規 `implementer` を起動)。再生成された `task-plan.md` から TODO.md を**再構築** (既存 TODO.md は `TODO.md.pre-rollback-<timestamp>` にリネーム)
- `design.md` との整合性が崩れる → Step 3 に戻るかを Main が判断

**並列実行の注意:**

- 並列 `implementer` 同士が同一ファイルを編集する場合、Task Plan の依存グラフで直列化されているはず。違反があれば Main が直列化し直す
- Git ブランチ戦略: タスクごとに feature branch を切るか、依存順で同一ブランチに逐次積むかを Main が決定
- 並列 `implementer` のうち特定インスタンスだけを終了させてはならない (Step 完了前は全員維持)。不要になっても待機状態とする

### Step 7: Self-Review (自己レビュー)

**目的:** 外部レビュー前に明らかな問題を潰し、手戻りコストを下げる

**起動 Specialist:** `self-reviewer` × 1

**プロジェクト固有ルールの適用:** レビュー観点のうちプロジェクト固有の基準 (セキュリティ基準値、パフォーマンス許容値、設計規約違反の定義) はプロジェクト固有スキルに従う。

**Main の作業:**

1. `self-reviewer` を起動し、全 diff (Step 6 で生成) / `design.md` / Intent Spec / Task Plan を渡す
2. 指摘事項を深刻度別 (High / Medium / Low) に整理
3. **High 指摘があれば Step 6 を再活性化**: 該当タスクを TODO.md で `[x]` → `[ ]` に戻し `status: in_progress`、`re_activations` カウンタをインクリメントしてコミット。前回の `implementer` は Step 6 完了時に役割終了済みのため、該当タスク担当の `implementer` を新規起動して修正させる
4. Medium / Low 指摘は Self-Review Report に記録し、Step 7 (External Review) の判断材料とする
5. 最終的に High 0 件を確認して Exit Criteria 判定 (Step 7 の `self-reviewer` は Exit Criteria 確定まで維持)

**成果物:** `docs/dev-workflow/<identifier>/self-review-report.md` (指摘 / 深刻度 / 該当 diff (コミット SHA + ファイル行番号) / 推奨アクション)

**Exit Criteria:**

- 深刻度 High の指摘が 0 件、または全て修正済み
- `design.md` との整合性が確認済み
- Intent Spec の成功基準を満たす見込みがある
- `self-review-report.md` + `progress.yaml` がコミット済み (1 ステップ = 1 コミット)

**Gate:** Main 判定。High 指摘残があれば Step 6 に戻る (Step 7 へは進めない)

**失敗時 / ロールバック:**

- High 指摘が繰り返し発生 → 設計レベルの問題の可能性。Step 3 への回帰を **In-Progress ユーザー問い合わせ形式**で相談
- `self-reviewer` の指摘が実装者と矛盾 → **セカンドオピニオン用に `self-reviewer` を追加起動** (並列化)。両者の指摘を Main が突き合わせる
- 個別指摘に曖昧さ → **既存の `self-reviewer` インスタンス**に詳細化を指示

**注意:**

- `self-reviewer` は `implementer` と**異なる新規インスタンス**として起動する
- Step 7 の `self-reviewer` は Step 7 の Exit Criteria が確定するまで維持する (Step 6 への差し戻し中も Step 7 を抜けきっていない場合は維持)
- 「自己レビュー」は「実装したエージェントチーム内のレビュー」の意。外部観点のレビューは Step 7 で行う

#### Step 6 ↔ Step 7 ループ

High 指摘があった場合のループ構造。Step 6 と Step 7 は別ステップなので、ステップを跨ぐ Specialist 再利用は行わないが、**各ステップの活性化期間中はインスタンスを維持**する。

```
[Step 6 活性化] implementer A1..AN (並列 N)
    ↓ Exit Criteria 満たす
[Step 6 完了] implementer A1..AN 役割終了
    ↓
[Step 7 活性化] self-reviewer B1 起動
    ↓
    B1 が指摘を生成 ─────┐
    │                     │
    (High 0)        High 指摘あり
    │                     │
Step 7 へ        [Step 6 再活性化]
                 新規 implementer C1..Ck を該当タスクのみに割り当て
                 (B1 は Step 7 継続のため維持)
                 C1..Ck が修正 diff を返却
                     ↓
                 [Step 6 再び完了] C1..Ck 役割終了
                     ↓
                 既存 B1 が再レビュー (差し戻し)
                     ↓
                 High 0 確認 → Step 7 へ (B1 はここで役割終了)
```

**ループ上限の目安:** 同一 Self-Review Report の High 指摘で 3 周以上ループする場合、設計レベルの問題を疑い Step 3 へロールバックを検討。ループのたびに進捗記録へ回数と原因を記録する。

### Step 7: External Review (外部レビュー)

**目的:** 実装者と独立した観点から品質を検証する

**起動 Specialist:** `reviewer` × N (観点ごとに並列)

**プロジェクト固有ルールの適用:** 各観点 (security / performance / readability 等) の具体的判定基準はプロジェクト固有スキルに従う。

**観点の例 (プロジェクト性質に応じて Main が選定):**

- セキュリティ (認証認可、入力検証、秘匿情報の取り扱い)
- パフォーマンス (計算量、I/O、メモリ、並行性)
- 可読性・保守性 (命名、構造、責務分離、コメント)
- テスト品質 (カバレッジ、エッジケース、mock 濫用)
- API 設計 (後方互換性、契約の明確さ、エラーモデル)

**Main の作業:**

1. `design.md` と Intent Spec からレビュー観点を導出
2. 観点ごとに `reviewer` を **並列起動** (Step 6 / 6 の `implementer` / `self-reviewer` とは**別個の新規インスタンス**)
3. 各 `reviewer` に全 diff / `design.md` 関連部分 / Intent Spec / レビュー観点の明示 (「セキュリティのみ」等、スコープ限定) を渡す
4. **全 Review Report そのものをユーザーに提示**して判断を仰ぐ
5. Blocker 指摘があれば Step 6 に差し戻し (Step 7 の `reviewer` 群は Step 7 完了まで維持)

**成果物:** 観点ごとに `docs/dev-workflow/<identifier>/review/<aspect>.md` (指摘 / 深刻度 / 該当箇所 (コミット SHA + ファイル行番号) / 推奨アクション)。`<aspect>` 例: `security.md`, `performance.md`, `readability.md`, `test-quality.md`, `api-design.md`

**Exit Criteria:**

- Blocker 指摘が 0 件
- Minor 指摘は記録のみで進行可 (Retrospective の材料として残す)
- `review/*.md` (全観点) + `progress.yaml` がコミット済み (1 ステップ = 1 コミット、全観点を 1 コミットにまとめる)

**Gate:** ユーザー承認必須 (Blocker 0 件の確認と、Minor 指摘の扱い方針)

**失敗時 / ロールバック:**

- Blocker 指摘発生 → Step 6 に戻り修正 (再活性化時は新規 `implementer` 起動)。戻り後は Step 7 → Step 7 を再実行 (Step 7 は新規 `reviewer` を起動)
- 観点不足 → **追加観点の `reviewer` を並列起動** (既存は維持)
- 既存 `reviewer` のレポートが不明瞭 → **既存インスタンス**に詳細化・根拠追記を指示
- 複数 `reviewer` の指摘が矛盾 → 両者の根拠を **In-Progress ユーザー問い合わせ形式**で提示し判断を仰ぐ

### Step 8: Validation (検証)

**目的:** 成功基準の達成を**観測可能な形**で確認する

**起動 Specialist:** `validator` × 1

**Main の作業:**

1. `validator` に Intent Spec の成功基準 / 実装済み diff と実行環境情報 / テスト実行手順 (Task Plan に記載されたもの) を渡して起動
2. テスト実行 (自動テスト一式) / メトリクス計測 (定量的) / シナリオ検証 (定性的) を指示
3. **Validation Report そのものをユーザーに提示**して判定の承認を得る
4. 未達成の成功基準があれば、対応方針を **In-Progress ユーザー問い合わせ形式**で提示

**成果物:** `docs/dev-workflow/<identifier>/validation-report.md` (成功基準 / 観測値 / 判定 / 証拠 (ログ / スクリーンショット / メトリクスへのパスや添付))。大きな証拠データは `docs/dev-workflow/<identifier>/validation-evidence/` 配下にサブディレクトリで保存。

**Exit Criteria:**

- Intent Spec の全成功基準が PASS、または明示的に保留理由付きで記録されている
- 観測値の**証拠 (ログ / スクリーンショット / メトリクス)** が残されている
- `validation-report.md` + `validation-evidence/*` (該当あれば) + `progress.yaml` がコミット済み

**Gate:** ユーザー承認必須

**失敗時 / ロールバック:**

- 成功基準未達 → 原因に応じてロールバック先を決定:
  - 実装バグ → Step 6
  - 設計ミス → Step 3
  - 成功基準の設定自体が不適切 → Step 1
- 検証手段が不適切 → **既存の `validator` インスタンス**に計測手段変更を差し戻す
- 検証スコープが拡大 → **追加の `validator` を並列起動**も可

**注意:** Validation は「主観的な OK / NG 判断」ではなく「客観的な観測値との比較」であることを Main が Specialist 指示に含める。

### Step 9: Retrospective (振り返り)

**目的:** 今サイクルの学びを次サイクルに残す

**起動 Specialist:** `retrospective-writer` × 1

**Main の作業:**

1. `retrospective-writer` に全ステップの進捗記録 / 全成果物 (Intent Spec / Research Notes / Design Document / Task Plan / diff / 各種 Report / 起票したプロジェクト横断 ADR があれば) / Blocker 履歴 / ループ回数 (Step 6 ↔ Step 7 の往復、Step 7 の差し戻し回数) / ユーザー承認ゲートでのやり取りを渡す
2. 生成された Retrospective Note をユーザーに提示
3. 次サイクルで参照可能な形式でリポジトリに保存

**成果物:** `docs/dev-workflow/<identifier>/retrospective.md` (良かった点 / 課題 / 次回改善案 / 再利用可能な知見)

**Exit Criteria:**

- `retrospective.md` + `progress.yaml` (`status: completed` に更新) がコミット済み (サイクル最終コミット)
- 次サイクル開始時に参照可能な場所・名称になっている

**Gate:** Main 判定 (ユーザーには情報共有のみ)

**失敗時 / ロールバック:**

- 振り返り内容が抽象的すぎる → **既存の `retrospective-writer` インスタンス**に具体的エピソードを指示して再生成
- 次回改善案が実行不可能 → **既存インスタンス**にアクション粒度まで分解するよう指示

---

## 調整プロトコル (Main ↔ Specialist)

### 1. ワークフロー開始時

1. ユーザーが Main にワークフロー開始を指示
2. Main はまず `docs/dev-workflow/` 配下に**再開可能なサイクルが存在しないか**確認する
   - 存在する場合: ユーザーに再開するかを確認。再開時は該当の `progress.yaml` を読み込んで「5. セッション再開時」の手順へ
   - 存在しない、または新規サイクル: 3 へ進む
3. Main はユーザーと `<identifier>` の命名を合意し、`docs/dev-workflow/<identifier>/` を作成
4. `progress.yaml` を初期化 (`current_step: Step 1`, 空の `completed_steps` 等) してコミット
5. Step 1 から着手する

### 2. ステップ実行ループ (全ステップ共通)

```
[Main]        → 現在ステップの Specialist を起動 (入力・スコープ・期待成果物を明示)
[Specialist]  → 作業実行、成果物を Main に返却 (同一ステップ内では存続)
[Main]        → Exit Criteria を照合
                ├─ 満たす       → Specialist の役割終了。次ステップへ (またはユーザー承認ゲートへ)
                ├─ 満たさない   → 同じ Specialist にフィードバックを差し戻して再試行
                ├─ スコープ拡大 → 同一ステップ内で Specialist を**追加起動**
                ├─ 前提崩壊     → 前ステップに戻る (現ステップの Specialist は役割終了)
                └─ Blocker      → 「4. Blocker 発生時」へ
```

**重要:** ステップ完了前に Specialist を terminate / replace してはならない。期待外の結果が返ってきても、**既存インスタンスにフィードバックを差し戻す**形で再試行させる。追加は容認されるが終了は禁止。

### 3. ゲート通過時

- **ユーザー承認ゲート (= 該当ステップ末尾の承認)**:
  1. Main は該当ステップの**成果物そのもの** (Intent Spec / Design Document / Task Plan / Review Report / Validation Report 等) のパスをユーザーに提示
  2. Main は Exit Criteria 充足状況を口頭で要約して補足する (成果物に書かれていない "判定プロセス" の部分)
  3. 一時レポートは作成しない
  4. 承認されれば次ステップへ進む。却下されれば却下理由を進捗記録に残し、前ステップに戻るか現ステップ内で Specialist に差し戻して修正
  5. 却下理由が「判断材料不足」であれば、成果物の品質 (記述の具体性・網羅性) を高める方向で Specialist にフィードバック
- **In-Progress ユーザー問い合わせ (作業途中の判断要請)**:
  1. Main が確認事項 (経緯 / 選択肢 / 推奨案 / 確認したい事項) を整理
  2. **一時レポートを `$TMPDIR/dev-workflow/step<N>-<purpose>.md` に書き出す**
  3. ユーザーにレポートのパスを案内し、口頭で要点を補足する
  4. ユーザー判断を受けて作業を再開。一時レポートは Retrospective で参照可能にする (ただし最終成果物には含めない)
- **Main 判定ゲート**: Main が Exit Criteria の各項目を照合し、通過可否を決定。判定結果は進捗記録に反映し、ユーザー確認は不要

### 4. Blocker 発生時

1. Specialist が Blocker を検知 → **作業を中断して Main に報告** (独断で回避策を試さない)
2. Main は以下のいずれかを選択:
   - 前ステップに戻る (設計不足、意図不明確等)
   - 並列 Specialist を追加起動 (別観点の調査等)
   - ユーザーに判断を仰ぐ (**In-Progress ユーザー問い合わせ**形式で一時レポート作成)
3. `progress.yaml.blockers` に追記してコミット

### 5. セッション再開時

別セッション/別ユーザーが中断済みサイクルを再開する手順。

1. `docs/dev-workflow/<identifier>/progress.yaml` を読み込む
2. `current_step` / `completed_steps` / `pending_gates` / `active_specialists` / `blockers` を確認
3. 既存成果物ファイル (`intent-spec.md` / `research/*.md` / `design.md` / `task-plan.md` / `TODO.md` / その他) を全て読み込み、文脈を再構築
4. **Step 6 を再開する場合**: `TODO.md` を読み込み、`TaskCreate` で内部タスクリストを**完全復元**する
   - `[x] completed` → TaskUpdate で `completed` 状態に
   - `status: in_progress` のタスク → `pending` に戻す (前セッションの `implementer` は役割終了済みのため、該当 `implementer` を新規起動し直すまで `pending` 扱い)
   - TODO.md と TaskCreate に齟齬があれば **TODO.md を正**として修正してコミット
5. **前セッションの Specialist は全て役割終了扱い**とする (`active_specialists` に `running` があっても、セッション跨ぎでの再利用は禁止のため)
6. 現在の `current_step` を継続する場合は、新規 Specialist を起動して当該ステップを再活性化
7. `blockers` があればユーザーに再提示し、対応方針を確認 (**In-Progress ユーザー問い合わせ**形式)
8. `progress.yaml.updated_at` を更新してコミット (再開マーカー)

---

## 成果物テンプレート・保存構造・進捗記録フォーマット

本プラグインでは**成果物仕様を `shared-artifacts` スキルに集約**することで、Main / Specialist / ユーザーの全ステークホルダーが同じ真のソースを参照できるようにしている。テンプレートと書き方ガイドの 1:1 対応が担保され、仕様変更時の更新漏れを防げる。

Main は以下を参照する:

- **成果物一覧とテンプレートパス**: `shared-artifacts` SKILL.md の「成果物一覧 (目次)」
- **ディレクトリ構造** (`docs/dev-workflow/<identifier>/` 配下): `shared-artifacts` SKILL.md の「成果物保存構造」
- **`<identifier>` の命名ルール**: `shared-artifacts` SKILL.md の「`<identifier>` の命名ルール」
- **サイクル外成果物** (プロジェクト横断 ADR、一時レポート): `shared-artifacts` SKILL.md の「サイクル外の成果物」
- **各成果物の書き方**: `shared-artifacts/references/<name>.md` (1:1 対応)
- **`progress.yaml` のスキーマ・書き方**: `shared-artifacts/references/progress-yaml.md`
- **`design.md` と ADR の使い分け**: `shared-artifacts/references/design.md`
- **`TODO.md` と内部タスクリストの同期**: `shared-artifacts/references/todo.md`

Specialist 起動時、Main はテンプレートパス (`shared-artifacts/templates/<name>.md`) と reference パス (`shared-artifacts/references/<name>.md`) の**両方を入力に含める**こと。Specialist はテンプレートを埋める際、必ず対応する reference を参照する。

---

## プロジェクト固有ルールとの関係

本ワークフローは**汎用的なプロセス構造**を提供する。一方で、個別プロジェクトは固有の規約・スキルを持つことが多く、これらは本ワークフローの抽象的ルールよりも**具体的でプロジェクトの現実に即している**。以下の使い分けを原則とする。

### 本ワークフローに従う領域 (プロセス構造)

- 10 ステップ構成と各ステップのゲート判定
- Main / Specialist の役割分離と起動プロトコル
- 成果物形式 (`intent-spec.md` / `design.md` / `task-plan.md` / `TODO.md` / 各種 Report / `retrospective.md`)
- ユーザー承認ゲート・In-Progress 問い合わせの使い分け
- ステップ完了時のコミット規約 (1 ステップ = 1 コミット、Step 6 のみタスク単位)
- サイクル作業ディレクトリ `docs/dev-workflow/<identifier>/` のレイアウト

### プロジェクト固有ルールを優先する領域 (作業内容)

- **実装パターン**: 言語・フレームワーク・ライブラリ固有の書き方 (例: `effect-layer`, `effect-hono`, `effect-runtime`, `totto2727-fp` 等のプロジェクト固有スキル)
- **テストルール**: テスト基盤、モック戦略、カバレッジ要件、E2E 判定基準
- **コードレビュー観点**: セキュリティ・パフォーマンス・可読性の各基準値
- **コミット規約 / ブランチ戦略**: プロジェクトの `git-workflow` スキル、Conventional Commits のスコープ命名、GPG 署名要件
- **設計規約**: 採用する設計パターン (関数型 / OOP)、エラーモデル、依存注入手法
- **命名規則・ディレクトリ構造**: プロジェクトの慣習
- **プラットフォーム固有コマンド**: macOS の `gsed` / `ggrep` 等 (`macos-cli-rules`)

### 適用手順

Main / Specialist は各ステップ開始前に以下を確認する:

1. プロジェクトの CLAUDE.md を読んで本ワークフローと整合するルール・禁止事項を把握
2. プロジェクトのスキル一覧を確認 (`plugins/<project>/skills/` 配下等)
3. 該当ステップで関連するプロジェクト固有スキル (例: 実装なら `effect-layer`、コミットなら `git-workflow`) を特定し、Specialist 起動時の入力に含める
4. 本ワークフローのデフォルト手順とプロジェクト固有ルールを比較:
   - **整合している** → 両者を併用
   - **プロジェクト固有が本ワークフローを具体化している** → プロジェクト固有に従う
   - **明確に矛盾している** → **作業を中断し、In-Progress ユーザー問い合わせ形式でユーザーに判断を仰ぐ** (独断で片方に寄せない)

### 矛盾の判定例

| ケース                                                                         | 解決                                                                                          |
| ------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| 本ワークフローは任意のコード設計を許容、プロジェクトは Effect Layer 必須       | プロジェクト優先 (`effect-layer` スキルに従う)                                                |
| Self-Review の汎用観点、プロジェクトに固有のレビュー観点あり                   | 両方併用 (汎用観点 + プロジェクト固有観点)                                                    |
| 本ワークフローは `docs(dev-workflow/...)` コミット規約、プロジェクトは独自     | 独自スコープ規約と折衷 (`docs(dev-workflow/<id>,project-scope): ...` 等) を提案しユーザー判断 |
| 本ワークフローの task 粒度「1 日以内」、プロジェクト規約が「1 PR = 複数週」    | **矛盾** → ユーザー判断 (別サイクルに分割するか、粒度を妥協するか)                            |
| 本ワークフローは `docs/dev-workflow/` 直下、プロジェクトが `doc/specs/` を使う | **軽微な矛盾** → プロジェクトに合わせて `doc/dev-workflow/` 等に調整、ユーザー承認            |

### Specialist への伝達

Main は Specialist 起動時に**関連するプロジェクト固有スキルのパス**を入力に含めること。`specialist-common` の入力契約に従って、参照すべきスキル一覧が明示されない場合は Specialist 側から Main に問い合わせる。

---

## ステップ完了時のコミット規約

各ステップが完了した時点で、そのステップで生成・更新された成果物は**必ずリポジトリにコミット**する。次のステップを開始する時点では、一時ファイル (`$TMPDIR/dev-workflow/*.md`) を除いて差分が存在しない状態が期待される。

### 原則

- **1 ステップ = 1 コミット** (Step 6 を除く)
- **Step 6 のみタスク単位で複数コミット** (task-plan の粒度に従う)
- コミットに含めるのは**成果物ファイル + `progress.yaml` + `TODO.md`** (該当する場合)
- 一時ファイル (`$TMPDIR/` 配下) は**決してコミットしない**
- プロジェクト横断 ADR を起票した場合は、該当 ADR ファイルも同じコミットに含めてよい (`design.md` の更新とセットで)

### ステップ別コミット内訳

| Step                    | コミット内容                                                                                                                                                                  |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| サイクル開始時          | `docs/dev-workflow/<identifier>/` ディレクトリ作成 + `progress.yaml` 初期化                                                                                                   |
| 1. Intent Clarification | `intent-spec.md` + `progress.yaml`                                                                                                                                            |
| 2. Research             | `research/*.md` (全観点まとめて) + `progress.yaml`                                                                                                                            |
| 3. Design               | `design.md` + `progress.yaml` (+ 起票した場合のみ ADR 本体)                                                                                                                   |
| 4. QA Design            | `qa-design.md` + `qa-flow.md` + `progress.yaml`                                                                                                                               |
| 5. Task Decomposition   | `task-plan.md` + `progress.yaml`                                                                                                                                              |
| 6. Implementation       | **タスクごとに 1 コミット** (実装 diff + `TODO.md` 該当タスク状態 + `progress.yaml`、必要に応じ `implementation-logs/<task-id>.md` / `qa-design.md` 追記 / `qa-flow.md` 追記) |
| 7. Self-Review          | `self-review-report.md` + `progress.yaml`                                                                                                                                     |
| 8. External Review      | `review/*.md` (全観点まとめて) + `progress.yaml`                                                                                                                              |
| 9. Validation           | `validation-report.md` + `validation-evidence/*` (ある場合) + `progress.yaml`                                                                                                 |
| 10. Retrospective       | `retrospective.md` + `progress.yaml` (最終コミット、`status: completed`)                                                                                                      |

**Step 6 補足:**

- 並列 `implementer` が独立タスクを実装している場合でも、**コミットは 1 タスク単位** (他タスクの進行中 diff が混ざらないよう注意)
- Self-Review High 指摘で再実装する場合、**修正コミットも別途作成** (amend しない、通常の新規コミットで追記)

### ユーザー承認ゲート通過時

承認結果を `progress.yaml.user_approvals` に反映してコミット。以下のいずれかのタイミングで:

- 該当ステップ完了コミットと同時 (承認が即時の場合)
- ステップ完了コミット後の別コミット (承認ゲートでユーザー判断待ちの時間がある場合)

### コミットメッセージ規約

プロジェクト固有の規約 (`git-workflow` スキル等) があればそれを優先。該当がない場合の推奨形式:

```
docs(dev-workflow/<identifier>): complete Step <N> (<StepName>)
docs(dev-workflow/<identifier>): record user approval for Step <N>
docs(dev-workflow/<identifier>): initialize cycle
feat(dev-workflow/<identifier>/task-<id>): <task summary>   # Step 6 Implementation
docs(dev-workflow/<identifier>): close cycle with retrospective
```

### コミット前チェック

各ステップ完了時、Main は以下を順に実行する:

1. 該当ステップの Exit Criteria が満たされているか確認
2. 成果物ファイルが `docs/dev-workflow/<identifier>/` 配下に全て配置されているか
3. `progress.yaml` の `completed_steps` / `artifacts` / `updated_at` を更新
4. `git status` で想定したファイルのみが変更されているか確認
5. `git add` は**明示的にファイルを指定** (`.` や `-A` は一時ファイルを巻き込むリスクあり)
6. `git commit` で規約に従ったメッセージで記録

### 一時ファイルの扱い

- 一時レポート (`$TMPDIR/dev-workflow/*.md`) は**そもそも `docs/dev-workflow/<identifier>/` 外に存在する**ためコミット対象にならない
- `.gitignore` で `$TMPDIR` 配下を明示する必要はない (絶対パスで分離されているため)
- サイクル完了時に `$TMPDIR/dev-workflow/<cycle>-*.md` を残す / 削除するかはプロジェクト方針に従う (Retrospective 分析に使うなら残す、機密情報を含むなら削除)

---

## 並列起動のガイドライン

| Step                    | 並列起動推奨度 | 並列軸                                   |
| ----------------------- | -------------- | ---------------------------------------- |
| 1. Intent Clarification | 低             | 単一 Specialist で対話ループ             |
| 2. Research             | 高             | 調査観点ごと (既存実装 / 依存 / 事例)    |
| 3. Design               | 低             | 設計は一貫性が重要なので原則 1 名        |
| 4. QA Design            | 低             | テスト戦略の一貫性のため 1 名            |
| 5. Task Decomposition   | 低             | 全体俯瞰が必要なので 1 名                |
| 6. Implementation       | 高             | Task Plan の独立タスクごと               |
| 7. Self-Review          | 低             | 全体整合性が必要なので原則 1 名          |
| 8. External Review      | 高             | レビュー観点ごと (セキュリティ / 性能等) |
| 9. Validation           | 低             | 成功基準の統一判定が必要なので 1 名      |
| 10. Retrospective       | 低             | 全体俯瞰が必要なので 1 名                |

---

## 逸脱時のリカバリ

### ユーザーが途中でスコープを変更した

1. Main は変更内容を進捗記録に反映し、影響範囲を評価
2. 必要なら Step 1 (Intent Clarification) まで戻す
3. 既存成果物は破棄せず、Retrospective で再利用可能性を検討

### Specialist が期待外の成果物を返した

1. Main は成果物をそのまま進捗記録に残す (隠蔽しない)
2. 不足・逸脱内容を明示して、**既存の同一 Specialist にフィードバックを差し戻し**再試行させる (ステップ完了前に Specialist を終了させない)
3. スコープが拡大した場合に限り、**追加の Specialist を並列起動** (既存 Specialist は終了させず維持)
4. フィードバックを数周繰り返しても改善しない場合は、前ステップに戻すかユーザー判断を仰ぐ (それでも現ステップの Specialist は終了させず、ステップを抜ける時点で役割終了となる)

### ステップ間で整合性が崩れた

1. Main は該当ステップの Exit Criteria を再確認
2. 満たされていない Criteria に対応する前ステップまでロールバック
3. ロールバック範囲と再実行計画をユーザーに **In-Progress ユーザー問い合わせ**形式 (一時レポート) で提示して判断を仰ぐ

### ロールバック先早見表

| 発見ステップ | 問題                                    | ロールバック先 |
| ------------ | --------------------------------------- | -------------- |
| Step 2       | 既存実装と Intent 矛盾                  | Step 1         |
| Step 3       | 設計が意図と乖離                        | Step 1         |
| Step 3       | Research 不足                           | Step 2         |
| Step 4       | 観測不能な成功基準を発見                | Step 1         |
| Step 4       | 振る舞いの定義が不足 (テスト化困難)     | Step 3         |
| Step 5       | 依存関係が解決不能                      | Step 3         |
| Step 6       | タスク定義が不適切                      | Step 5         |
| Step 6       | 設計との整合性が崩れる                  | Step 3         |
| Step 7       | High 指摘                               | Step 6         |
| Step 7       | 設計レベルの問題                        | Step 3         |
| Step 7       | Blocker 指摘                            | Step 6         |
| Step 8       | 実装バグ                                | Step 6         |
| Step 8       | 設計ミス                                | Step 3         |
| Step 8       | 成功基準が不適切                        | Step 1         |
| Step 8       | テスト設計漏れ (qa-flow カバレッジ不足) | Step 4         |

---

## このスキルが扱わないこと

- 各 Specialist の作業詳細 → `specialist-*` スキル (役割別) と `specialist-common` (横断ルール) に委譲
- 各 Specialist をサブエージェントとして起動する際のエントリポイント定義 → `agents/*.md`
- プロジェクト全体に及ぶ横断的な意思決定の記録 → `adr` スキルに委譲 (本ワークフロー内でサイクルを跨いで影響する決定が発生した場合のみ使用。Design Document の代替にはならない)
- 個別の Specialist のプロンプト詳細 → 将来的に agents/ 配下で定義
- ツール固有のコマンド → プロジェクト固有のスキル (`effect-layer` 等) に委譲
- ワークフロー外の単発修正 → 通常の会話で処理
- デプロイ・観測・SLA 監視 → 本ワークフロー外 (CI/CD パイプライン等)
