# Milestone: Persistence — Event Store + CQRS Skeleton + Plugin Contracts

- **Milestone ID:** ms-05-persistence-event-store
- **Roadmap ID:** feed-platform
- **Status:** planned
- **Created at:** 2026-05-04T00:00:00Z
- **Last updated:** 2026-05-04T00:00:00Z

## 目的

ロードマップ全体の中核となる**永続化基盤 (Event Source of Truth + CQRS)** を構築し、フィード共通データモデル / イベント追記専用ストア / プロジェクション (キャッシュ DB) / Read-Your-Write 整合戦略の骨格を成立させる。同時に、入力プラグイン契約 / 出力プラグイン契約のスケルトン (interface / trait / module 境界) を本マイルストーン内で先行確定し、後続の入出力プラグイン基盤マイルストーンが契約に従う参照アダプタ実装に専念できる土台を作る。

## 到達点 (定性)

- フィード共通データモデル (Feed / Item / 関連 Aggregate 単位) が確定し、後続入出力プラグインが共通契約として参照できる
- イベント追記専用ストア (Event Source of Truth) が成立し、最低 1 種類のイベント (例: フィード新規取得) を Append → ES 保存 → 出力 Queue 投入 → ビュー更新 → キャッシュ DB 反映 まで通せる
- リソース単位 BFF (Resource-Oriented BFF + Internal CQRS) の最小例が動作し、Command Handler 経路 / Query Handler 経路の論理分離が確認できる
- Read-Your-Write 整合戦略 (Tier 1 / Tier 2 / Tier 3 の使い分けルール) が確定し、ADR として記録されている
- 入力プラグイン契約スケルトン (interface 定義) と出力プラグイン契約スケルトン (interface 定義) が確定し、後続の `ms-06` / `ms-07` が契約に従う参照アダプタ実装に集中できる
- イベント追記 / プロジェクション再構築 / Aggregate 単位同期更新 (Tier 2) のテストケースが網羅され `vp test` で green を維持

## スコープ

- 対象モジュール: 採用ワークスペース上の永続化基盤パッケージ、イベント記録システム、ビュー更新システム、Query API、Command API (リソース単位 BFF 構造)
- 対象機能: Event Source of Truth (イベント追記専用ストア)、キャッシュ DB (Projection)、Aggregate 単位同期更新 (Tier 2)、Read-Your-Write 整合戦略の基盤実装
- 対象契約定義: 入力プラグイン契約スケルトン (interface のみ、参照実装は ms-06)、出力プラグイン契約スケルトン (interface のみ、参照実装は ms-07)
- 対象 ADR: Event Source of Truth の物理選定軸、Read-Your-Write 戦略 (Tier 階層適用ルール)、リソース境界 (Aggregate 設計)、Web UI からの Command 経路 (L8: ER 直結 vs IQ 経由)、入出力プラグイン契約の境界面

## 非スコープ

- 入力プラグイン参照アダプタ (RSS / HTML 解析 / X リスト) の実装 — `ms-06-input-plugin-platform` の責務
- 出力プラグイン参照アダプタ (API / Slack / Web UI) の実装 — `ms-07-output-plugin-platform` の責務
- 定期実行基盤 — `ms-08-scheduler-platform` の責務
- AI 要約機能 — `ms-09-ai-summary` の責務
- 全プロジェクション (集計値 / 関連エンティティ含む) の同期更新 (Eventual Consistency 領域に残す)
- マルチリージョン / バックアップ戦略 (本ロードマップでは選定軸の議論まで)

## 依存マイルストーン

- `ms-01-workspace-foundation`: 採用ワークスペースが前提
- (認証認可基盤への依存はなし) — Intent 規範的制約「認証認可基盤は他全領域 (永続化層を除く) の利用前提」により、永続化層は認証認可と独立して進められる

## 関連 oh-my-codingagent execution サイクル (workflow_identifiers)

| サイクル `<identifier>` | 状態 | コメント |
| ----------------------- | ---- | -------- |
| (未起動)                | -    | -        |

## 想定 oh-my-codingagent execution サイクル数

1〜2

本マイルストーンは 6 領域中で最も論点が集中する (`design-hint.md` の L1〜L9 の大半が永続化層関連)。配下サイクルが 1 つで完遂可能と判断される場合は 1 サイクル、Step 3 (Design) で論点が膨らんだ場合は「(a) Event Store + CQRS 基盤」「(b) プラグイン契約スケルトン + Read-Your-Write 戦略」の 2 サイクルに分割することを許容する。最終判断は配下 oh-my-codingagent execution サイクル Step 1 (Intent Clarification) 段階でユーザー承認を得る。

## 補足 / 留意事項

- Intent 未解決事項「永続化基盤と入出力プラグイン契約の境界面確定タイミング」に対し、本マイルストーンが**先行確定側**を担う。プラグイン契約は本マイルストーン内で interface のみ確定し、参照実装は ms-06 / ms-07 に委譲する形で密結合の悪化を防ぐ
- design-hint.md の論点 L1 (IQ 粒度) / L2 (記録 → 通知経路) / L3 (出力 Queue 粒度) / L5 (ES 選定軸) / L7 (Read-Your-Write) / L8 (Command 経路) / L9 (BFF 単位) は本マイルストーンの配下サイクル Step 3 (Design) で確定、対応 ADR を発行する
- L4 (取得情報用 DB の必要性) は本マイルストーンでは「契約として吸収できる抽象度の判断」のみ行い、最終確定は `ms-06-input-plugin-platform` の Step 3 で実施
- L6 (定期実行基盤と取得システムの結合方式) は `ms-08-scheduler-platform` の責務
