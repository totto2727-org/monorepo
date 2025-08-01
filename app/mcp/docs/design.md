# MCP サーバー設計書

## 概要

この文書は、Effectドキュメント検索のためのMCP（Model Context Protocol）サーバーの設計について説明します。Cloudflare Workers上で`@hono/mcp`を使用し、Cloudflare Auto RAGを通じてEffectライブラリのドキュメントを検索・提供するシステムです。

## アーキテクチャ

### 高レベルコンポーネント

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MCP Client    │────│  Cloudflare     │────│   Effect Docs   │
│   (Claude/IDEs) │    │   Workers       │    │   Auto RAG      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ├── Hono Router
                              ├── @hono/mcp
                              ├── MCP Server
                              └── ai_search Tool
```

### コアコンポーネント

#### 1. MCP サーバーコア

- **フレームワーク**: `@hono/mcp` + `@modelcontextprotocol/sdk`
- **トランスポート**: `StreamableHTTPTransport`
- **プロトコル**: MCP 2024-11-05 仕様準拠
- **ライフサイクル**: HTTP ストリーミング接続

#### 2. ツール実装

**Effect ドキュメント検索ツール** (`search_effect_docs_by_ai`)

- Effectライブラリのドキュメント検索に特化
- Auto RAG の `aiSearch()` メソッドでEffect公式ドキュメントを検索
- 検索結果 + AI による回答生成
- ストリーミングレスポンスをデフォルト有効

#### 3. Auto RAG 統合

```typescript
// Effect ドキュメント検索の使用例
const effectDocsResponse = await env.AI.autorag(env.AUTO_RAG_NAME).aiSearch({
  query: "Effect Data型の使い方",
  rewrite_query: true,
  stream: true
})
```

## 実装ファイル

### ファイル構成

- `app/mcp-server.ts`: MCP サーバーとツールの実装
- `app/entry.hono.ts`: Hono アプリケーションエントリーポイント
- `app/entry.worker.ts`: Workers エントリーポイント

## 設定

### 環境変数とバインディング

```json
// wrangler.jsonc
{
  "ai": {
    "binding": "AI"
  },
  "vars": {
    "AUTO_RAG_NAME": "effect-mcp"
  }
}
```

### 依存関係

```json
// package.json devDependencies（カタログモード使用）
{
  "@hono/mcp": "catalog:",
  "@modelcontextprotocol/sdk": "catalog:",
  "hono": "catalog:",
  "zod": "catalog:"
}
```

## レスポンス形式

### Effect ドキュメント検索レスポンス

```typescript
interface EffectDocsSearchResponse {
  query: string          // 元の検索クエリ
  response: string       // Effect関連のAI生成レスポンス
  retrieved_data: {      // Effectドキュメントからの検索結果
    content: string      // ドキュメントの内容
    score: number        // 関連度スコア
    metadata?: {         // ドキュメントメタデータ
      title?: string
      url?: string
      section?: string
    }
  }[]
}
```

## 実装計画

### フェーズ 1: 基本セットアップ

1. `@hono/mcp` の統合
2. 基本的な MCP サーバーの構築
3. HTTP トランスポートの設定

### フェーズ 2: Effect ドキュメント検索ツール実装

1. `search_effect_docs_by_ai` ツールのEffect特化実装
2. Auto RAG バインディング統合（Effectドキュメント用）
3. エラーハンドリングとバリデーション

### フェーズ 3: 最適化

1. ストリーミング対応
2. エラー処理の改善
3. パフォーマンス調整

## セキュリティとパフォーマンス

### セキュリティ

- 入力パラメータの検証
- クエリ長の制限
- レート制限（Cloudflare Workers レベル）

### パフォーマンス

- ストリーミングレスポンス対応
- 適切なタイムアウト設定
- エラー処理とリトライロジック

## 監視と可観測性

- Cloudflare Workers Analytics
- Effect ドキュメント検索クエリの分析
- Auto RAG 使用量監視
- エラーログとパフォーマンス追跡

## 使用例

### 典型的な検索クエリ

- "Effect Data型の使い方を教えて"
- "Effect.genでエラーハンドリングする方法"
- "Effect Schemaでバリデーションする方法"
- "Effect Configの設定方法"

### 期待される応答

Effect公式ドキュメントから関連する情報を検索し、AIがEffectライブラリの使用方法について詳細で実用的な回答を生成します。
