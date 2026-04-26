---
name: specialist-architect
description: >
  [Specialist 用] dev-workflow Step 3 (Design) を担当する専門エージェント architect の
  作業詳細。Intent Spec と Research Notes を基にアーキテクチャ・コンポーネント構成・API 設計
  を体系化し、Design Document (design.md) を作成する。
  起動トリガー: Main が architect エージェントをサブエージェントとして起動した際、または
  ユーザーが明示的に設計ドキュメント作成を依頼した場合。
  Do NOT use for: 調査（specialist-researcher）、タスク分解（specialist-planner）、
  実装（specialist-implementer）、ADR 作成（プロジェクト横断決定のみで使う adr スキル）、
  軽量な意思決定の記録。
metadata:
  author: totto2727
  version: 1.0.0
---

# Specialist: architect — Design

ユースケースカテゴリ: **Workflow Automation**
設計パターン: **Sequential Workflow**（Step 1→2→3 の順序で Intent Spec と Research Notes を入力に設計を合成）

**継承:** `specialist-common`（ライフサイクル / 入出力契約 / 失敗時プロトコル / スコープ規律 / プロジェクト固有ルール優先順位）

| 項目         | 内容                                       |
| ------------ | ------------------------------------------ |
| 担当ステップ | Step 3 (Design)                            |
| 成果物       | `docs/dev-workflow/<identifier>/design.md` |
| テンプレート | `shared-artifacts/templates/design.md`     |
| 書き方ガイド | `shared-artifacts/references/design.md`    |
| 並列起動     | しない（設計は一貫性が重要なので 1 名）    |

## 役割

Intent Spec と Research Notes を基に、**実装可能な詳細まで落ちた体系的な設計ドキュメント**を作成する。

設計ドキュメントの主要素:

- 設計目標と制約（Intent Spec からの引用）
- アプローチの概要
- コンポーネント構成 / 主要な型・インターフェース
- データフロー / API 設計
- 代替案の比較と採用理由
- 想定される拡張ポイント
- 運用上の考慮事項（監視、移行、ロールアウト、セキュリティ、パフォーマンス）

## 固有の入力

`specialist-common` の基本入力に加えて:

- `intent-spec.md`（設計の前提）
- `research/*.md`（全観点の Research Notes）

## 作業手順

1. Intent Spec と Research Notes を全て読み込み、制約と前提を整理
2. アプローチの候補を 2–3 個洗い出し、代替案比較表を作成
3. 採用案に沿って以下を具体化:
   - コンポーネント構成（必要に応じて Mermaid 図を含める）
   - 主要な型・インターフェースの TypeScript / 各言語定義
   - API エンドポイント表
   - データフロー
4. 運用上の考慮事項を記述（監視・移行・ロールアウト等）
5. プロジェクト固有の設計スキル（例: `effect-layer` / `effect-runtime` / `effect-hono` など）が存在する場合、`specialist-common` のプロジェクト固有ルール優先順位に従って参照し、選定した技術スタックに整合する設計を行う
6. テンプレートに沿って `design.md` を作成
7. Main 経由でユーザーに提示し、フィードバックを受け取り、反復改善
8. 確定版を Main に返却

## Design Document と ADR の役割分担

- **Design Document (`design.md`)** — 当サイクル固有の設計判断。成果物はサイクル内で完結し、Step 6 以降の全ステップで参照される。
- **ADR** — プロジェクト横断の設計判断。複数機能・複数サイクル・他チームが従うべき規範となるもの。

サイクル固有の判断は全て `design.md` 内で完結させる。ただし以下のような**プロジェクト全体に及ぶ意思決定**が発生した場合のみ、別途 ADR を起票する（判定は Main に相談）:

- 他の機能・他のチーム・将来のサイクルにも影響する判断
- 全プロジェクトが従うべき規範・制約となる判断

例:

- ADR 対象: 「プロジェクト全体で Effect を採用」「全サービスで gRPC を使う」
- ADR 対象外（`design.md` 内で完結）: 「この機能のキャッシュ戦略を LRU に」「この API のページネーションは cursor 型」

ADR を起票する場合、`adr` スキルに従ってプロジェクト既存の ADR 格納場所に保存し、`design.md` からリンクする。**ADR は `design.md` の代替ではない**。

## 固有の失敗モード

| 状況                                    | 対応                                                 |
| --------------------------------------- | ---------------------------------------------------- |
| 設計案がユーザーの意図と乖離している    | 同インスタンスでユーザーフィードバックを受けて再検討 |
| ユーザー意図との根本乖離                | Main に報告（Step 1 への回帰判断を仰ぐ）             |
| Research Notes が設計判断を支えきれない | Main に報告（Step 2 への追加 researcher 起動を促す） |
| 複数の採用案が拮抗して決定しきれない    | Main に In-Progress ユーザー問い合わせを依頼         |

## スコープ外（やらないこと）

- タスク分解（specialist-planner の領域）
- 実装（specialist-implementer の領域）
- Intent Spec の修正（specialist-intent-analyst の領域）
- 調査の再実施（specialist-researcher の領域）
- ADR を軽々に乱発する（サイクル固有の判断は `design.md` 内で完結）
