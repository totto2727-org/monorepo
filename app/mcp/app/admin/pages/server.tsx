export function ServerConfig() {
  // モックデータ
  const currentConfig = {
    description: "Effect documentation search MCP server",
    lastUpdated: "2025-01-05T10:30:00Z",
    name: "totto-docs-mcp-server",
    version: "1.0.0",
  }

  return (
    <div class="space-y-6">
      {/* ページヘッダー */}
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">サーバー設定</h1>
        <div class="badge badge-info">編集モード</div>
      </div>

      {/* 基本設定フォーム */}
      <div class="card bg-base-100 shadow-lg">
        <div class="card-body">
          <h2 class="card-title mb-4">基本設定</h2>

          <form
            class="space-y-4"
            hx-indicator="#save-spinner"
            hx-put="/app/admin/api/server"
            hx-target="#save-status"
          >
            {/* サーバー名 */}
            <div class="form-control">
              <label class="label" htmlFor="server-name">
                <span class="label-text font-semibold">サーバー名</span>
                <span class="label-text-alt text-error">必須</span>
              </label>
              <input
                class="input input-bordered w-full"
                id="server-name"
                maxLength={50}
                minLength={3}
                name="name"
                placeholder="サーバー名を入力"
                required
                type="text"
                value={currentConfig.name}
              />
              <label class="label" htmlFor="server-name">
                <span class="label-text-alt">
                  MCPクライアントに表示される識別名
                </span>
              </label>
            </div>

            {/* バージョン */}
            <div class="form-control">
              <label class="label" htmlFor="server-version">
                <span class="label-text font-semibold">バージョン</span>
                <span class="label-text-alt text-error">必須</span>
              </label>
              <input
                class="input input-bordered w-full"
                id="server-version"
                name="version"
                pattern="^\d+\.\d+\.\d+$"
                placeholder="1.0.0"
                required
                type="text"
                value={currentConfig.version}
              />
              <label class="label" htmlFor="server-version">
                <span class="label-text-alt">
                  セマンティックバージョニング形式 (例: 1.0.0)
                </span>
              </label>
            </div>

            {/* 説明 */}
            <div class="form-control">
              <label class="label" htmlFor="server-description">
                <span class="label-text font-semibold">説明</span>
                <span class="label-text-alt">任意</span>
              </label>
              <textarea
                class="textarea textarea-bordered h-24"
                id="server-description"
                maxLength={200}
                name="description"
                placeholder="サーバーの説明を入力"
              >
                {currentConfig.description}
              </textarea>
              <label class="label" htmlFor="server-description">
                <span class="label-text-alt">サーバーの用途や機能の説明</span>
              </label>
            </div>

            {/* 保存ボタン */}
            <div class="flex items-center gap-4">
              <button class="btn btn-primary" type="submit">
                <svg
                  aria-label="保存アイコン"
                  class="w-4 h-4"
                  fill="none"
                  role="img"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    d="M5 13l4 4L19 7"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                  ></path>
                </svg>
                設定を保存
              </button>

              <button class="btn btn-outline" type="reset">
                <svg
                  aria-label="リセットアイコン"
                  class="w-4 h-4"
                  fill="none"
                  role="img"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                  ></path>
                </svg>
                リセット
              </button>

              <div
                class="htmx-indicator loading loading-spinner loading-sm"
                id="save-spinner"
              ></div>
            </div>

            {/* 保存ステータス */}
            <div id="save-status"></div>
          </form>
        </div>
      </div>

      {/* 詳細情報 */}
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 現在の設定 */}
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title">現在の設定</h2>
            <div class="space-y-3">
              <div class="flex justify-between items-center">
                <span class="font-medium">サーバー名:</span>
                <span class="badge badge-outline">{currentConfig.name}</span>
              </div>
              <div class="flex justify-between items-center">
                <span class="font-medium">バージョン:</span>
                <span class="badge badge-secondary">
                  {currentConfig.version}
                </span>
              </div>
              <div class="flex justify-between items-center">
                <span class="font-medium">最終更新:</span>
                <span class="text-sm text-base-content/70">
                  {new Date(currentConfig.lastUpdated).toLocaleString("ja-JP")}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* 設定の注意事項 */}
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title text-warning">
              <svg
                aria-label="警告アイコン"
                class="w-5 h-5"
                fill="none"
                role="img"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16c-.77.833.192 2.5 1.732 2.5z"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                ></path>
              </svg>
              重要な注意事項
            </h2>
            <ul class="space-y-2 text-sm">
              <li class="flex items-start gap-2">
                <svg
                  aria-label="情報アイコン"
                  class="w-4 h-4 mt-0.5 text-info"
                  fill="none"
                  role="img"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                  ></path>
                </svg>
                設定変更後はサーバーの再起動が必要です
              </li>
              <li class="flex items-start gap-2">
                <svg
                  aria-label="情報アイコン"
                  class="w-4 h-4 mt-0.5 text-info"
                  fill="none"
                  role="img"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                  ></path>
                </svg>
                サーバー名は接続済みクライアントに影響します
              </li>
              <li class="flex items-start gap-2">
                <svg
                  aria-label="情報アイコン"
                  class="w-4 h-4 mt-0.5 text-info"
                  fill="none"
                  role="img"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                  ></path>
                </svg>
                バージョンは適切なセマンティックバージョニングを使用してください
              </li>
            </ul>
          </div>
        </div>
      </div>

      {/* 操作履歴 */}
      <div class="card bg-base-100 shadow-lg">
        <div class="card-body">
          <h2 class="card-title">最近の変更履歴</h2>
          <div class="overflow-x-auto">
            <table class="table table-zebra">
              <thead>
                <tr>
                  <th>日時</th>
                  <th>変更項目</th>
                  <th>変更前</th>
                  <th>変更後</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>2025-01-05 10:30</td>
                  <td>サーバー作成</td>
                  <td>-</td>
                  <td>初期設定</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  )
}
