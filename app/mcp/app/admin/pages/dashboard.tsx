import {
  LightningIcon,
  PlusIcon,
  RefreshIcon,
  ToolsIcon,
} from "../ui/icons/icon.js"

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
              <ToolsIcon ariaLabel="登録ツールアイコン" size="md" />
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
              <LightningIcon ariaLabel="クイックアクションアイコン" size="md" />
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
                <PlusIcon ariaLabel="追加アイコン" size="sm" />
                新しいツールを追加
              </button>

              <button
                class="btn btn-outline w-full justify-start"
                hx-get="/app/admin/server"
                hx-push-url="true"
                hx-target="main"
                type="button"
              >
                <ToolsIcon ariaLabel="設定アイコン" size="sm" />
                サーバー設定を変更
              </button>

              <button
                class="btn btn-outline w-full justify-start"
                onclick="location.reload()"
                type="button"
              >
                <RefreshIcon ariaLabel="再読み込みアイコン" size="sm" />
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
