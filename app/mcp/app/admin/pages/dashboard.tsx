import { ServerIcon, ToolsIcon } from "../ui/icons/icon.js"

export function Dashboard() {
  // シンプルな統計データ
  const stats = {
    dataSourcesCount: 0,
    lastUpdated: "2025-01-05T10:30:00Z",
    mcpToolsCount: 1,
  }

  return (
    <div class="space-y-6">
      {/* ページヘッダー */}
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">管理画面</h1>
        <div class="badge badge-success">稼働中</div>
      </div>

      {/* 統計カード */}
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title text-primary">MCPツール</h2>
            <p class="text-2xl font-bold">{stats.mcpToolsCount}</p>
            <p class="text-sm text-base-content/70">登録済み検索ツール</p>
          </div>
        </div>

        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title text-secondary">データソース</h2>
            <p class="text-2xl font-bold">{stats.dataSourcesCount}</p>
            <p class="text-sm text-base-content/70">設定済みデータソース</p>
          </div>
        </div>

        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title text-info">最終更新</h2>
            <p class="text-sm">
              {new Date(stats.lastUpdated).toLocaleDateString("ja-JP")}
            </p>
            <p class="text-sm text-base-content/70">システム更新日時</p>
          </div>
        </div>
      </div>

      {/* 管理メニュー */}
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* MCPツール管理 */}
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title flex items-center gap-2">
              <ToolsIcon ariaLabel="MCPツールアイコン" size="md" />
              MCPツール管理
            </h2>
            <p class="text-base-content/70">検索ツールの追加・編集・削除</p>
            <div class="card-actions justify-end mt-4">
              <a class="btn btn-primary" href="/app/admin/mcp-tools">
                管理する
              </a>
            </div>
          </div>
        </div>

        {/* データソース管理 */}
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title flex items-center gap-2">
              <ServerIcon ariaLabel="データソースアイコン" size="md" />
              データソース管理
            </h2>
            <p class="text-base-content/70">データ取得元の設定・管理</p>
            <div class="card-actions justify-end mt-4">
              <a class="btn btn-primary" href="/app/admin/data-sources">
                管理する
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
