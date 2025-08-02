# MCPサーバー設計書

## 概要

この文書は、Effectドキュメント検索のためのMCP（Model Context Protocol）サーバーの設計について説明します。

**共通アーキテクチャ**: システム全体の設計については[architecture.md](./architecture.md)を参照してください。

## アーキテクチャ

### 高レベルコンポーネント

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MCP Client    │────│  Cloudflare     │────│   Effect Docs   │
│   (Claude/IDEs) │    │   Workers       │    │   Auto RAG      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ├── Hono Router
                              ├── Factory Pattern
                              ├── MCP Handler
                              └── MCP Server Core
```

### コアコンポーネント

#### 1. MCPサーバーコア

- **フレームワーク**: `@modelcontextprotocol/sdk`
- **トランスポート**: `StreamableHTTPTransport`
- **プロトコル**: MCP 2024-11-05 仕様準拠
- **設定**: `McpServerConfig`による動的設定
- **実装**: [app/mcp/server.ts](./app/mcp/server.ts)

#### 2. ハンドラーレイヤー

- **ファクトリーパターン**: Hono Factory Helperによる型安全なハンドラー作成
- **環境統合**: Cloudflare.Envからの動的設定
- **トランスポート管理**: HTTPトランスポートのライフサイクル管理
- **実装**: [app/mcp/handler.ts](./app/mcp/handler.ts)

#### 3. ツール実装

**Effectドキュメント検索ツール** (`search_effect_docs_by_ai`)

- Effectライブラリのドキュメント検索に特化
- Auto RAG `aiSearch()`メソッド統合
- 検索結果 + AI回答生成
- JSONレスポンス形式
- **セキュリティ**: エラー詳細をクライアントレスポンスから除外

#### 4. 型システム

- 設定管理のための共有型定義
- 全コンポーネントでのTypeScript型安全性
- **実装**: [app/mcp/types.ts](./app/mcp/types.ts)

## 実装ファイル

### ファイル構成

```
app/
├── entry.hono.ts           # Honoアプリケーションエントリーポイント
├── entry.worker.ts         # Workersエントリーポイント
├── hono.ts                 # Honoファクトリー設定
└── mcp/
    ├── server.ts           # MCPサーバーとツール実装
    ├── handler.ts          # MCPハンドラーファクトリー
    └── types.ts            # 共有型定義
```

### リファクタリングによる主な改善点

1. **関心の分離**: MCPサーバーロジックとHTTP処理の明確な分離
2. **依存性注入**: 設定関数による環境依存の外部化
3. **型安全性**: 共有型定義による一貫性確保
4. **拡張性**: ファクトリーパターンによる他ドキュメントソースへの容易な拡張
5. **セキュリティ**: サーバーサイドログとサニタイズされたクライアントレスポンスによる強化されたエラーハンドリング

## 設定

### 環境変数とバインディング

Cloudflare Workersバインディングによる設定管理:

- **AIバインディング**: `AI` - Cloudflare AIサービスアクセス
- **R2バケット**: `EFFECT_DATA_SOURCE` - Effectドキュメントストレージ
- **Auto RAG**: `EFFECT_AUTO_RAG_NAME` - Effect専用Auto RAG設定

**設定ファイル**: [wrangler.jsonc](./wrangler.jsonc)

### 依存関係

依存関係は[package.json](./package.json)で定義されたPNPMカタログモードで管理されています。

主要な依存関係:
- `@hono/mcp` - Hono用MCP統合
- `@modelcontextprotocol/sdk` - 公式MCP SDK
- `hono` - Webフレームワーク
- `zod` - スキーマバリデーション

## セキュリティとパフォーマンス

### セキュリティ強化

- **入力パラメータバリデーション**: 全入力に対するZodスキーマバリデーション
- **エラー情報保護**: 詳細エラーはサーバーサイドのみでログ出力
- **サニタイズされたクライアントレスポンス**: 汎用エラーメッセージで情報漏洩を防止
- **環境固有バインディング**: マルチドキュメント対応のための明確な命名規則（`EFFECT_*`）

### パフォーマンス考慮事項

- **適切なタイムアウト設定**: Cloudflare Workers経由で設定可能
- **エラーハンドリングとリトライロジック**: 堅牢なエラー復旧機構
- **ファクトリーパターンの効率性**: 最小限のオーバーヘッドでの再利用可能なハンドラー作成

## エラーハンドリング

### セキュリティファーストアプローチ

- **サーバーサイドログ**: `console.error()`による詳細エラー情報のログ出力
- **クライアントレスポンスサニタイゼーション**: 汎用エラーメッセージのみ
- **情報漏洩防止**: 機密性のあるサーバー詳細をクライアントに公開しない

## 将来の拡張性

### マルチドキュメント対応

リファクタリングされたアーキテクチャは以下により他ドキュメントソースへの容易な拡張をサポート:

- **設定可能なMCPハンドラー**: 環境駆動の設定関数
- **命名規則**: プレフィックス付きバインディング（`EFFECT_*`、`REACT_*`、`VUE_*`）
- **ファクトリーパターン**: 異なるドキュメントソース用の再利用可能なハンドラー生成

### 設定のスケーラビリティ

環境バインディングは明確な分離のための命名規則に従います:
- Effect: `EFFECT_AUTO_RAG_NAME`、`EFFECT_DATA_SOURCE`
- 将来のReact: `REACT_AUTO_RAG_NAME`、`REACT_DATA_SOURCE`
- 将来のVue: `VUE_AUTO_RAG_NAME`、`VUE_DATA_SOURCE`

## 使用例

### 典型的な検索クエリ

- "Effect Data型の使い方"
- "Effect.genでのエラーハンドリング"
- "Effect Schemaでのバリデーション"
- "Effect Configの設定方法"

### 期待される応答

システムはEffect公式ドキュメントを検索し、Effectライブラリの使用パターンとベストプラクティスについて詳細で実用的なAI回答を生成します。

## 監視と可観測性

- **Cloudflare Workers Analytics**: 組み込みパフォーマンス監視
- **Effectドキュメント検索分析**: クエリパターン分析
- **Auto RAG使用量監視**: リソース使用率追跡
- **エラーログとパフォーマンス追跡**: Cloudflareプラットフォームによる包括的な可観測性