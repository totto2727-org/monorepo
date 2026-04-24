---
name: main-inception
description: >
  [Main 用] AI-DLC Phase 1 (Inception) の詳細実行手順を定義する。
  意図明確化・調査・設計・タスク分解の 4 ステップを Specialist 起動仕様付きで提供する。
  ユーザー要求を Intent Spec / Research Notes / Design Document / Task Plan へと変換し、
  実装可能な計画を承認ゲートまで導く。
  起動トリガー: "Inception フェーズを開始", "意図明確化", "要求定義", "設計フェーズ",
  "タスク分解", "ai-dlc の inception"。
  Do NOT use for: ai-dlc ワークフロー全体の管理（main-workflow スキルを使う）、
  実装・レビュー・検証フェーズ（main-construction / main-verification スキルを使う）、
  Specialist 側の作業詳細（specialist-* スキルを使う）、フェーズを跨いだ意思決定。
metadata:
  author: ai-dlc
  version: 1.0.0
---

# AI-DLC Phase 1 — Inception

ユースケースカテゴリ: **Workflow Automation**
設計パターン: **Sequential Workflow**（Step 1 → 2 → 3 → 4 のゲート付き順次実行）

Inception フェーズは、ユーザー要求を**実装可能な計画**に変換する。
意図を言語化し、前提を調査し、設計を確定し、タスクに分解する。出力はユーザー承認を得た `Task Plan` であり、これが Construction フェーズの入力となる。

**このスキルは `main-workflow` スキル配下で使用される。** `main-workflow` の基本方針・役割定義・調整プロトコル・ユーザー承認ゲート規則（Artifact-as-Gate-Review / Report-Based Confirmation for In-Progress Questions の区別）をすべて継承する。各 Specialist の作業詳細は `specialist-*` スキルに定義されている。

## フェーズ全体

| 項目         | 内容                                                                                                |
| ------------ | --------------------------------------------------------------------------------------------------- |
| 入力         | ユーザー要求 / 現在のリポジトリ状態                                                                 |
| 成果物       | `intent-spec.md` / `research/<topic>.md` / `design.md` / `task-plan.md`（プロジェクト横断の意思決定があれば ADR も別途起票） |
| 保存先       | `docs/ai-dlc/<identifier>/` 配下（`<identifier>` はサイクル開始時にユーザーと合意した命名）         |
| 出口ゲート   | ユーザー承認（Task Plan に基づく実装開始の合意）                                                    |
| 想定ステップ | 1. Intent Clarification → 2. Research → 3. Design → 4. Task Decomposition                           |
| ロールバック | スコープ変更時は Step 1 へ。設計破綻時は Step 3 へ。前提不足時は Step 2 へ戻る                      |

**コミット方針:** 各ステップ完了時に成果物と `progress.yaml` を追加／更新してコミット（詳細は `main-workflow` スキルの「成果物保存構造」参照）。

**対応エージェント・スキル・成果物:**

| Step                    | Agent                   | Specialist Skill               | 成果物（書き方 / テンプレート）                                                                             |
| ----------------------- | ----------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| 1. Intent Clarification | `intent-analyst`        | `specialist-intent-analyst`    | `shared-artifacts/references/intent-spec.md` / `shared-artifacts/templates/intent-spec.md`                 |
| 2. Research             | `researcher` (並列 N)   | `specialist-researcher`        | `shared-artifacts/references/research-note.md` / `shared-artifacts/templates/research-note.md`             |
| 3. Design               | `architect`             | `specialist-architect`         | `shared-artifacts/references/design.md` / `shared-artifacts/templates/design.md`                           |
| 4. Task Decomposition   | `planner`               | `specialist-planner`           | `shared-artifacts/references/task-plan.md` / `shared-artifacts/templates/task-plan.md`                     |

Specialist 起動時には **reference（書き方ガイド）とテンプレートの両方のパス**を入力に含めること。各 Specialist は `specialist-common`（横断ルール）と上記の個別スキルを参照する。

---

## Step 1: Intent Clarification（意図明確化）

**目的:** ユーザーが本当に解きたい問題を言語化し、スコープ・制約・成功基準を確定する

**起動する Specialist:** `intent-analyst` × 1

**Main の作業:**

1. `intent-analyst` を起動し、以下を入力として渡す:
   - 初期ユーザー要求（会話履歴から抜粋）
   - 現在のリポジトリ状態の要約
2. `intent-analyst` の質問を受け取り、ユーザーに提示
3. ユーザー回答を `intent-analyst` に戻し、Intent Spec を確定させる
4. **確定した Intent Spec そのものをユーザーに提示**して承認を得る（一時レポートは作成しない。成果物がそのまま承認材料）

**Specialist の成果物:**

- `docs/ai-dlc/<identifier>/intent-spec.md`
  - 内容: 背景 / 目的 / スコープ / 非スコープ / 成功基準 / 制約

**Exit Criteria:**

- スコープと非スコープが明文化されている
- 成功基準が観測可能な形式で記述されている（「速くなる」ではなく「p95 < 200ms」等）
- ユーザーが Intent Spec に同意済み
- `intent-spec.md` がコミット済み、`progress.yaml` の `completed_steps` に追記済み

**Gate:** ユーザー承認必須

**失敗時の挙動:**

- ユーザー回答が曖昧で Intent Spec が確定しない → **同じ `intent-analyst` インスタンスに追加質問を指示**し対話を継続（Step 1 完了まで同一インスタンスを維持）
- 成功基準が観測不能 → ユーザーに計測手段を相談して再定義（`intent-analyst` はそのまま維持）

---

## Step 2: Research（調査）

**目的:** 既存コード・既存設計・外部制約を把握し、設計の前提を揃える

**起動する Specialist:** `researcher` × N（観点ごとに並列）

**Main の作業:**

1. Intent Spec から調査観点を導出する（例: 既存実装、依存関係、類似事例、既存 ADR、外部仕様）
2. 観点ごとに `researcher` を **並列起動**（各々に固有のスコープと成果物フォーマットを指定）
3. 全 Researcher の成果物を集約し、Exit Criteria を判定
4. 未解決の不明点があれば Blocker として進捗記録に反映

**Specialist の成果物:**

- 観点ごとに `docs/ai-dlc/<identifier>/research/<topic>.md`
  - 内容: 対象 / 発見事項 / 引用元 / 設計への含意
  - `<topic>` 例: `existing-impl`, `dependencies`, `similar-cases`, `external-spec`

**Exit Criteria:**

- Intent Spec で示された制約が裏付けされている
- 既存実装との接続点・衝突点が列挙されている
- 未解決の不明点が Blocker として明示されている（残っても良いが記録する）
- 全 Research Note がコミット済み、`progress.yaml` に反映

**Gate:** Main 判定のみ（ユーザー確認は任意。重大な Blocker がある場合のみ In-Progress ユーザー問い合わせ形式で一時レポートを作成し判断を仰ぐ）

**失敗時の挙動:**

- Research Note の粒度が不足 → **既存の `researcher` インスタンスに深掘り指示を差し戻す**（同一インスタンスを維持）
- 観点自体が不足していた → `researcher` を**追加並列起動**（既存インスタンスは終了させず維持）
- 既存実装と Intent Spec が根本的に矛盾 → Step 1 へロールバックし Intent Spec を修正（Step 2 を抜ける時点で全 `researcher` の役割終了）

---

## Step 3: Design（設計）

**目的:** アーキテクチャと実装アプローチを体系的に設計し、**設計ドキュメント**を作成する

**起動する Specialist:** `architect` × 1

**プロジェクト固有ルールの適用:** 設計規約（関数型 / OOP、依存注入手法、エラーモデル等）は該当プロジェクトのスキル（例: `effect-layer`, `effect-runtime`, `effect-hono`, `totto2727-fp`）を優先する。Main は `architect` 起動時に該当スキルのパスを入力に含めること。AI-DLC の汎用構造と矛盾する場合は `main-workflow` の「プロジェクト固有ルールとの関係」に従いユーザー判断を仰ぐ。

**Main の作業:**

1. `architect` に Intent Spec と Research Notes、および**関連するプロジェクト固有の設計スキルのパス**を渡して起動
2. `architect` が生成した設計ドキュメントを受け取り、**そのドキュメント自体をユーザーに提示**してフィードバックを得る（一時レポートは作成しない）
3. ユーザーのフィードバックを `architect` に戻し、設計ドキュメントを反復して改善させる（同一インスタンスを継続使用）
4. 確定版の設計ドキュメントを `docs/ai-dlc/<identifier>/design.md` に保存・コミット
5. 設計アプローチの選定でユーザー判断が必要な場面（複数候補の優劣が拮抗する等）では、**In-Progress ユーザー問い合わせ形式**で一時レポートを作成して判断を仰ぐ（この場合は設計ドキュメント確定前の意思決定段階）
6. **サイクル中に「プロジェクト全体に及ぶ横断的な意思決定」が発生した場合のみ**、`adr` スキルを使って別途 ADR を起票（詳細は後述「ADR の起票条件」）

**Specialist の成果物:**

- `docs/ai-dlc/<identifier>/design.md`（設計ドキュメント本体）
  - 内容:
    - 設計目標と制約（Intent Spec からの引用）
    - アプローチの概要
    - コンポーネント構成 / 主要な型・インターフェース
    - データフロー / API 設計
    - 代替案の比較表（採用案 / 却下案 / 理由）
    - 想定される拡張ポイント
    - 運用上の考慮事項（監視、移行、ロールアウト等）
    - （該当する場合）プロジェクト横断 ADR へのリンク

**Exit Criteria:**

- `design.md` + `progress.yaml` がコミット済み（プロジェクト横断 ADR を起票した場合は ADR 本体も同コミットに含める）
- 主要な設計判断について代替案と採用理由が記録されている
- ユーザーが設計方針に同意済み
- コミット後、**次ステップ着手時に一時ファイル以外の差分がない状態**

**Gate:** ユーザー承認必須

**失敗時の挙動:**

- 設計案がユーザーの意図と乖離 → **同じ `architect` インスタンス**にユーザーフィードバックを戻し再検討させる。根本乖離なら Step 1 へロールバック（Step 3 を抜ける時点で `architect` の役割終了）
- Research Notes が設計判断を支えきれない → Step 2 へロールバック（現 `architect` はそのまま維持し、追加 Research Notes の到着を待つ）

### ADR の起票条件（補足）

`design.md` とは別に ADR を起票するのは、**サイクル内で発生した意思決定がプロジェクト全体に及ぶ場合に限る**。

| 起票する（プロジェクト横断）             | 起票しない（サイクル内完結）                      |
| ---------------------------------------- | ------------------------------------------------- |
| 「プロジェクト全体で Effect を採用する」 | 「この機能のキャッシュ戦略を LRU にする」         |
| 「全サービスで gRPC を使う」             | 「この API のページネーションは cursor 型にする」 |
| 「認可レイヤを OpenFGA に統一する」      | 「この画面のバリデーションは zod で書く」         |

**判定基準:**

- 他の機能・他のチーム・将来のサイクルにも影響するか？ → YES なら ADR
- 本サイクル内で完結する判断か？ → YES なら `design.md` 内にとどめる

ADR を起票した場合:

1. `adr` スキルを使ってプロジェクト既存の ADR 格納場所に起票
2. ADR のパスを `progress.yaml` の `artifacts.external_adrs` に追記
3. `design.md` から該当 ADR にリンクを張る

---

## Step 4: Task Decomposition（タスク分解）

**目的:** 設計ドキュメントを実装可能な粒度のタスクに分解し、並列性と依存関係を明示する

**起動する Specialist:** `planner` × 1

**Main の作業:**

1. `planner` に `design.md` と Intent Spec を渡して起動
2. 生成された Task Plan の粒度・順序・並列性を Main が検証
3. 不十分なら **同じ `planner` インスタンス**に不足点を差し戻して再分解させる（Step 4 完了まで同一インスタンスを維持）
4. **確定版 Task Plan そのものをユーザーに提示**して実装開始の承認を得る（一時レポートは作成しない）

**Specialist の成果物:**

- `docs/ai-dlc/<identifier>/task-plan.md`
  - 内容: タスク ID / 概要 / 成果物 / 依存関係 / 並列可否 / 見積り規模

**Exit Criteria:**

- 各タスクが 1 人の Implementer で完遂可能な粒度
- タスク間の依存関係がグラフとして明示されている
- 並列実行可能なタスク群が識別されている
- `task-plan.md` + `progress.yaml` がコミット済み
- コミット後、**次ステップ着手時に一時ファイル以外の差分がない状態**

**Gate:** ユーザー承認必須（実装開始の合意）

**失敗時の挙動:**

- タスクが粗すぎる・細かすぎる → **同じ `planner` インスタンス**に粒度基準を明示して再分解を指示
- 依存関係が解決不能 → Step 3 に戻り `design.md` を見直す（Step 4 を抜ける時点で `planner` の役割終了）

---

## フェーズ出口チェックリスト

Construction フェーズへ遷移する前に、Main は以下を確認する。

- [ ] `docs/ai-dlc/<identifier>/intent-spec.md` が確定済み・コミット済み（Step 1 でユーザー承認）
- [ ] `docs/ai-dlc/<identifier>/research/*.md` が観点網羅でコミット済み（Step 2 で Main 判定）
- [ ] `docs/ai-dlc/<identifier>/design.md` が作成済み・ユーザー承認済み・コミット済み（Step 3）
- [ ] プロジェクト横断の意思決定があった場合は、ADR が既存 ADR 格納場所に起票済みで `progress.yaml` の `artifacts.external_adrs` に記録済み
- [ ] `docs/ai-dlc/<identifier>/task-plan.md` が確定済み・ユーザー承認済み（Step 4）
- [ ] 未解決の Blocker が `progress.yaml` の `blockers` に明示されている（ゼロであること必須ではない）
- [ ] `progress.yaml` の `phase` を Construction に更新してコミット

全項目チェック後、`main-construction` スキルへ移行する。

---

## 並列起動のガイドライン（Inception 固有）

| ステップ             | 並列起動推奨度 | 並列軸                                 |
| -------------------- | -------------- | -------------------------------------- |
| Intent Clarification | 低             | 単一 Specialist で対話ループ           |
| Research             | 高             | 調査観点ごと（既存実装 / 依存 / 事例） |
| Design               | 低             | 設計は一貫性が重要なので原則 1 名      |
| Task Decomposition   | 低             | 全体俯瞰が必要なので 1 名              |

---

## このスキルが扱わないこと

- ワークフロー全体の管理 → `main-workflow` スキル
- 実装・自己レビュー → `main-construction` スキル
- 外部レビュー・検証・振り返り → `main-verification` スキル
- 各 Specialist の作業詳細 → `specialist-*` スキル（`specialist-common` + 役割別）
- プロジェクト横断の意思決定記録（ADR）の記法 → `adr` スキル（サイクル内で発生した場合のみ併用）
