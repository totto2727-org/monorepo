# Milestone: Workspace Foundation

- **Milestone ID:** ms-01-workspace-foundation
- **Roadmap ID:** feed-platform
- **Status:** completed <!-- planned | active | completed | blocked | cancelled (`progress.yaml.milestones[].status` と一致させる) -->
- **Created at:** 2026-05-04T00:00:00Z
- **Last updated:** 2026-05-07T03:55:00Z

このドキュメントは 1 マイルストーンの定義書。1 ファイル = 1 マイルストーンを原則とし、`docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md` に配置する。書き方は `plugins/totto2727-coding/skills/share-artifacts/references/milestone.md` (Milestone Authoring Guide) に従う。

## 目的

`feed-platform` ロードマップ全領域の前提となる **`js/` ワークスペース上のアプリケーション基盤と共有ライブラリ基盤**を成立させる。後続 9 マイルストーンは、この基盤を共通の実装・検証・設計判断の前提として参照する。

本マイルストーンは、以下を現在の基盤状態として定義する:

- `js/app/feed-platform-backend/`、`js/app/feed-platform-web/`、`js/app/identity-provider/` がフィードプラットフォームの主要アプリケーション境界として存在する
- Cloudflare Workers、Hono、Remix v3、Effect を前提に、サーバレスアーキテクチャとマイクロサービス境界を表現できるプロジェクト構成を持つ
- Remix / Effect 横断ユーティリティは `js/package/` 配下の共有ライブラリとして提供され、各アプリケーションから参照される
- 後続マイルストーンは、認証認可、永続化、入出力プラグイン、定期実行、AI 要約をこの基盤上で独立に進める

## 到達点 (定性)

配下の oh-my-codingagent execution サイクルが完了し、`progress.yaml.milestones[ms-01-workspace-foundation].status` が `completed` に遷移する条件として、人間が目視で「達成された」と合意できる粒度で書く。

- `js/` が `feed-platform` の採用ワークスペースである
- `feed-platform-backend` / `feed-platform-web` / `identity-provider` が `js/app/` 配下に存在し、各アプリケーションのパッケージ、モジュール構成、Lint / Format / 型チェック / ビルド設定が成立している
- `dynamicLoggerLayer`、`makeDisposableRuntime`、環境 Feature Service、frame request 判定、Page / Frame レンダリング補助などの横断ユーティリティは `js/package/` 配下の共有ライブラリとして利用できる
- 3 アプリケーションは共有ライブラリを直接参照し、アプリケーションごとの同形実装を持たない
- サーバレスアーキテクチャ、マイクロサービス境界、イベントソーシング + CQRS の制約は、後続マイルストーンが拡張できるディレクトリ構成とモジュール境界として表現されている
- `vp check` / `vp test` / `vp run -r build` が通る状態を基盤の検証条件とする

## スコープ

このマイルストーンで扱う領域を具体的に記述する。配下の oh-my-codingagent execution サイクルが**最大でどこまで触ってよいか**の境界。

- 対象アプリケーション: `js/app/feed-platform-backend/` / `js/app/feed-platform-web/` / `js/app/identity-provider/`
- 対象共有ライブラリ: `js/package/` 配下のフィードプラットフォーム共通ライブラリ群
- 対象設定: アプリケーションと共有ライブラリの `package.json` / `tsconfig.json` / `vite.config.ts` / Lint / Format / Test / Build 設定
- 対象ユーティリティ:
  - **Effect runtime 系**: `dynamicLoggerLayer` (`Layer.unwrap` + `Env.Service` 経由 Logger 形式判定) / `makeDisposableRuntime` (TC39 `await using` 自動破棄 HOF + `Symbol.asyncDispose` 実装)
  - **Effect Service 系**: `feature/env.ts` (`process.env.NODE_ENV` 経由 ENV 派生 + `Env.Service` + `makeLayer` (test 用))
  - **Remix UI 系**: `isFrameRequest` (`hono-remix-v3-cloudflare-example/app/routes.ts` ベース) / `createPageOrFrame` (`hono-remix-v3-cloudflare-example/app/ui/page-or-frame.tsx` ベース)
  - **その他 Remix / Effect 横断ユーティリティ**: 複数アプリケーションで共有されるもの
- 対象 ADR: 採用ワークスペース、プロジェクト構成、共有ライブラリ配置、命名、API surface の判断

## 非スコープ

- 認証認可・永続化・入出力プラグイン・定期実行・AI 要約のいずれの実装 (各マイルストーンの責務)
- 具体的なサーバレス実行環境 (Cloudflare Workers / AWS Lambda 等) の選定 (本ロードマップでは「サーバレス原則」の抽象度に留める、各機能マイルストーンが Step 3 で個別判断)
- CI / CD / 本番デプロイ自動化 (Intent 非スコープ)
- イベントストア / Queue / DB の具体的サービス選定 (`ms-05-persistence-event-store` の責務)

## 依存マイルストーン

このマイルストーンが**先行完了を要求する**他のマイルストーン ID を列挙する。`progress.yaml.milestones[].depends_on[]` と完全一致させる。

- (なし) — 本マイルストーンはロードマップの起点

## 関連 oh-my-codingagent execution サイクル (workflow_identifiers)

このマイルストーンに紐付く oh-my-codingagent execution サイクルの `<identifier>` 一覧。

| サイクル `<identifier>`                    | 状態        | コメント                                                                                                             |
| ------------------------------------------ | ----------- | -------------------------------------------------------------------------------------------------------------------- |
| `feed-platform-ms-01-workspace-foundation` | `completed` | `js/` ワークスペース上の 3 アプリケーション境界、標準設定、サーバレス / Remix / Hono / Effect 基盤を成立させる       |
| `feed-platform-ms-01-shared-libraries`     | `completed` | Remix / Effect 横断ユーティリティを `js/package/` 配下の共有ライブラリとして提供し、3 アプリケーションから参照させる |

## 想定 oh-my-codingagent execution サイクル数

**2**

- 3 アプリケーション境界と標準設定の成立
- 共有ライブラリ境界とアプリケーション参照構造の成立

## 補足 / 留意事項

- 後続マイルストーンは `js/` ワークスペース、Effect、Hono、Remix v3、Cloudflare Workers、`@totto2727/fp` 系共有基盤を前提に設計する
- 認証認可、永続化、入出力プラグイン、定期実行、AI 要約の具体実装は後続マイルストーンで扱う
- アーキテクチャ的制約 (サーバレス / マイクロサービス境界 / イベントソーシング + CQRS) は、後続実装が拡張するディレクトリ構成 / モジュール境界として維持する
