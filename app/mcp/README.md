# mcp

## 本番環境構築

### Cloudflare R2

```bash
na wrangler r2 bucket create $NAME
```

```json:wrangler.jsonc
{
  "r2_buckets": [
    {
      "binding": "DATA_SOURCE",
      "bucket_name": "$NAME"
    }
  ]
}
```

### Cloudflare AI Gateway

- 設定しなくても良い
- MCP用に新規で作成することを推奨する
  - ログを有効にする
  - キャッシュを有効にする

TODO: 認証済みゲートウェイを使用する設定を追加する

### Cloudflare Auto Rag

1. 作成したCloudflare R2を選択して次ヘ進む
1. 次へ進む
1. AI Gatewayを生成していた場合は選択、していない場合はデフォルトのまま次へ進む
   - クエリの書き換えを有効にする
   - 類似性キャッシュを有効にする
1. 任意の名前で設定する
1. `wrangler.jsonc`に設定した名前を追加する
   ```json:wrangler.jsonc
   {
     "vars": {
       "AUTO_RAG_NAME": "$AUTO_RAG_NAME"
     }
   }
   ```

### Cloudflare Workers

1. ローカルからデプロイする
1. GitHubと連携する
   - build: `pnpm turbo build`
   - cwd: `app/mcp`
1. ビルド環境の設定をする
   - バージョンは適切に設定すること
   - `NODE_VERSION`
   - `PNPM_VERSION`

### Cloudflare Access

TODO
