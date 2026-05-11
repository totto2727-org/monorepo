# Milestone: Workspace Foundation

- **Milestone ID:** ms-01-workspace-foundation
- **Roadmap ID:** feed-platform
- **Status:** active <!-- planned | active | completed | blocked | cancelled (`roadmap-progress.yaml.milestones[].status` と一致させる) -->
- **Created at:** 2026-05-04T00:00:00Z
- **Last updated:** 2026-05-07T03:55:00Z (Phase 2 拡張 — 共通ライブラリ抽出 cycle 追加)

このドキュメントは `dev-roadmap` の **Step 2 (Milestone Decomposition)** で `roadmap-planner` Specialist が起草する**1 マイルストーンの定義書**。1 ファイル = 1 マイルストーンを原則とし、`docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md` に配置する。書き方の詳細は `shared-artifacts/references/milestone.md` を参照。

## 目的

`feed-platform` ロードマップ全領域の前提となる**採用ワークスペース (`js/` / `mbt/` / `go/` のいずれか) の確定とプロジェクト雛形整備**を完了し、後続 9 マイルストーンが共通基盤として参照できる土台を成立させる。Intent 未解決事項「採用ワークスペースの確定」を本マイルストーンの配下 `dev-workflow` サイクル Step 1〜2 で解消する。

本マイルストーンは **2 つの dev-workflow サイクル** で構成される:

- **Phase 1 (`feed-platform-ms-01-workspace-foundation`、completed 2026-05-07)**: 採用ワークスペース確定 + 3 プロジェクト (`feed-platform-backend` / `feed-platform-web` / `identity-provider`) の Hello World レベル雛形整備 + Cloudflare Workers + Hono + Remix v3 + Effect + ADR-01 / ADR-02 起票。retrospective: `docs/retrospective/feed-platform-ms-01-workspace-foundation.md`
- **Phase 2 (`feed-platform-ms-01-shared-libraries`、active 2026-05-07〜)**: Phase 1 完了時点で 3 プロジェクトに完全同形コピーされていた共通ロジック (`dynamicLoggerLayer` / `makeDisposableRuntime` / `feature/env.ts` / `isFrameRequest` / `PageOrFrame` / 他 Remix・Effect 横断ユーティリティ) を `js/package/` 配下のライブラリとして抽出し、3 プロジェクトから参照する形に refactor。User 戦略指示 (2026-05-06) によりロードマップに後追い挿入され、ms-02 (認証) 着手前に完了させる必要がある

## 到達点 (定性)

配下の `dev-workflow` サイクルが完了し、`roadmap-progress.yaml.milestones[ms-01-workspace-foundation].status` が `completed` に遷移する条件として、人間が目視で「達成された」と合意できる粒度で書く。

### Phase 1 到達点 (completed 2026-05-07)

- 採用ワークスペース (`js/` / `mbt/` / `go/` のいずれか) が ADR として確定し、`docs/adr/` 配下に決定根拠が記録されている
- 採用ワークスペース上に `feed-platform` 用のプロジェクト雛形 (パッケージ / モジュール構成、Lint / Format / 型チェック設定) が成立し、`vp check` 等の標準コマンドが通る
- 後続マイルストーンが共通参照する横断ユーティリティ層 (採用ワークスペースのプロジェクト固有スキル — 例 `effect-layer` / `effect-runtime` / `effect-hono` 等のいずれかが該当) の使い方が雛形上で例示されている
- 「サーバレスアーキテクチャ原則」「マイクロサービス境界としてのプラグイン分割」「イベントソーシング + CQRS」というロードマップ Intent のアーキテクチャ的制約が、プロジェクト雛形のディレクトリ構成や境界設計レベルで反映されている (具体実装は後続マイルストーン)

### Phase 2 到達点 (Phase 2 cycle 完了時に更新)

- Phase 1 で 3 プロジェクト (`feed-platform-backend` / `feed-platform-web` / `identity-provider`) に完全同形コピーされていた共通ロジック群が `js/package/` 配下のライブラリとして抽出され、3 プロジェクトすべてが当該ライブラリを参照する形に refactor されている
- 抽出対象 (本マイルストーン Phase 2 サイクル Step 1 で具体合意): `dynamicLoggerLayer` / `makeDisposableRuntime` / `feature/env.ts` 相当 / `isFrameRequest` / `PageOrFrame` / 他 Remix / Effect 横断ユーティリティ
- `vp check` / `vp test` / `vp run -r build` がすべて通過 (Phase 1 と同等の SC 維持)
- 共通 library 配置 / 命名 / API surface が ADR として記録されている (Phase 1 ADR-01 を補足する形 or 新規 ADR)

## スコープ

このマイルストーンで扱う領域を具体的に記述する。配下の `dev-workflow` サイクルが**最大でどこまで触ってよいか**の境界。

### Phase 1 (completed)

- 対象モジュール: 採用ワークスペース直下の `feed-platform` 専用ルートパッケージ (例: `js/app/feed-platform/` または `mbt/feed-platform/` または `go/feed-platform/`)
- 対象設定: 採用ワークスペースの Lint / Format / 型チェック / テスト / ビルド設定 (`package.json` / `moon.pkg.json` / `go.mod` 等の必要範囲)
- 対象 ADR: 「採用ワークスペースの確定」「プロジェクト雛形構成」「アーキテクチャ的制約のプロジェクト構造への反映方針」 (= ADR-01 / ADR-02 として起票済)
- 対象ドキュメント: 雛形利用方法を後続マイルストーンに引き継ぐ最低限の README または `docs/workflow/<identifier>/` 配下の `intent-spec.md` / `design.md`

### Phase 2 (active)

- 対象モジュール: `js/package/` 配下に新設する共通ライブラリ群 + 既存 3 プロジェクト (`js/app/feed-platform-backend/` / `js/app/feed-platform-web/` / `js/app/identity-provider/`) の対応箇所
- 対象抽出: Phase 1 で 3 プロジェクトに完全同形コピーされた以下の単位
  - **Effect runtime 系**: `dynamicLoggerLayer` (`Layer.unwrap` + `Env.Service` 経由 Logger 形式判定) / `makeDisposableRuntime` (TC39 `await using` 自動破棄 HOF + `Symbol.asyncDispose` 実装)
  - **Effect Service 系**: `feature/env.ts` (`process.env.NODE_ENV` 経由 ENV 派生 + `Env.Service` + `makeLayer` (test 用))
  - **Remix UI 系**: `isFrameRequest` (`hono-remix-v3-cloudflare-example/app/routes.ts` ベース) / `createPageOrFrame` (`hono-remix-v3-cloudflare-example/app/ui/page-or-frame.tsx` ベース)
  - **その他 Remix / Effect 横断ユーティリティ**: Phase 2 cycle Step 1 で具体合意
- 対象設定: `js/package/` 配下の新規パッケージの `package.json` / `tsconfig.json` / `vite.config.ts` / Lint / Format 設定、3 プロジェクト側の依存追加
- 対象 ADR: 共通ライブラリの配置 / 命名 / API surface の判断 (Phase 1 ADR-01 を補足する形 or 新規 ADR、Phase 2 cycle Step 1〜3 で合意)

## 非スコープ

- 認証認可・永続化・入出力プラグイン・定期実行・AI 要約のいずれの実装 (各マイルストーンの責務)
- 具体的なサーバレス実行環境 (Cloudflare Workers / AWS Lambda 等) の選定 (本ロードマップでは「サーバレス原則」の抽象度に留める、各機能マイルストーンが Step 3 で個別判断)
- CI / CD / 本番デプロイ自動化 (Intent 非スコープ)
- イベントストア / Queue / DB の具体的サービス選定 (`ms-05-persistence-event-store` の責務)

## 依存マイルストーン

このマイルストーンが**先行完了を要求する**他のマイルストーン ID を列挙する。`roadmap-progress.yaml.milestones[].depends_on[]` と完全一致させる。

- (なし) — 本マイルストーンはロードマップの起点

## 関連 dev-workflow サイクル (workflow_identifiers)

このマイルストーンに紐付く `dev-workflow` サイクルの `<identifier>` 一覧。1:1 が推奨だが 1:N も許容する。本マイルストーンは Phase 1 + Phase 2 の 2 サイクル構成 (User 戦略指示 2026-05-06 によるロードマップ後追い拡張)。

| サイクル `<identifier>`                    | 状態        | コメント                                                                                                                                                                                                          |
| ------------------------------------------ | ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `feed-platform-ms-01-workspace-foundation` | `completed` | Phase 1 (2026-05-04 〜 2026-05-07)。3 プロジェクト雛形 + Cloudflare Workers + Hono + Remix v3 + Effect + ADR-01 / ADR-02 起票成立。retrospective `docs/retrospective/feed-platform-ms-01-workspace-foundation.md` |
| `feed-platform-ms-01-shared-libraries`     | `active`    | Phase 2 (2026-05-07 〜)。共通ライブラリ抽出 (`dynamicLoggerLayer` / `makeDisposableRuntime` / `feature/env.ts` / `isFrameRequest` / `PageOrFrame` 等) を `js/package/` 配下に refactor                            |

## 想定 dev-workflow サイクル数

**2** (Phase 1 + Phase 2)

- Phase 1 (completed): 採用ワークスペース選定 + 3 プロジェクト雛形整備
- Phase 2 (active): 共通ライブラリ抽出。Phase 1 で発見された 3 プロジェクト同形コピーの 5 件 (+ 他横断ユーティリティ) を `js/package/` 配下のライブラリとして抽出する単一サイクル規模 (Hello World + skeleton 抽出のため、auth / 永続化等の重い実装は伴わない)

## 補足 / 留意事項

- Intent 未解決事項「採用ワークスペースの確定」は本マイルストーンの配下 `dev-workflow` サイクル Step 1〜2 で解消する。`js/` を選ぶ場合は既存スキル群 (`effect-layer` / `effect-runtime` / `effect-hono` / `totto2727-fp`) との整合性が最も高い
- 本マイルストーン完了後、後続マイルストーンの「対応プロジェクト固有スキル」が確定する (例: `js/` 採用なら `effect-*` 系スキル、`mbt/` 採用なら `moonbit-*` 系スキル、`go/` 採用なら別途スキル整備が必要)
- アーキテクチャ的制約 (サーバレス / マイクロサービス境界 / イベントソーシング + CQRS) はディレクトリ構成 / モジュール境界レベルでの「素地」のみを整える。実装は後続マイルストーン
