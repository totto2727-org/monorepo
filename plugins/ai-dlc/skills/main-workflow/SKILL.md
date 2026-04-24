---
name: main-workflow
description: >
  [Main 用] AI-DLC (AI-Driven Development Lifecycle) の全体ワークフローを管理するルール集。
  Main が進捗管理とエージェント起動を兼ね、Inception → Construction → Verification の
  3フェーズを順次実行する。各フェーズの詳細は個別スキル (main-inception / main-construction /
  main-verification) に、各 Specialist の作業詳細は specialist-* スキルに委譲する。
  起動トリガー: "ai-dlc を開始", "開発ワークフローを実行", "新機能を ai-dlc で進める",
  "AI 駆動開発ライフサイクル", "AI-DLC フローで設計から実装まで"。
  Do NOT use for: 単一フェーズのみの実行（該当する main-* フェーズスキルを直接使う）、
  Specialist 側の作業詳細（specialist-* スキルを使う）、単発のコード修正。
metadata:
  author: ai-dlc
  version: 1.0.0
---

# AI-DLC Workflow — Multi-Agent Development Lifecycle

ユースケースカテゴリ: **Workflow Automation**
設計パターン: **Sequential Workflow** + **Multi-Service Coordination**（ゲート付き順次実行 + Main/Specialist 2 層調整）

このスキルは「AI-DLC (AI-Driven Development Lifecycle)」を **Agents Team 前提**で実行するための**ワークフロー全体の司令塔**である。
人間との対話・進捗管理・エージェント起動を担う **Main** と、各ステップを実行する **Specialist** の 2 層構成で、3 フェーズをゲート式で進行させる。
各フェーズの詳細な手順・Specialist 起動仕様は**個別スキルに委譲**する。

## Main と Orchestrator を分離しない理由

Claude Code の仕様により、**サブエージェントは別のサブエージェントを起動できない**（"Subagents cannot spawn other subagents." / "No nested teams: teammates cannot spawn their own teams or teammates. Only the lead can manage the team."）。
Orchestrator を独立したサブエージェントとして切り出しても、Specialist を起動するために結局 Main に指示を戻す必要があり、1 往復分のオーバーヘッドが増えるだけで実質的な分離にならない。
本スキルでは **Orchestrator の責務（進捗管理・ゲート判定・Specialist への指示起案）を Main に統合**し、役割は 2 層（Main / Specialist）のみとする。

## 基本方針

- **Main-Centric Orchestration**: Main が人間との対話・進捗管理・Specialist 起動・ゲート判定を全て担う。Specialist はステップ実行のみに専念する
- **Single-Source-of-Progress**: ワークフローの進捗は Main が唯一の真実として保持する。Specialist は自分で次のステップを決めない
- **One-Shot Specialist & Within-Step Persistence**: 各 Specialist は **1 ステップ限定**でステップを跨いで使い回さない。一方、**同一ステップ内では原則として同じ Specialist インスタンスを維持**する
  - ステップ完了までの間、Specialist の**終了（kill / replace）は禁止**。期待外の成果物が返っても、既存 Specialist にフィードバックを差し戻して再試行させる
  - ステップ完了までの間、Specialist の**追加**は容認される（スコープ拡大・観点追加・並列タスク追加のため）
  - ステップの Exit Criteria が満たされ次フェーズへ進む時点で Specialist の役割は終了する
- **Gate-Based Progression**: 各ステップには明確な完了基準（Exit Criteria）があり、それを満たさない限り次ステップに進まない
- **Artifact-Driven Handoff**: ステップ間の受け渡しは人間が読める成果物（ドキュメント、設計書、計画書、diff）で行う。口伝や暗黙知に頼らない
- **Project-Rule Precedence for Details**: 本プラグインの AI-DLC ワークフローは**プロセス全体の構造**（フェーズ・ステップ・成果物形式・ゲート判定）を提供するが、**実装パターン・テストルール・コミット/ブランチ規約・設計規約・コードレビュー観点・命名規則**など**具体的な作業内容**はプロジェクト固有のルール・スキル（`effect-layer` / `git-workflow` / プロジェクト CLAUDE.md 等）を優先する。両者が矛盾する場合は独断で解決せず、**In-Progress ユーザー問い合わせ形式でユーザーに判断を仰ぐ**（詳細は後述「プロジェクト固有ルールとの関係」参照）
- **Commit-Based Resumability**: サイクルの成果物と進捗記録は `docs/ai-dlc/<identifier>/` に集約し、**各ステップ完了時に必ずコミット**する。これにより別セッション／別ユーザーがコミットを取得して作業を再開できる（詳細は後述「ステップ完了時のコミット規約」参照）
- **Clean-Transition Between Steps**: 次ステップ着手時には、**一時ファイル（`$TMPDIR/ai-dlc/*.md`）以外は差分がない状態**とする。前ステップで作った成果物は全てコミット済みであること。これにより「ステップ完了の認識ずれ」「中途半端なファイルが次ステップに混入」を防ぐ
- **Artifact-as-Gate-Review**: ステップ／フェーズ末尾の**ユーザー承認ゲートでは、そのステップの成果物そのものをレビュー対象とする**（Intent Spec / Design Document / Task Plan / Review Report / Validation Report 等）。一時レポートは作成しない。成果物こそが承認判断の材料である
  - Main は該当成果物のパスを案内し、要点を口頭で補足する
  - 端的な質問（「これでいいですか？」）は禁止だが、解消は**成果物の質**で行う（成果物に必要な情報が書かれていれば、それを読めば判断できる）
- **Report-Based Confirmation for In-Progress Questions**: **作業途中でユーザーに判断や情報提供を求める際**は、**必ず詳細な文脈レポートを一時ファイルとして作成**し、それを提示したうえで確認を取る
  - 対象ケース（いずれも成果物が未完成の状態でユーザー判断が必要な場面）:
    - Blocker 発生時の方針相談（前ステップへのロールバック可否、代替案の選定等）
    - スコープ変更の意思確認
    - Specialist 同士の指摘が矛盾し、ユーザー判断が必要な場合
    - ステップ内で複数アプローチが競合し、推奨案を提示して決定を仰ぐ場合
  - 対象外: **ステップ末尾のユーザー承認ゲート**（成果物そのもので代用できるため一時レポート不要）
  - 端的な質問は禁止。ユーザーが文脈を把握できず、適切な判断ができないため
  - レポートは**最終成果物（設計ドキュメント / 各種レポート / コード）には含めない**。判断のための一時資料
  - 保存先: `$TMPDIR/ai-dlc/<phase>-<step>-<purpose>.md`（例: `$TMPDIR/ai-dlc/construction-step5-rollback-query.md`）
  - レポート最小構成: `# 目的` / `# これまでの経緯` / `# 選択肢と根拠` / `# 推奨案` / `# 確認したい事項`
  - ユーザーには「レポートを `<path>` に作成しました。確認のうえ指示してください」と案内し、口頭で要点をかいつまんで提示する

---

## 役割定義

### Main（メインエージェント = オーケストレーター兼務）

**責務:**

- 人間（ユーザー）との直接対話
- ワークフロー全体の進捗管理（現在フェーズ・ステップ・ゲート・Blocker）
- 各ステップの Specialist 起動（入力・期待成果物の指定を含む）
- 各ステップのゲート判定（Exit Criteria 充足確認）
- ユーザー承認ゲートでのレポート作成と確認取得

**原則:**

- Main は**実装作業を自分で行わない**（対話・判断・割り当てに専念）
  - 例外: ワークフロー開始前の初期確認、Specialist 未起動時の軽微な質問回答、進捗記録の更新
- Specialist 起動時は以下を明示する:
  - 役割（例: `researcher` / `implementer`）
  - 入力（Intent Spec, Research Notes, 該当タスク定義など）
  - 期待成果物（フォーマットと保存先）
  - スコープ境界（これをやる / これはやらない）
- 進捗状態（後述の「進捗記録フォーマット」）を各ターンで更新し、必要に応じてユーザーに可視化する

### Specialist（専門エージェント）

**責務:**

- 割り当てられた 1 ステップ（または 1 タスク）を完遂する
- 成果物を Main に返却する（次ステップに持ち運び可能な形式）

**原則:**

- Specialist は**自分のスコープ外を触らない**（例: Researcher は実装しない）
- 次ステップを勝手に開始しない（完了報告のみ）
- 1 Specialist = 1 ステップ（ステップを跨いで使い回さない）
- **同一ステップ内では存続を維持する**: ステップ完了まで Main は Specialist を終了させない。期待外の結果が出ても同じ Specialist にフィードバックを差し戻して再試行する
- 同一ステップ内で並列実行可能（例: 複数観点の調査、複数タスクの並列実装）。ステップ途中での **追加起動も容認**（スコープ拡大時）
- Blocker に遭遇した場合は独断で回避策を取らず、**作業を中断して Main に報告**する

---

## ワークフロー全体図

```
┌─────────────────── Inception ────────────────────┐
│  1. Intent Clarification                          │
│  2. Research                                      │
│  3. Design                                        │
│  4. Task Decomposition                            │
└──────────────────────────────────────────────────┘
                       │
                       ▼ Gate: 実装計画承認（ユーザー承認）
┌─────────────────── Construction ─────────────────┐
│  5. Implementation                                │
│  6. Self-Review                                   │
└──────────────────────────────────────────────────┘
                       │
                       ▼ Gate: 自己レビュー通過（Main 判定）
┌─────────────────── Verification ─────────────────┐
│  7. External Review                               │
│  8. Validation                                    │
│  9. Retrospective                                 │
└──────────────────────────────────────────────────┘
                       │
                       ▼ 完了
```

---

## フェーズ概要

各フェーズの詳細手順（ステップ定義 / Specialist 仕様 / Exit Criteria / Gate）は個別スキルに定義されている。Main は該当フェーズに入る時点で対応するスキルを参照すること。

### Phase 1: Inception（意図 → 実装計画）

**目的:** ユーザーの意図を言語化し、調査と設計を経て、実装可能なタスクに分解する

**入力:** ユーザー要求、現在のリポジトリ状態
**成果物:**
- `docs/ai-dlc/<identifier>/intent-spec.md`
- `docs/ai-dlc/<identifier>/research/<topic>.md`（観点ごと）
- `docs/ai-dlc/<identifier>/design.md`（設計ドキュメント本体）
- `docs/ai-dlc/<identifier>/task-plan.md`

**出口ゲート:** ユーザー承認（Task Plan に基づく実装開始の合意）

**詳細スキル:** `main-inception` — 以下 4 ステップ
1. Intent Clarification — 意図明確化
2. Research — 調査
3. Design — 設計（設計ドキュメント作成）
4. Task Decomposition — タスク分解

### Phase 2: Construction（実装計画 → コード）

**目的:** Task Plan に従ってコードを実装し、外部レビュー前に自己レビューで明らかな問題を潰す

**入力:** Task Plan, Design Document, Intent Spec
**成果物:**
- タスクごとの diff（Git コミットとして）
- `docs/ai-dlc/<identifier>/self-review-report.md`

**出口ゲート:** Main 判定（High 指摘 0 件、設計ドキュメントとの整合性確認）

**詳細スキル:** `main-construction` — 以下 2 ステップ
5. Implementation — 実装
6. Self-Review — 自己レビュー

### Phase 3: Verification（コード → 完了）

**目的:** 独立した観点からの外部レビューと成功基準の検証を行い、振り返りで学びを残す

**入力:** 実装済み diff, Design Document, Intent Spec
**成果物:**
- `docs/ai-dlc/<identifier>/review/<aspect>.md`（観点ごと）
- `docs/ai-dlc/<identifier>/validation-report.md`
- `docs/ai-dlc/<identifier>/retrospective.md`

**出口ゲート:** ユーザー承認（Validation 結果ベース）

**詳細スキル:** `main-verification` — 以下 3 ステップ
7. External Review — 外部レビュー
8. Validation — 検証
9. Retrospective — 振り返り

---

## 調整プロトコル（Main ↔ Specialist）

### 1. ワークフロー開始時

1. ユーザーが Main に対して AI-DLC 開始を指示
2. Main はまず `docs/ai-dlc/` 配下に**再開可能なサイクルが存在しないか**確認する
   - 存在する場合: ユーザーに再開するかを確認。再開時は該当の `progress.yaml` を読み込んで「### 5. セッション再開時」の手順に進む
   - 存在しない、または新規サイクルを開始する場合: 3 へ進む
3. Main はユーザーと `<identifier>` の命名を合意し、`docs/ai-dlc/<identifier>/` を作成
4. `progress.yaml` を初期化（`phase: Inception`, `current_step: Step 1`, 空の `completed_steps` 等）してコミット
5. `main-inception` スキルを参照して Step 1 から着手する

### 2. ステップ実行ループ（全フェーズ共通）

```
[Main]        → 現在ステップの Specialist を起動（入力・スコープ・期待成果物を明示）
[Specialist]  → 作業実行、成果物を Main に返却（同一ステップ内では存続）
[Main]        → Exit Criteria を照合
                ├─ 満たす       → Specialist の役割終了。次ステップへ（またはユーザー承認ゲートへ）
                ├─ 満たさない   → 同じ Specialist にフィードバックを差し戻して再試行
                ├─ スコープ拡大 → 同一ステップ内で Specialist を**追加起動**
                ├─ 前提崩壊     → 前ステップに戻る（現ステップの Specialist は役割終了）
                └─ Blocker      → 調整プロトコル 4 へ
```

**重要:** ステップ完了前に Specialist を terminate / replace してはならない。期待外の結果が返ってきても、**既存インスタンスにフィードバックを差し戻す**形で再試行させる。追加は容認されるが終了は禁止。

### 3. ゲート通過時

- **ユーザー承認ゲート（= ステップ／フェーズ末尾の承認）**:
  1. Main は該当ステップの**成果物そのもの**（Intent Spec / Design Document / Task Plan / Review Report / Validation Report 等）のパスをユーザーに提示
  2. Main は Exit Criteria 充足状況を口頭で要約して補足する（成果物に書かれていない "判定プロセス" の部分）
  3. 一時レポートは作成しない（成果物そのものが承認判断の材料となるため）
  4. 承認されれば次ステップへ進む。却下された場合は却下理由を進捗記録に残し、前ステップに戻るか現ステップ内で Specialist に差し戻して修正
  5. 却下理由が「判断材料不足」であれば、成果物の品質（記述の具体性・網羅性）を高める方向で Specialist にフィードバック（一時レポートを追加で書くのではなく、成果物を改善する）
- **In-Progress ユーザー問い合わせ（作業途中の判断要請）**:
  1. Main が確認事項（経緯 / 選択肢 / 推奨案 / 確認したい事項）を整理
  2. **一時レポートを `$TMPDIR/ai-dlc/<phase>-<step>-<purpose>.md` に書き出す**（Report-Based Confirmation 原則）
  3. ユーザーにレポートのパスを案内し、口頭で要点を補足する
  4. ユーザー判断を受けて作業を再開。一時レポートは Retrospective で参照可能にする（ただし最終成果物には含めない）
- **Main 判定ゲート**: Main が Exit Criteria の各項目を照合し、通過可否を決定。判定結果は進捗記録に反映し、ユーザー確認は不要

### 4. Blocker 発生時

1. Specialist が Blocker を検知 → **作業を中断して Main に報告**（独断で回避策を試さない）
2. Main は以下のいずれかを選択:
   - 前ステップに戻る（設計不足、意図不明確等）
   - 並列 Specialist を追加起動（別観点の調査等）
   - ユーザーに判断を仰ぐ（**In-Progress ユーザー問い合わせ**形式で一時レポート作成）
3. `progress.yaml` の `blockers` に追記してコミット

### 5. セッション再開時

別セッション／別ユーザーが中断済みサイクルを再開する手順。

1. `docs/ai-dlc/<identifier>/progress.yaml` を読み込む
2. `current_step` / `completed_steps` / `pending_gates` / `active_specialists` / `blockers` を確認
3. 既存成果物ファイル（`intent-spec.md` / `research/*.md` / `design.md` / `task-plan.md` / `TODO.md` / その他）を全て読み込み、文脈を再構築
4. **Construction フェーズを再開する場合**: `TODO.md` を読み込み、`TaskCreate` で内部タスクリストを**完全復元**する
   - `[x] completed` → TaskUpdate で `completed` 状態に
   - `status: in_progress` のタスク → `pending` に戻す（前セッションの `implementer` は役割終了済みのため、該当 `implementer` を新規起動し直すまで `pending` 扱い）
   - TODO.md と TaskCreate に齟齬があれば **TODO.md を正**として修正してコミット
5. **前セッションの Specialist は全て役割終了扱い**とする（`active_specialists` に `running` があっても、セッション跨ぎでの再利用は禁止のため）
6. 現在の `current_step` を継続する場合は、新規 Specialist を起動して当該ステップを再活性化
7. `blockers` があればユーザーに再提示し、対応方針を確認（**In-Progress ユーザー問い合わせ**形式）
8. `progress.yaml` の `updated_at` を更新してコミット（再開マーカー）

---

## 成果物テンプレート・保存構造・進捗記録フォーマット

本プラグインでは**成果物仕様を `shared-artifacts` スキルに集約**することで、Main / Specialist / ユーザーの全ステークホルダーが同じ真のソースを参照できるようにしている。これにより、テンプレートと書き方ガイドの 1:1 対応が担保され、仕様変更時の更新漏れを防げる（詳細な設計判断は本サイクル付随の `design.md` の「代替案と採用理由」表を参照）。

Main は以下を参照する:

- **成果物一覧とテンプレートパス**: `shared-artifacts` SKILL.md の「成果物一覧（目次）」
- **ディレクトリ構造**（`docs/ai-dlc/<identifier>/` 配下）: `shared-artifacts` SKILL.md の「成果物保存構造」
- **`<identifier>` の命名ルール**: `shared-artifacts` SKILL.md の「`<identifier>` の命名ルール」
- **サイクル外成果物**（プロジェクト横断 ADR、一時レポート）: `shared-artifacts` SKILL.md の「サイクル外の成果物」
- **各成果物の書き方**: `shared-artifacts/references/<name>.md`（1:1 対応）
- **`progress.yaml` のスキーマ・書き方**: `shared-artifacts/references/progress-yaml.md`
- **`design.md` と ADR の使い分け**: `shared-artifacts/references/design.md`
- **`TODO.md` と内部タスクリストの同期**: `shared-artifacts/references/todo.md`

Specialist 起動時、Main はテンプレートパス (`shared-artifacts/templates/<name>.md`) と reference パス (`shared-artifacts/references/<name>.md`) の**両方を入力に含める**こと。Specialist はテンプレートを埋める際、必ず対応する reference を参照する。

---

## プロジェクト固有ルールとの関係

本プラグインの AI-DLC ワークフローは**汎用的なプロセス構造**を提供する。一方で、個別プロジェクトは固有の規約・スキルを持つことが多く、これらは AI-DLC の抽象的ルールよりも**具体的でプロジェクトの現実に即している**。以下の使い分けを原則とする。

### AI-DLC に従う領域（プロセス構造）

- 3 フェーズ構成（Inception / Construction / Verification）
- 各フェーズの Step 分割とゲート判定
- Main / Specialist の役割分離と起動プロトコル
- 成果物形式（`intent-spec.md` / `design.md` / `task-plan.md` / `TODO.md` / 各種 Report / `retrospective.md`）
- ユーザー承認ゲート・In-Progress 問い合わせの使い分け
- ステップ完了時のコミット規約（1 ステップ = 1 コミット、Implementation のみタスク単位）
- サイクル作業ディレクトリ `docs/ai-dlc/<identifier>/` のレイアウト

### プロジェクト固有ルールを優先する領域（作業内容）

- **実装パターン**: 言語・フレームワーク・ライブラリ固有の書き方（例: `effect-layer`, `effect-hono`, `effect-runtime`, `totto2727-fp` 等のプロジェクト固有スキル）
- **テストルール**: テスト基盤、モック戦略、カバレッジ要件、E2E 判定基準
- **コードレビュー観点**: セキュリティ・パフォーマンス・可読性の各基準値
- **コミット規約 / ブランチ戦略**: プロジェクトの `git-workflow` スキル、Conventional Commits のスコープ命名、GPG 署名要件
- **設計規約**: 採用する設計パターン（関数型 / OOP）、エラーモデル、依存注入手法
- **命名規則・ディレクトリ構造**: プロジェクトの慣習
- **プラットフォーム固有コマンド**: macOS の `gsed`/`ggrep` 等（`macos-cli-rules`）

### 適用手順

Main / Specialist は各ステップ開始前に以下を確認する:

1. プロジェクトの CLAUDE.md を読んで AI-DLC と整合するルール・禁止事項を把握
2. プロジェクトのスキル一覧を確認（`plugins/<project>/skills/` 配下等）
3. 該当ステップで関連するプロジェクト固有スキル（例: 実装なら `effect-layer`、コミットなら `git-workflow`）を特定し、Specialist 起動時の入力に含める
4. AI-DLC のデフォルト手順とプロジェクト固有ルールを比較:
   - **整合している** → 両者を併用
   - **プロジェクト固有が AI-DLC を具体化している** → プロジェクト固有に従う
   - **明確に矛盾している** → **作業を中断し、In-Progress ユーザー問い合わせ形式でユーザーに判断を仰ぐ**（独断で片方に寄せない）

### 矛盾の判定例

| ケース                                                                 | 解決                                                                          |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| AI-DLC は任意のコード設計を許容、プロジェクトは Effect Layer 必須      | プロジェクト優先（`effect-layer` スキルに従う）                              |
| AI-DLC の Self-Review は汎用観点、プロジェクトに固有のレビュー観点あり  | 両方併用（汎用観点 + プロジェクト固有観点）                                   |
| AI-DLC は `docs(ai-dlc/...)` コミット規約、プロジェクトは独自のスコープ規約 | 独自スコープ規約と折衷（`docs(ai-dlc/<id>,project-scope): ...` 等）を提案しユーザー判断 |
| AI-DLC の task 粒度「1 日以内」、プロジェクト規約が「1 PR = 複数週」   | **矛盾** → ユーザー判断（別サイクルに分割するか、粒度を妥協するか）           |
| AI-DLC は `docs/ai-dlc/` 直下、プロジェクトが `doc/specs/` を使う        | **軽微な矛盾** → プロジェクトに合わせて `doc/ai-dlc/` 等に調整、ユーザー承認   |

### Specialist への伝達

Main は Specialist 起動時に**関連するプロジェクト固有スキルのパス**を入力に含めること。`specialist-common` の入力契約に従って、参照すべきスキル一覧が明示されない場合は Specialist 側から Main に問い合わせる。

---

## ステップ完了時のコミット規約

各ステップが完了した時点で、そのステップで生成・更新された成果物は**必ずリポジトリにコミット**する。次のステップを開始する時点では、一時ファイル（`$TMPDIR/ai-dlc/*.md`）を除いて差分が存在しない状態が期待される。

### 原則

- **1 ステップ = 1 コミット**（Implementation を除く）
- **Implementation のみタスク単位で複数コミット**（task-plan の粒度に従う）
- コミットに含めるのは**成果物ファイル + `progress.yaml` + `TODO.md`**（該当する場合）
- 一時ファイル（`$TMPDIR/` 配下）は**決してコミットしない**
- プロジェクト横断 ADR を起票した場合は、該当 ADR ファイルも同じコミットに含めてよい（`design.md` の更新とセットで）

### フェーズ別コミット内訳

#### Inception（各ステップ 1 コミット）

| Step                         | コミット内容                                                              |
| ---------------------------- | ------------------------------------------------------------------------- |
| 1. Intent Clarification      | `intent-spec.md` + `progress.yaml`                                        |
| 2. Research                  | `research/*.md`（全観点まとめて）+ `progress.yaml`                        |
| 3. Design                    | `design.md` + `progress.yaml`（+ 起票した場合のみ ADR 本体）             |
| 4. Task Decomposition        | `task-plan.md` + `progress.yaml`                                          |

サイクル開始時に追加の初回コミット: `docs/ai-dlc/<identifier>/` ディレクトリ作成 + `progress.yaml` 初期化。

#### Construction（Step 5 のみ複数コミット、Step 6 は 1 コミット）

**Step 5 (Implementation):**

- **タスクごとに 1 コミット**（task-plan の粒度に従う）
- 各コミット内容: 該当タスクの実装 diff + `TODO.md` の該当タスク状態更新 + `progress.yaml`
- 必要な場合のみ `implementation-logs/<task-id>.md` も追加
- 並列 `implementer` が独立タスクを実装している場合でも、**コミットは 1 タスク単位**（他タスクの進行中 diff が混ざらないよう注意）
- Self-Review High 指摘で再実装する場合、**修正コミットも別途作成**（amendしない、通常の新規コミットで追記）

**Step 6 (Self-Review):**

- 1 コミットで `self-review-report.md` + `progress.yaml`
- High 指摘があれば Step 5 に戻ってタスク修正コミット → 再 Self-Review コミット、とループ

#### Verification（各ステップ 1 コミット）

| Step                | コミット内容                                                             |
| ------------------- | ------------------------------------------------------------------------ |
| 7. External Review  | `review/*.md`（全観点まとめて）+ `progress.yaml`                         |
| 8. Validation       | `validation-report.md` + `validation-evidence/*`（ある場合）+ `progress.yaml` |
| 9. Retrospective    | `retrospective.md` + `progress.yaml`（最終コミット、`phase: Completed`） |

### ユーザー承認ゲート通過時

承認結果を `progress.yaml.user_approvals` に反映してコミット。以下のいずれかのタイミングで:

- 該当ステップ完了コミットと同時（承認が即時の場合）
- ステップ完了コミット後の別コミット（承認ゲートでユーザー判断待ちの時間がある場合）

### コミットメッセージ規約

プロジェクト固有の規約（`git-workflow` スキル等）があればそれを優先。該当がない場合の推奨形式:

```
docs(ai-dlc/<identifier>): complete Step <N> (<StepName>)
docs(ai-dlc/<identifier>): record user approval for Step <N>
docs(ai-dlc/<identifier>): initialize cycle
feat(ai-dlc/<identifier>/task-<id>): <task summary>   # Step 5 Implementation
docs(ai-dlc/<identifier>): close cycle with retrospective
```

### コミット前チェック

各ステップ完了時、Main は以下を順に実行する:

1. 該当ステップの Exit Criteria が満たされているか確認
2. 成果物ファイルが `docs/ai-dlc/<identifier>/` 配下に全て配置されているか
3. `progress.yaml` の `completed_steps` / `artifacts` / `updated_at` を更新
4. `git status` で想定したファイルのみが変更されているか確認
5. `git add` は**明示的にファイルを指定**（`.` や `-A` は一時ファイルを巻き込むリスクあり）
6. `git commit` で規約に従ったメッセージで記録

### 一時ファイルの扱い

- 一時レポート（`$TMPDIR/ai-dlc/*.md`）は**そもそも `docs/ai-dlc/<identifier>/` 外に存在する**ためコミット対象にならない
- `.gitignore` で `$TMPDIR` 配下を明示する必要はない（絶対パスで分離されているため）
- サイクル完了時に `$TMPDIR/ai-dlc/<cycle>-*.md` を残す / 削除するかはプロジェクト方針に従う（Retrospective 分析に使うなら残す、機密情報を含むなら削除）

---

## フェーズ遷移時の引き継ぎ

フェーズ間の遷移では、**次フェーズスキルに必要な入力成果物が揃っているか**を Main が確認する。

| 遷移                        | 必須入力成果物                                                                                    | 確認方法                     |
| --------------------------- | ------------------------------------------------------------------------------------------------- | ---------------------------- |
| Inception → Construction    | `intent-spec.md` / `design.md` / `task-plan.md`                                                   | ファイル存在 + ユーザー承認  |
| Construction → Verification | Git コミット済み diff / `TODO.md`（全完了）/ `self-review-report.md`                             | Main 判定（High 指摘 0）     |
| Verification → 完了         | `review/*.md` / `validation-report.md` / `retrospective.md`                                       | ユーザー承認                 |

遷移直前に Main は該当フェーズスキルを参照し直し、`progress.yaml` の `phase` を更新してコミットしたうえで、次フェーズの初期ステップを起動する。

---

## 逸脱時のリカバリ

### ユーザーが途中でスコープを変更した

1. Main は変更内容を進捗記録に反映し、影響範囲を評価
2. 必要なら Inception の Step 1（Intent Clarification）まで戻す
3. 既存成果物は破棄せず、Retrospective で再利用可能性を検討

### Specialist が期待外の成果物を返した

1. Main は成果物をそのまま進捗記録に残す（隠蔽しない）
2. 不足・逸脱内容を明示して、**既存の同一 Specialist にフィードバックを差し戻し**再試行させる（ステップ完了前に Specialist を終了させない）
3. スコープが拡大した場合に限り、**追加の Specialist を並列起動**（既存 Specialist は終了させず維持）
4. フィードバックを数周繰り返しても改善しない場合は、前ステップに戻すかユーザー判断を仰ぐ（それでも現ステップの Specialist は終了させず、ステップを抜ける時点で役割終了となる）

### フェーズ跨ぎで整合性が崩れた

1. Main は該当フェーズスキルの Exit Criteria を再確認
2. 満たされていない Criteria に対応する前フェーズの該当ステップまでロールバック
3. ロールバック範囲と再実行計画をユーザーに **In-Progress ユーザー問い合わせ**形式（一時レポート）で提示して判断を仰ぐ

---

## このスキルが扱わないこと

- 各フェーズの詳細手順 → `main-inception` / `main-construction` / `main-verification` スキルに委譲
- 各 Specialist の作業詳細 → `specialist-*` スキル（役割別）と `specialist-common`（横断ルール）に委譲
- 各 Specialist をサブエージェントとして起動する際のエントリポイント定義 → `agents/*.md`
- プロジェクト全体に及ぶ横断的な意思決定の記録 → `adr` スキルに委譲（本ワークフロー内でサイクルを跨いで影響する決定が発生した場合のみ使用。Design Document の代替にはならない）
- 個別の Specialist のプロンプト詳細 → 将来的に agents/ 配下で定義
- ツール固有のコマンド → プロジェクト固有のスキル（`effect-layer` 等）に委譲
- ワークフロー外の単発修正 → 通常の会話で処理

---

## 起動テスト観点（Triggering 例）

Main が本スキルを起動すべき / すべきでない典型例。description のトリガー語と対応する。

**Should trigger:**

- 「ai-dlc で新機能を設計から実装まで進めたい」→ 全フェーズの司令塔として起動
- 「この要求を AI-DLC フローで回してほしい」→ Inception から開始
- 中断済みサイクルの再開依頼（`docs/ai-dlc/<identifier>/` が既存）→ 「5. セッション再開時」プロトコルへ

**Should NOT trigger:**

- 「Inception フェーズだけやり直したい」→ `main-inception` を直接参照
- 「実装タスクだけ並列で走らせたい」→ `main-construction` を直接参照
- 「設計ドキュメントの書き方を知りたい」→ `shared-artifacts` を参照
- 「単発のバグ修正」→ 通常の会話で処理（サイクルを起こさない）
