# saas-example

TanStack スタックを使用したモダンな React エコシステムを紹介するフルスタック SaaS デモアプリケーション。

## 技術スタック

- **フロントエンド**: React 19 + TanStack Start (Router, Query, Store, Form, DB)
- **バックエンド**: Hono on Cloudflare Workers
- **認証**: better-auth
- **データベース**: Kysely + LibSQL
- **国際化**: Inlang Paraglide-JS (日本語, 英語)
- **スタイリング**: Tailwind CSS v4 + @package/ui
- **テスト**: Vitest
- **コンポーネント**: Storybook
- **ビルド**: Vite + @cloudflare/vite-plugin
- **React コンパイラ**: babel-plugin-react-compiler

## 開発

```bash
# ローカルデータベースサーバーの起動 (vp dev の前に必要)
task db:dev

# 開発サーバーの起動 (このディレクトリから実行)
vp dev

# Vite+ タスクの実行 — `setup` と `build` は vite.config.ts で定義されたタスク
vp run --filter saas-example setup    # すべての setup:* を並列実行し出力をキャッシュ
vp run --filter saas-example build    # vp build — setup に依存、除外グロブでキャッシュを保持

# その他のコマンド
vp preview                            # ビルド済みアプリケーションのプレビュー (このディレクトリから実行)
vp run --filter saas-example storybook:dev    # Storybook 開発 (スクリプト)
vp run --filter saas-example storybook:build  # Storybook ビルド (スクリプト)
```

### セットアップタスク

`setup` は Vite+ タスクで、`dependsOn` を介して 4 つのサブタスクにファンアウトします。`build` は `setup` に依存するため、`vp run build` (または `vp run -r build`) を実行すると、入力が変更されたときに自動的に生成ファイルが更新されます。適切な入力除外設定により、繰り返し実行してもキャッシュがヒットします:

- `setup:cloudflare` — `wrangler types` (Cloudflare Worker バインディング)
- `setup:paraglide` — `paraglide-js compile` (i18n メッセージ型)
- `setup:tsr` — `tsr generate` (TanStack Router ツリー)
- `setup:kysely` — `atlas-to-kysely` (Atlas スキーマからの Kysely 型定義)

`check` / `fix` / `test` はルートレベルのタスク (`vp check` / `vp check --fix` / `vp test`) であり、Vite+ のワークスペースリント/型チェックパスを介してこのアプリをカバーします — アプリごとの `check` タスクはありません。

### データベース操作

以下のコマンドは `task db:dev` の実行中に使用できます。

```bash
# スキーマ変更の適用
task db:schema:apply

# データベースのリセットとスキーマの再適用
task db:reset && task db:schema:apply

# 新しいマイグレーションの作成
task db:migrate:diff

# マイグレーションの適用
task db:migrate:apply
```

> **警告**: マイグレーションコマンド (`db:migrate:diff`, `db:migrate:apply`) はデータベースをリセットします。実行する前に重要なデータをバックアップしてください。

## アーキテクチャ

- `src/entry.worker.ts` - Cloudflare Worker エントリポイント
- `src/entry.hono.ts` - Hono サーバー初期化
- `src/router.tsx` - TanStack Router 設定
- `src/routes/` - ファイルベースのルート定義
- `src/api/` - API エンドポイント
- `src/feature/` - 機能モジュール (auth, db, i18n, share)
- `messages/` - i18n 翻訳ファイル
- `db/` - データベーススキーマ (Atlas)

パスエイリアス: `#@/*` は `./src/*` にマップされます