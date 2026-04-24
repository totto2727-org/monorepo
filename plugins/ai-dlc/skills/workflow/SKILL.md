---
name: workflow
description: >
  AI-DLC (AI-Driven Development Lifecycle) の全体ワークフローを管理する。
  Main が進捗管理とエージェント起動を兼ね、Inception → Construction → Verification の
  3フェーズを順次実行する。各フェーズの詳細は個別スキル (inception / construction / verification)
  に委譲する。
  起動トリガー: "ai-dlc を開始", "開発ワークフローを実行", "新機能を ai-dlc で進める",
  "AI 駆動開発ライフサイクル", "AI-DLC フローで設計から実装まで"。
  Do NOT use for: 単一フェーズのみの実行（該当フェーズスキルを直接使う）、
  単発のコード修正、ワークフロー外の単発作業。
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
- **Commit-Based Resumability**: サイクルの成果物と進捗記録は `docs/ai-dlc/<identifier>/` に集約し、**各ステップ完了時にコミット**する。これにより別セッション／別ユーザーがコミットを取得して作業を再開できる（詳細は後述「成果物保存構造」参照）
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

**詳細スキル:** `inception` — 以下 4 ステップ
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

**詳細スキル:** `construction` — 以下 2 ステップ
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

**詳細スキル:** `verification` — 以下 3 ステップ
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
5. `inception` スキルを参照して Step 1 から着手する

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

## 成果物テンプレート

各成果物にはテンプレートが用意されている。Specialist を起動する際、Main は該当テンプレートへのパスを入力に含めること。プレースホルダは `{{name}}` 形式（将来的に EJS 等に移行する可能性あり）。

| 成果物                   | テンプレートパス                                                                      |
| ------------------------ | ------------------------------------------------------------------------------------- |
| progress.yaml            | `skills/workflow/templates/progress.yaml`                                             |
| intent-spec.md           | `skills/inception/templates/intent-spec.md`                                           |
| research/<topic>.md      | `skills/inception/templates/research-note.md`                                         |
| design.md                | `skills/inception/templates/design.md`                                                |
| task-plan.md             | `skills/inception/templates/task-plan.md`                                             |
| TODO.md                  | `skills/construction/templates/TODO.md`                                               |
| self-review-report.md    | `skills/construction/templates/self-review-report.md`                                 |
| implementation-logs/*.md | `skills/construction/templates/implementation-log.md`                                 |
| review/<aspect>.md       | `skills/verification/templates/review-report.md`                                      |
| validation-report.md     | `skills/verification/templates/validation-report.md`                                  |
| retrospective.md         | `skills/verification/templates/retrospective.md`                                      |

---

## 成果物保存構造（サイクル作業ディレクトリ）

AI-DLC の成果物および進捗記録は、**サイクルごとに独立したディレクトリに集約**してリポジトリにコミットする。これにより**作業の中断と再開**が可能になる（別のセッションが同一ディレクトリを読めば現在地を把握できる）。

### ディレクトリ構造

```
docs/ai-dlc/<identifier>/
├── progress.yaml              # 進捗記録（Main が各ターンで更新）
├── intent-spec.md             # Step 1 成果物
├── research/                  # Step 2 成果物（観点ごとにファイル分割）
│   ├── <topic-1>.md
│   ├── <topic-2>.md
│   └── ...
├── design.md                 # Step 3 成果物（設計ドキュメント本体）
├── task-plan.md               # Step 4 成果物（planner が生成したタスク分解）
├── TODO.md                    # Construction 進行中のタスク状態（完了/進行中/未着手を永続化）
├── self-review-report.md      # Step 6 成果物
├── review/                    # Step 7 成果物（観点ごとにファイル分割）
│   ├── security.md
│   ├── performance.md
│   └── ...
├── validation-report.md       # Step 8 成果物
└── retrospective.md           # Step 9 成果物
```

### `<identifier>` の命名ルール

プロジェクトごとに決める。使用候補:

- チケット ID（例: `JIRA-1234`, `issue-567`）
- 機能名（例: `user-auth-refactor`, `oauth-support`）
- 日付 + スラッグ（例: `2026-04-24-cache-layer`）

サイクル開始時に Main がユーザーと合意して決定する。命名ルールがプロジェクトで既に決まっていればそれを踏襲する。

### Design Document と ADR の使い分け

本ワークフローで作成する主な成果物は**設計ドキュメント（Design Document）**。`adr` スキルは**プロジェクト全体に及ぶ横断的な意思決定**に限定して使用する。

| 観点       | Design Document（本ワークフローで常に作成）                                                       | ADR（プロジェクト横断決定時のみ使用）                                                   |
| ---------- | ------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| 対象       | そのサイクルで扱う機能・チケットの設計                                                            | 1 機能・1 サイクルに収まらない、プロジェクト全体のアーキテクチャ決定                     |
| 目的       | 実装前の体系的な設計（アーキテクチャ、コンポーネント、API、データフロー、代替案の検討）           | 全プロジェクトが従うべき規範・制約の記録                                                 |
| 粒度       | 1 サイクル単位。構造的・詳細                                                                      | プロジェクト横断。凝縮された決定文                                                       |
| 保存場所   | `docs/ai-dlc/<identifier>/design.md`（サイクル作業ディレクトリ内）                                | プロジェクト既存の ADR 格納場所（例: `doc/adr/YYYY-MM-DD-title.md`）                     |
| 作成タイミング | Inception Step 3 で `architect` Specialist が必ず作成                                           | サイクル内で「プロジェクト全体に影響する決定」が発生した場合のみ別途起票                 |
| 例         | 「この機能のキャッシュ戦略を LRU にする」                                                         | 「プロジェクト全体で Effect を採用する」「全サービスで gRPC を使う」                     |

**運用ルール:**

- サイクル内の設計判断は **Design Document 内で完結**させる（個別の判断を ADR 化しない）
- サイクル中に**プロジェクト全体に影響する判断**が発生した場合のみ、`adr` スキルを使って別途起票する
  - 起票した ADR のパスを `progress.yaml` の `artifacts.external_adrs` に記録
  - Design Document からも該当 ADR にリンクを張る
- ADR は軽量な記録用なので、設計書本体の代替にはならない（両者は粒度と目的が違う）

Design Document の内容例:

- 設計目標と制約（Intent Spec からの引用）
- アプローチの概要
- コンポーネント構成 / 主要な型・インターフェース
- データフロー / API 設計
- 代替案の比較と採用理由
- 想定される拡張ポイント
- 運用上の考慮事項（監視、移行、ロールアウト等）

### 一時レポート（In-Progress Questions）との関係

`$TMPDIR/ai-dlc/<phase>-<step>-<purpose>.md` に作成される一時レポートは**コミットしない**。これらは作業途中の対話用で、Retrospective の題材になる情報のみが `retrospective.md` に要約として残る。

### コミット戦略

- サイクル開始時: `docs/ai-dlc/<identifier>/` を作成し、`progress.yaml` を初期化してコミット
- 各ステップ完了時: 該当する成果物ファイルを追加／更新し、`progress.yaml` を更新してコミット
- ユーザー承認ゲート通過時: 承認結果を `progress.yaml` に反映してコミット
- Retrospective 完了時: 最終コミットで `retrospective.md` を追加

**コミットメッセージ例:**

```
docs(ai-dlc/<identifier>): complete Step 3 (Design)
docs(ai-dlc/<identifier>): update progress after user approval
docs(ai-dlc/<identifier>): close cycle with retrospective
```

### 再開プロトコル

別セッション／別ユーザーが同じサイクルを再開する場合の手順:

1. `docs/ai-dlc/<identifier>/progress.yaml` を読み込む
2. `current_step` / `completed_steps` / `pending_gates` から現在地を把握
3. 既存成果物（intent-spec, research/, design, task-plan, etc.）を読み込み文脈を再構築
4. `active_specialists` が running のまま残っていれば、その Specialist は**前セッションと共に終了済み**と扱う。再開時は現在ステップの Specialist を新規起動する（ステップ完了後に役割終了する One-Shot Specialist 原則に従い、**セッションを跨いだ Specialist 再利用はしない**）
5. `blockers` を確認してユーザーに再提示

---

## 進捗記録フォーマット（`progress.yaml`）

Main は各ターンで以下の状態を明示的に保持し、`docs/ai-dlc/<identifier>/progress.yaml` に反映する。ステップ完了・ゲート通過・Blocker 発生のタイミングでコミットする。

```yaml
identifier: <サイクル識別子>
started_at: <ISO8601 タイムスタンプ>
updated_at: <ISO8601 タイムスタンプ>

phase: Inception | Construction | Verification | Completed
current_step: <ステップ番号と名称>
completed_steps:
  - step: <ステップ番号と名称>
    completed_at: <ISO8601>
    artifact: <成果物ファイル相対パス>
pending_gates:
  - <保留中のゲート（ユーザー承認待ち / Main 判定待ち）>

active_specialists:
  - name: <Specialist 種別>
    task: <割り当てタスク>
    status: running | completed | blocked
    started_at: <ISO8601>

blockers:
  - <未解決の Blocker>

artifacts:
  intent_spec: <intent-spec.md 相対パス>
  research:
    - <research/xxx.md>
  design: <design.md>
  external_adrs:  # サイクル外に起票したプロジェクト横断 ADR（該当サイクルで起票した場合のみ）
    - <doc/adr/YYYY-MM-DD-title.md>
  task_plan: <task-plan.md>
  todo: <TODO.md>
  self_review: <self-review-report.md>
  review:
    - <review/xxx.md>
  validation: <validation-report.md>
  retrospective: <retrospective.md>

user_approvals:
  - gate: <ゲート名>
    approved_at: <ISO8601>
    approved_by: <ユーザー識別子 or "user">
    notes: <メモ>

rollbacks:
  - from: <戻す前のステップ>
    to: <戻した先のステップ>
    reason: <理由>
    at: <ISO8601>
```

この状態をユーザーに定期的に共有することで、**サイクル全体の透明性**を保つ。同時にこのファイルは**セッション間の引き継ぎ情報源**として機能する。

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

- 各フェーズの詳細手順 → `inception` / `construction` / `verification` スキルに委譲
- プロジェクト全体に及ぶ横断的な意思決定の記録 → `adr` スキルに委譲（本ワークフロー内でサイクルを跨いで影響する決定が発生した場合のみ使用。Design Document の代替にはならない）
- 個別の Specialist のプロンプト詳細 → 将来的に agents/ 配下で定義
- ツール固有のコマンド → プロジェクト固有のスキル（`effect-layer` 等）に委譲
- ワークフロー外の単発修正 → 通常の会話で処理
