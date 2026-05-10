# @app/rss-graphql

RSSフィードの処理とクエリのためのGraphQL APIサーバー。

## 技術スタック

- **ランタイム**: Cloudflare Workers
- **フレームワーク**: Hono
- **GraphQL**: Pothosスキーマビルダー + GraphQL Scalars
- **RSS**: @mikaelporttila/rss（フィード解析）
- **FP**: Effect（関数型エラーハンドリング）
- **ビルド**: Vite + @cloudflare/vite-plugin

## 開発

```bash
# 開発サーバーを起動（このディレクトリから実行、vp組み込み）
vp dev

# Wranglerローカルサーバーを起動（package.jsonスクリプト）
vp run --filter @app/rss-graphql start

# リント、フォーマット、型チェック — ルートの `check` タスク（ワークスペース全体）
vp run check

# Cloudflareにデプロイ（package.jsonスクリプト）
vp run --filter @app/rss-graphql deploy
```

このパッケージには `build` / `setup` タスクはありません。デプロイはwranglerが直接行います。

## アーキテクチャ

- `app/entry.worker.ts` - Cloudflare Workerエントリポイント
- `app/app.ts` - メインのHonoアプリケーション
- `app/feature/graphql/` - GraphQLスキーマとリゾルバ
- `app/feature/hono/` - Honoコンテキストユーティリティ

パスエイリアス: `#@/*` は `./app/*` にマッピングされます。
