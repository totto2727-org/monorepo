# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ構造

これはTurboでタスクオーケストレーションを行うPNPMモノレポです。

## 開発コマンド

**Turboタスク：**

- `turbo build` - 依存関係グラフ最適化ですべてのアプリケーションをビルド
- `turbo check` - すべてのアプリケーションでタイプチェックを実行
- `turbo deploy` - すべてのアプリケーションをデプロイ

**ルートレベルツール：**

- `nr check` - Biome、dprintチェックを実行
- `nr fix` - Biome、dprintで自動修正

**注意：** `@antfu/ni`を使用してパッケージマネージャーに依存しないコマンドを実行します：

- `pnpm`の代わりに`na`
- `pnpm i`の代わりに`ni`
- `pnpm run`の代わりに`nr`

## アーキテクチャ

### パッケージ管理

- 依存関係バージョンの一元管理のためカタログモード付きPNPMを使用
- すべての依存関係バージョンは`pnpm-workspace.yaml`カタログで定義
- インポートマップ設定で`#@*`プレフィックスによるクリーンな内部インポート

### 開発ツール

- **Turbo**: モノレポタスクオーケストレーション（miseでインストール）
- **Biome**: 高速リンティングとフォーマッティング
- **dprint**: 追加コードフォーマッティング
