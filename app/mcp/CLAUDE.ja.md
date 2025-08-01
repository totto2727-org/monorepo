# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## アプリケーション概要

これはCloudflare Workers上で動作するMCP（Model Context Protocol）アプリケーションです。Honoフレームワークを使用し、Viteでビルドされます。

## 開発コマンド

**開発用：**

- `nr dev` - Vite開発サーバーを起動
- `nr preview` - Wranglerプレビューサーバーを起動
- `nr start` - Wranglerローカル開発サーバーを起動
- `nr check` - TypeScriptタイプチェックを実行

**ビルド・デプロイ：**

- `nr build` - Viteで本番用ビルド
- `nr deploy` - Cloudflare Workersにデプロイ

## アーキテクチャ

### プロジェクト構造

```
app/
├── entry.hono.ts    # Honoアプリケーションの定義
└── entry.worker.ts  # Workers エントリーポイント
```

### 技術スタック

- **Hono**: 軽量Webフレームワーク
- **Vite**: ビルドツール
- **Cloudflare Workers**: サーバーレス実行環境
- **TypeScript**: 型安全性

### Cloudflareサービス統合

- **AI Binding**: Cloudflare AI へのアクセス
- **R2 Bucket**: データストレージ（`DATA_SOURCE`バインディング）
- **Auto RAG**: 検索拡張生成（`AUTO_RAG_NAME`環境変数で設定）
- **Observability**: パフォーマンス監視有効

### 設定ファイル

- `wrangler.jsonc`: Workers設定、バインディング、環境変数
- `vite.config.ts`: Viteビルド設定
- Import Maps: `#@*`プレフィックスでクリーンなパス解決

### 依存関係管理

- 原則として依存関係は`devDependencies`に追加する

## デプロイメント

### 本番環境セットアップ

1. **Cloudflare R2**: データストレージ用バケット作成
2. **AI Gateway**: API管理とキャッシュ（推奨）
3. **Auto RAG**: R2バケットと連携したRAG機能
4. **Workers**: GitHub統合またはローカルデプロイ

詳細な手順はREADME.mdを参照してください。
