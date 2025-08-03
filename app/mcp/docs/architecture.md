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
2. R2ストレージへの保存（Workflow内で実行）
3. Auto RAGによるインデックス化
4. MCPツールからの検索提供

**設定**:

- 環境変数: `{PREFIX}_AUTO_RAG_NAME`
- R2バケット: `{PREFIX}_DATA_SOURCE`

## 共通設定管理

### 環境変数パターン

- **命名規則**: プレフィックスベースの環境分離
  - Effect: `EFFECT_AUTO_RAG_NAME`, `EFFECT_DATA_SOURCE`
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

### Effect専用設計

- **特化設計**: Effectドキュメントに特化した効率的な実装
- **シンプルな構造**: 単一ドキュメントソースによる複雑性の削減
- **ファクトリーパターン**: 再利用可能なコンポーネント設計
- **型安全性**: TypeScript静的型チェック

### 新機能統合

- **モジュラー設計**: 独立したコンポーネント間の疎結合
- **設定駆動**: コード変更を最小限に抑えた機能追加
- **統一インターフェース**: Effectに特化したMCPサーバーによる一貫性

このアーキテクチャにより、EffectドキュメントMCPサーバーとデータ同期システムの一貫性、拡張性、保守性を確保します。
