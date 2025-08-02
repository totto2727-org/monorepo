# システムアーキテクチャ概要

## 概要

この文書は、MCPプロジェクト全体のシステムアーキテクチャについて説明します。Cloudflare Workers上でMCP（Model Context Protocol）サーバーとデータ同期システムを統合したアーキテクチャを提供します。

## 全体アーキテクチャ

### 統合システム構成

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MCP Client    │────│  Cloudflare     │────│  Data Sources   │
│   (Claude/IDEs) │    │   Workers       │    │  & Storage      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                    │                        │
         │              ┌─────┴─────┐                 │
         └──/api/mcp────│ Unified   │                 ├── R2 Storage
                        │ MCP Server │                 ├── Auto RAG
                        └─────┬─────┘                 ├── HTTP APIs
                              │                        └── Firecrawl
                        ┌─────┴─────┐
                        │   Tools   │
                        ├───────────┤
                        ├ search_ai_effect
                        ├ search_ai_react
                        └ search_ai_vue
```

## 共通プラットフォーム

### Cloudflare Workers

- **実行環境**: Edge-first serverless platform
- **スケーリング**: Automatic scaling and global distribution
- **統合サービス**: AI, R2, Analytics, Observability

### Auto RAG統合

**データフロー**:
1. データ収集（Scheduled Worker）
2. R2ストレージへの保存
3. Auto RAGによるインデックス化
4. MCPツールからの検索提供

**設定**:
- 環境変数: `{PREFIX}_AUTO_RAG_NAME`
- R2バケット: `{PREFIX}_DATA_SOURCE`

## 共通設定管理

### 環境変数パターン

- **命名規則**: プレフィックスベースの環境分離
  - Effect: `EFFECT_AUTO_RAG_NAME`, `EFFECT_DATA_SOURCE`
  - 将来: `REACT_AUTO_RAG_NAME`, `VUE_AUTO_RAG_NAME`
- **動的設定**: 実行時設定読み込み
- **型安全性**: TypeScriptによる設定検証

### 設定ファイル

**Cloudflare Workers設定**: [wrangler.jsonc](../wrangler.jsonc)

## 共通ファイル構成

```
app/
├── entry.hono.ts           # Honoアプリケーションエントリーポイント
├── entry.worker.ts         # Workersエントリーポイント
├── hono.ts                 # Honoファクトリー設定
├── mcp/                    # MCPサーバーコンポーネント
│   ├── server.ts           # MCPサーバーコア
│   ├── handler.ts          # MCPハンドラーファクトリー
│   └── types.ts            # MCPサーバー型定義
└── sync/                   # データ同期コンポーネント
    ├── data-sync.ts        # Scheduled worker
    ├── data-fetcher.ts     # データ取得ロジック
    ├── r2-storage.ts       # R2操作ユーティリティ
    ├── error-handler.ts    # エラーハンドリング
    └── types.ts            # データ同期型定義
```

## 共通セキュリティ原則

### エラーハンドリング
- **サーバーサイドログ**: `console.error()`による詳細エラー記録
- **クライアントレスポンス**: サニタイズされた汎用メッセージ
- **情報漏洩防止**: 機密情報の外部露出回避

### アクセス制御
- **バインディング権限**: 最小権限の原則
- **APIキー管理**: 環境変数による安全な管理
- **CORS設定**: 適切なオリジン制限

## 拡張性設計

### マルチドキュメント対応
- **統合エンドポイント**: `/api/mcp`で全ドキュメントソースを提供
- **ツール命名規則**: `search_ai_{source}`パターンで一貫性確保
- **設定ベース拡張**: 新ドキュメントソース追加時の最小変更
- **ファクトリーパターン**: 再利用可能なコンポーネント設計
- **型安全性**: TypeScript静的型チェック

### 新機能統合
- **モジュラー設計**: 独立したコンポーネント間の疎結合
- **設定駆動**: コード変更を最小限に抑えた機能追加
- **統一インターフェース**: 全ツールが同一のMCPサーバーで動作

この共通アーキテクチャにより、MCPサーバーとデータ同期システムの一貫性、拡張性、保守性を確保します。