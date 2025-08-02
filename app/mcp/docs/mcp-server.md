# 統合MCPサーバー設計書

## 概要

この文書は、複数のドキュメントソースに対応する統合MCP（Model Context Protocol）サーバーの設計について説明します。単一のエンドポイントで複数のドキュメント検索ツールを提供します。

**共通アーキテクチャ**: システム全体の設計については[architecture.md](./architecture.md)を参照してください。

## アーキテクチャ

### 高レベルコンポーネント

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MCP Client    │────│  Cloudflare     │────│  Multiple Docs  │
│   (Claude/IDEs) │    │   Workers       │    │   Auto RAGs     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                    │                        │
         │              ┌─────┴─────┐          ┌──────┴──────┐
         └──/api/mcp────│  Unified  │          │ • Effect    │
                        │MCP Server │          │ • React     │
                        └─────┬─────┘          │ • Vue       │
                              │                └─────────────┘
                        Multiple Tools:
                        • search_ai_effect
                        • search_ai_react
                        • search_ai_vue
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

#### 3. 統合ツール実装

**統一命名規則**: `search_ai_{source}`

- **search_ai_effect**: Effectライブラリのドキュメント検索
- **search_ai_react**: Reactライブラリのドキュメント検索  
- **search_ai_vue**: Vueライブラリのドキュメント検索

**共通機能**:
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

## 統合アーキテクチャの利点

### 運用の簡素化

- **単一エンドポイント**: `/api/mcp`でクライアント設定が簡潔
- **統一ツール管理**: 全検索ツールが1つのMCPサーバーに集約
- **一貫した命名**: `search_ai_{source}`パターンで直感的

### 拡張性

- **新ドキュメントソース追加**: 設定変更のみで新しい検索ツールを追加
- **環境別設定**: プレフィックスベースのバインディング管理
  - Effect: `EFFECT_AUTO_RAG_NAME`、`EFFECT_DATA_SOURCE`  
  - React: `REACT_AUTO_RAG_NAME`、`REACT_DATA_SOURCE`
  - Vue: `VUE_AUTO_RAG_NAME`、`VUE_DATA_SOURCE`

### 保守性向上

- **統一インターフェース**: 全ツールが同じMCPサーバー構造
- **設定駆動**: コード変更を最小限に抑えた機能追加
- **型安全性**: TypeScriptによる統合的な型管理

## 使用例

### 利用可能なツール

- **search_ai_effect**: Effect関連の検索
  - "Effect Data型の使い方"
  - "Effect.genでのエラーハンドリング"
- **search_ai_react**: React関連の検索
  - "React Hooksの使い方"
  - "useEffectの依存配列の管理"
- **search_ai_vue**: Vue関連の検索
  - "Vue Composition APIの使い方"
  - "Reactivityシステムの仕組み"

### 期待される応答

各ツールは対応するライブラリの公式ドキュメントを検索し、使用パターンとベストプラクティスについて詳細で実用的なAI回答を生成します。

## 監視と可観測性

- **Cloudflare Workers Analytics**: 組み込みパフォーマンス監視
- **Effectドキュメント検索分析**: クエリパターン分析
- **Auto RAG使用量監視**: リソース使用率追跡
- **エラーログとパフォーマンス追跡**: Cloudflareプラットフォームによる包括的な可観測性