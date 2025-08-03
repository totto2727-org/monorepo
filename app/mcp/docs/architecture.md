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
         └──/api/mcp────│  Effect   │                 ├── R2 Storage
                        │ MCP Server │                 ├── Auto RAG
                        └─────┬─────┘                 ├── HTTP APIs
                              │                        └── Firecrawl
                        ┌─────┴─────┐
                        │   Tool    │
                        ├───────────┤
                        └ search_ai_effect
                        
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Scheduled     │────│   Workflows     │────│  Data Sync      │
│   Worker        │    │   Platform      │    │  Workflow       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 共通プラットフォーム

### Cloudflare Workers

- **実行環境**: Edge-first serverless platform
- **スケーリング**: Automatic scaling and global distribution
- **統合サービス**: AI, R2, Analytics, Observability, Workflows

### Cloudflare Workflows

- **実行時間**: 最大15分（通常のWorkersは30秒）
- **耐久性**: 自動的な状態管理とリトライ
- **ステップ実行**: 部分的な失敗に対する耐性
- **用途**: データ同期処理の信頼性向上

### Auto RAG統合

**データフロー**:

1. データ収集（Scheduled Worker → Workflows）
2. R2ストレージへの保存（フォルダ構造で分類）
3. 自動メタデータ設定（folder, filename, timestamp）
4. Auto RAGによるインデックス化
5. MCPツールからのフィルタリング検索

**統一アーキテクチャ**:

- **統一AutoRAG**: 単一のAutoRAGインスタンスで全ドキュメントを管理
- **フォルダベース分類**: `{document-type}/filename`形式でR2に保存
- **自動メタデータ**: Cloudflareが自動的にfolder, filename, timestampを設定
- **フィルタリング検索**: MCPツールがfiltersプロパティで適切なドキュメントを検索

**設定**:

- 環境変数: `AUTO_RAG_NAME` - 統一AutoRAG名
- R2バケット: `DATA_SOURCE` - 統一データバケット

## 共通設定管理

### 環境変数パターン

- **統一命名**: 単一のAutoRAGとR2バケットで全ドキュメント管理
  - AutoRAG: `AUTO_RAG_NAME`
  - R2バケット: `DATA_SOURCE`
- **動的設定**: 実行時設定読み込み
- **型安全性**: TypeScriptによる設定検証

### 設定ファイル

**Cloudflare Workers設定**: [wrangler.jsonc](../wrangler.jsonc)

- Workflowsバインディング
- Scheduled Triggers
- R2バケット設定
- 環境変数

## 共通ファイル構成

```
app/
├── entry.hono.ts           # Honoアプリケーションエントリーポイント
├── entry.worker.ts         # Workersエントリーポイント (Workflow export含む)
├── entry.scheduled.ts      # Scheduled Worker (Workflowトリガー)
├── entry.workflow.ts       # DataSync Workflow実装
├── hono.ts                 # Honoファクトリー設定
├── mcp/                    # MCPサーバーコンポーネント
│   ├── server.ts           # MCPサーバーコア
│   ├── handler.ts          # MCPハンドラーファクトリー
│   └── types.ts            # MCPサーバー型定義
└── sync/                   # データ同期コンポーネント
    ├── retrieve.ts         # データ取得ロジック (Workflow用)
    ├── r2-storage.ts       # R2操作ユーティリティ
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

### マルチドキュメント対応設計

- **統一プラットフォーム**: 複数のドキュメントソースを単一システムで管理
- **フォルダベース分類**: ドキュメントタイプごとのフォルダ分離
- **自動メタデータ**: Cloudflareによる自動的なメタデータ設定
- **フィルタリング検索**: 各ツールが対象ドキュメントのみを検索
- **型安全性**: TypeScript静的型チェック

### 新ドキュメント追加

- **型定義**: `TargetDocument`に新しいドキュメントタイプを追加
- **データソース設定**: Workflowで新しいデータソース設定を追加
- **MCPツール**: 新しい検索ツールを設定に追加
- **フォルダ作成**: R2内で新しいフォルダ構造が自動作成

このアーキテクチャにより、統一されたAutoRAGとR2バケットを使用してマルチドキュメント対応のMCPサーバーとデータ同期システムの一貫性、拡張性、保守性を確保します。
