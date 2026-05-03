# Milestone: Workspace Foundation

- **Milestone ID:** ms-01-workspace-foundation
- **Roadmap ID:** feed-platform
- **Status:** planned <!-- planned | active | completed | blocked | cancelled (`roadmap-progress.yaml.milestones[].status` と一致させる) -->
- **Created at:** 2026-05-04T00:00:00Z
- **Last updated:** 2026-05-04T00:00:00Z

このドキュメントは `dev-roadmap` の **Step 2 (Milestone Decomposition)** で `roadmap-planner` Specialist が起草する**1 マイルストーンの定義書**。1 ファイル = 1 マイルストーンを原則とし、`docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md` に配置する。書き方の詳細は `shared-artifacts/references/milestone.md` を参照。

## 目的

`feed-platform` ロードマップ全領域の前提となる**採用ワークスペース (`js/` / `mbt/` / `go/` のいずれか) の確定とプロジェクト雛形整備**を完了し、後続 9 マイルストーンが共通基盤として参照できる土台を成立させる。Intent 未解決事項「採用ワークスペースの確定」を本マイルストーンの配下 `dev-workflow` サイクル Step 1〜2 で解消する。

## 到達点 (定性)

配下の `dev-workflow` サイクルが完了し、`roadmap-progress.yaml.milestones[ms-01-workspace-foundation].status` が `completed` に遷移する条件として、人間が目視で「達成された」と合意できる粒度で書く。

- 採用ワークスペース (`js/` / `mbt/` / `go/` のいずれか) が ADR として確定し、`docs/adr/` 配下に決定根拠が記録されている
- 採用ワークスペース上に `feed-platform` 用のプロジェクト雛形 (パッケージ / モジュール構成、Lint / Format / 型チェック設定) が成立し、`vp check` 等の標準コマンドが通る
- 後続マイルストーンが共通参照する横断ユーティリティ層 (採用ワークスペースのプロジェクト固有スキル — 例 `effect-layer` / `effect-runtime` / `effect-hono` 等のいずれかが該当) の使い方が雛形上で例示されている
- 「サーバレスアーキテクチャ原則」「マイクロサービス境界としてのプラグイン分割」「イベントソーシング + CQRS」というロードマップ Intent のアーキテクチャ的制約が、プロジェクト雛形のディレクトリ構成や境界設計レベルで反映されている (具体実装は後続マイルストーン)

## スコープ

このマイルストーンで扱う領域を具体的に記述する。配下の `dev-workflow` サイクルが**最大でどこまで触ってよいか**の境界。

- 対象モジュール: 採用ワークスペース直下の `feed-platform` 専用ルートパッケージ (例: `js/app/feed-platform/` または `mbt/feed-platform/` または `go/feed-platform/`)
- 対象設定: 採用ワークスペースの Lint / Format / 型チェック / テスト / ビルド設定 (`package.json` / `moon.pkg.json` / `go.mod` 等の必要範囲)
- 対象 ADR: 「採用ワークスペースの確定」「プロジェクト雛形構成」「アーキテクチャ的制約のプロジェクト構造への反映方針」
- 対象ドキュメント: 雛形利用方法を後続マイルストーンに引き継ぐ最低限の README または `docs/workflow/<identifier>/` 配下の `intent-spec.md` / `design.md`

## 非スコープ

- 認証認可・永続化・入出力プラグイン・定期実行・AI 要約のいずれの実装 (各マイルストーンの責務)
- 具体的なサーバレス実行環境 (Cloudflare Workers / AWS Lambda 等) の選定 (本ロードマップでは「サーバレス原則」の抽象度に留める、各機能マイルストーンが Step 3 で個別判断)
- CI / CD / 本番デプロイ自動化 (Intent 非スコープ)
- イベントストア / Queue / DB の具体的サービス選定 (`ms-05-persistence-event-store` の責務)

## 依存マイルストーン

このマイルストーンが**先行完了を要求する**他のマイルストーン ID を列挙する。`roadmap-progress.yaml.milestones[].depends_on[]` と完全一致させる。

- (なし) — 本マイルストーンはロードマップの起点

## 関連 dev-workflow サイクル (workflow_identifiers)

このマイルストーンに紐付く `dev-workflow` サイクルの `<identifier>` 一覧。1:1 が推奨だが 1:N も許容する。

- 起票時 (Step 2): 空 `[]`
- 配下サイクル開始時: 各 `dev-workflow` サイクルが `progress.yaml.roadmap` ブロックを初期化するタイミングで、自身の `<identifier>` を `roadmap-progress.yaml.milestones[].workflow_identifiers[]` に追記する

| サイクル `<identifier>` | 状態 (`active` / `completed` / `blocked` / `cancelled`) | コメント |
| ----------------------- | ------------------------------------------------------- | -------- |
| (未起動)                | -                                                       | -        |

## 想定 dev-workflow サイクル数

1 (推奨)

採用ワークスペース選定と雛形整備は単一の `dev-workflow` サイクルで Intent Spec → Design → Implement → Validate まで完遂可能な規模。ワークスペース選定の議論が長引く場合でも、Step 1 (Intent Clarification) で確定させ Step 3 以降に持ち越さない方針。

## 補足 / 留意事項

- Intent 未解決事項「採用ワークスペースの確定」は本マイルストーンの配下 `dev-workflow` サイクル Step 1〜2 で解消する。`js/` を選ぶ場合は既存スキル群 (`effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp`) との整合性が最も高い
- 本マイルストーン完了後、後続マイルストーンの「対応プロジェクト固有スキル」が確定する (例: `js/` 採用なら `effect-*` 系スキル、`mbt/` 採用なら `moonbit-*` 系スキル、`go/` 採用なら別途スキル整備が必要)
- アーキテクチャ的制約 (サーバレス / マイクロサービス境界 / イベントソーシング + CQRS) はディレクトリ構成 / モジュール境界レベルでの「素地」のみを整える。実装は後続マイルストーン
