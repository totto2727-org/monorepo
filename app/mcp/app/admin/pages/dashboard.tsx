export function Dashboard() {
  // モックデータ
  const stats = {
    lastUpdated: "2025-01-05T10:30:00Z",
    serverName: "totto-docs-mcp-server",
    toolsCount: 1,
    version: "1.0.0",
  }

  const recentTools = [
    {
      name: "search_ai_effect",
      status: "active",
      target: "effect",
      title: "Effect Documentation Search",
    },
  ]

  return (
    <div class="space-y-6">
      {/* ページヘッダー */}
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">ダッシュボード</h1>
        <div class="badge badge-success">稼働中</div>
      </div>

      {/* 統計カード */}
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title text-primary">サーバー名</h2>
            <p class="text-2xl font-bold">{stats.serverName}</p>
          </div>
        </div>

        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title text-secondary">バージョン</h2>
            <p class="text-2xl font-bold">{stats.version}</p>
          </div>
        </div>

        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title text-accent">登録ツール数</h2>
            <p class="text-2xl font-bold">{stats.toolsCount}</p>
          </div>
        </div>

        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title text-info">最終更新</h2>
            <p class="text-sm">
              {new Date(stats.lastUpdated).toLocaleDateString("ja-JP")}
            </p>
          </div>
        </div>
      </div>

      {/* 最近の活動 */}
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 登録済みツール */}
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title flex items-center gap-2">
              <svg
                aria-label="登録ツールアイコン"
                class="w-5 h-5"
                fill="none"
                role="img"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                ></path>
                <path
                  d="M15 12a3 3 0 11-6 0 3 3 0 616 0z"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                ></path>
              </svg>
              登録済みツール
            </h2>
            <div class="space-y-3">
              {recentTools.map((tool) => (
                <div
                  class="flex items-center justify-between p-3 bg-base-200 rounded-lg"
                  key={tool.name}
                >
                  <div>
                    <h3 class="font-semibold">{tool.title}</h3>
                    <p class="text-sm text-base-content/70">{tool.name}</p>
                    <div class="badge badge-outline badge-sm mt-1">
                      {tool.target}
                    </div>
                  </div>
                  <div class="badge badge-success">稼働中</div>
                </div>
              ))}
            </div>
            <div class="card-actions justify-end mt-4">
              <a
                class="btn btn-primary btn-sm"
                href="/app/admin/tools"
                hx-get="/app/admin/tools"
                hx-push-url="true"
                hx-target="main"
              >
                すべて表示
              </a>
            </div>
          </div>
        </div>

        {/* クイックアクション */}
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title flex items-center gap-2">
              <svg
                aria-label="クイックアクションアイコン"
                class="w-5 h-5"
                fill="none"
                role="img"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  d="M13 10V3L4 14h7v7l9-11h-7z"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                ></path>
              </svg>
              クイックアクション
            </h2>
            <div class="space-y-3">
              <button
                class="btn btn-outline w-full justify-start"
                hx-get="/app/admin/tools/new"
                hx-push-url="true"
                hx-target="main"
                type="button"
              >
                <svg
                  aria-label="追加アイコン"
                  class="w-4 h-4"
                  fill="none"
                  role="img"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                  ></path>
                </svg>
                新しいツールを追加
              </button>

              <button
                class="btn btn-outline w-full justify-start"
                hx-get="/app/admin/server"
                hx-push-url="true"
                hx-target="main"
                type="button"
              >
                <svg
                  aria-label="設定アイコン"
                  class="w-4 h-4"
                  fill="none"
                  role="img"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                  ></path>
                </svg>
                サーバー設定を変更
              </button>

              <button
                class="btn btn-outline w-full justify-start"
                onclick="location.reload()"
                type="button"
              >
                <svg
                  aria-label="再読み込みアイコン"
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
                設定を再読み込み
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* システム情報 */}
      <div class="card bg-base-100 shadow-lg">
        <div class="card-body">
          <h2 class="card-title">システム情報</h2>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="stat">
              <div class="stat-title">プラットフォーム</div>
              <div class="stat-value text-lg">Cloudflare Workers</div>
            </div>
            <div class="stat">
              <div class="stat-title">フレームワーク</div>
              <div class="stat-value text-lg">Hono + JSX</div>
            </div>
            <div class="stat">
              <div class="stat-title">MCP SDK</div>
              <div class="stat-value text-lg">v1.17.1</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
