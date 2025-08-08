# データ同期システム設計書

## 概要

この文書は、MCPサーバー用のデータソース定期更新システムの設計について説明します。Cloudflare Workflowsを活用して、耐久性と拡張性の高いデータ同期を実現します。

**共通アーキテクチャ**: システム全体の設計については[architecture.md](./architecture.md)を参照してください。

## アーキテクチャ

### 高レベルコンポーネント

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Scheduled     │────│    Workflows    │────│  Data Sources   │
│   Worker        │    │  (DataSync)     │    │  (HTTP/Firecrawl)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                      │                       │
         │              ┌───────┴────────┐             │
         └──trigger─────│ R2 Storage     │─────fetch──┘
                        │ (Raw Data)     │
                        └───────┬────────┘
                                │
                        ┌───────┴────────┐
                        │   Auto RAG     │
                        │   Processing   │
                        └────────────────┘
```

### コアコンポーネント

#### 1. Scheduled Worker

- **フレームワーク**: Cloudflare Workers + Scheduled Events
- **実行頻度**: 週次（毎週日曜日午前0時 UTC）
- **責務**: Workflowインスタンスの作成とトリガー
- **実装**: 最小限のロジックでWorkflowを起動

#### 2. DataSync Workflow

- **フレームワーク**: Cloudflare Workflows
- **責務**: 実際のデータ同期処理の実行
- **特徴**:
  - 長時間実行可能（最大15分）
  - 自動リトライとエラーハンドリング
  - ステップ単位での状態管理

#### 3. データソースハンドラー

**HTTPデータソース**

- 単純なHTTP GETリクエスト
- 取得したテキストをそのまま保存

**Firecrawlデータソース**

- Firecrawl APIを使用したWebスクレイピング
- Markdown形式での構造化コンテンツ抽出

#### 4. データストレージ

- **プライマリ**: R2バケット
- **データ形式**:
  - Firecrawl: Markdown形式
  - HTTP: 取得テキストそのまま
- **更新方式**: 既存データの上書き更新

## 型定義

### データソース設定

データソース設定の型定義は[app/sync/type.ts](./app/sync/type.ts)で管理されています。

### 実装済み型定義

- ✅ **DataFetchResult**: Effect.Effectによるデータ取得結果の構造化
- ✅ **DataSourceType**: HTTPとFirecrawlのデータソース種別
- ✅ **DataSourceTarget**: URLとタイプによるデータソース設定
- ✅ **DataSourceConfig**: R2バケットとデータソース配列の設定

### 将来実装予定

- 同期ジョブの実行結果管理
- より詳細なエラーハンドリング用の型定義

## ファイル構成

### 実装済み構成

```
app/
├── entry.worker.ts         # Workers エントリーポイント (Workflow export含む)
├── entry.scheduled.ts      # Scheduled Worker (Workflowトリガー)
├── entry.workflow.ts       # DataSync Workflow実装
└── sync/
    ├── retrieve.ts         # データ取得ロジック (Workflow用)
    ├── r2-storage.ts       # R2操作ユーティリティ
    └── types.ts            # データソース型定義
```

## 設定管理

### 環境変数とバインディング

**Scheduled Worker設定**:

- **Cron Trigger**: `0 0 * * 1` (毎週日曜日午前0時 UTC)
- **Workflow Binding**: `DATA_SYNC_WORKFLOW`

**Workflow設定**:

- **R2 Bucket**: `EFFECT_DATA_SOURCE`
- **データソース**: コード内定義（将来的に環境変数化予定）

### 設定例構造

- HTTP APIエンドポイント設定
- Firecrawl対象URL設定
- 週次実行タイミング（固定）

## Auto RAGとの統合

### データフロー

1. **週次Scheduled Worker実行** (毎週日曜日午前0時 UTC)
2. **Workflowインスタンス作成**: ユニークIDでWorkflowを起動
3. **Workflow実行**:
   - データソース設定の読み込み
   - 各データソースからのデータ取得（retrieve）
   - R2への保存（コンテンツタイプ付き）
4. **Auto RAGインデックス化**: R2バケットとAuto RAGの自動連携
5. **MCP検索**: search_ai_effectツールからの検索可能化

### データ形式の統一

- Auto RAG互換フォーマットでの保存
- 検索効率を考慮したデータ構造

## メタデータとフィルタリング

### 自動メタデータ設定

Cloudflare AutoRAGは、R2オブジェクトに対して以下のメタデータを自動的に設定します：

- **folder**: ファイルのディレクトリパス（例: `effect/`）
- **filename**: ファイル名（例: `effect-website-llms-full.txt`）
- **timestamp**: 最終更新時間（Unix timestamp）

### フィルタリング機能

各MCPツールは、AutoRAGの`filters`プロパティを使用して対象ドキュメントのみを検索：

```javascript
filters: {
  key: "folder",
  type: "eq", 
  value: "effect"  // effectフォルダのみを検索
}
```

**サポートされる比較演算子**:

- `eq`: 等しい
- `ne`: 等しくない
- `gt`: より大きい
- `gte`: 以上
- `lt`: より小さい
- `lte`: 以下

### フォルダ構造

R2バケット内のファイル構造：

```
mcp/
├── effect/
│   ├── effect-website-llms-full.txt
│   └── [他のEffectドキュメント]
└── [将来追加される他のドキュメントタイプ]/
    └── [ドキュメントファイル]
```

## Cloudflare Workflowsの活用

### Workflowsとは

Cloudflare Workflowsは、長時間実行可能な耐久性のあるワークフローを構築するためのサービスです。

**主な特徴**:

- **耐久性**: ワークフローの状態は自動的に保存され、失敗時に再開可能
- **長時間実行**: 最大15分間の実行時間（通常のWorkersは30秒制限）
- **ステップ実行**: 各ステップは独立して実行され、部分的な失敗に対して耐性がある
- **自動リトライ**: 失敗したステップは自動的にリトライされる

### Workflowバインディング

`wrangler.jsonc`での設定:

```json
{
  "workflows": [
    {
      "binding": "DATA_SYNC_WORKFLOW",
      "class_name": "DataSyncWorkflow",
      "name": "mcp-data-sync-workflow"
    }
  ]
}
```

### Workflowsによる改善点

#### 信頼性の向上

- **自動リトライ**: ネットワークエラーへの自動対応
- **部分的失敗への対応**: 一部のデータソースが失敗しても処理継続
- **状態の永続化**: 処理途中での中断にも対応

#### パフォーマンスと拡張性

- **長時間実行**: 最大15分の実行時間でより多くのデータソースに対応
- **並列処理**: Effect.allによる効率的な並列実行
- **メモリ効率**: ステップ単位での処理によりメモリ使用量を最適化

#### 可観測性

- **実行履歴**: 各Workflowインスタンスの実行履歴を追跡
- **ステータス確認**: 現在の実行状態をリアルタイムで確認
- **デバッグ**: 各ステップの成功/失敗を個別に確認可能

## エラーハンドリング

### Workflowレベル

- ステップ単位での自動リトライ
- 失敗したステップのみ再実行
- 全体の失敗時にはWorkflow全体を再実行可能

### アプリケーションレベル

- Effect.catchAllによる個別データソースのエラーハンドリング
- エラーログの記録
- 他のデータソースの処理は継続

## 将来の拡張性

### 新しいドキュメントタイプの追加

1. **型定義更新**: `mcp/types.ts`の`TargetDocument`に新しいタイプを追加
2. **データソース設定**: `createDataSourceConfigArray`に新しい設定を追加
3. **MCPツール設定**: `entry.hono.ts`に新しい検索ツールを追加
4. **フォルダ作成**: R2内で新しいフォルダが自動作成される

例：Reactドキュメント追加の場合：

```typescript
// mcp/types.ts
export type TargetDocument = "effect" | "react"

// entry.workflow.ts  
{
  dataSources: [
    { type: "text", url: new URL("https://react.dev/reference.txt") },
  ],
  target: "react",
}

// entry.hono.ts
{
  description: "Search React documentation and generate AI responses",
  name: "search_ai_react", 
  target: "react",
  title: "React Documentation Search",
}
```

### パフォーマンス最適化

- 並列処理の最適化
- データソースごとの優先度設定
- 条件付き実行（変更検出など）

## 監視とデバッグ

### Cloudflare Dashboard

- Workflow実行履歴の確認
- 各インスタンスの詳細な実行ログ
- エラー率と成功率の監視

### ログ出力

- インスタンスID: 各実行を一意に識別
- ステータス情報: 実行の進行状況
- エラーログ: 失敗したデータソースの詳細

この設計により、Cloudflare Workflowsを活用した耐久性と拡張性の高いデータ同期システムを実現し、MCPサーバーのデータ品質と最新性を確保します。
