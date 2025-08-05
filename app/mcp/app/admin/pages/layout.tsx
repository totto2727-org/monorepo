import type { PropsWithChildren } from "hono/jsx"
import {
  DashboardIcon,
  MenuIcon,
  ServerIcon,
  ToolsIcon,
} from "../ui/icons/icon.js"

export function AdminLayout({ children }: PropsWithChildren) {
  return (
    <div class="min-h-screen bg-base-200" hx-boost="true">
      {/* Header */}
      <div class="navbar bg-base-100 shadow-lg">
        <div class="flex-1">
          <h1 class="btn btn-ghost text-xl">MCP管理画面</h1>
        </div>
        <div class="flex-none">
          <button class="btn btn-square btn-ghost" type="button">
            <MenuIcon ariaLabel="メニューアイコン" />
          </button>
        </div>
      </div>

      <div class="drawer lg:drawer-open">
        <input class="drawer-toggle" id="drawer-toggle" type="checkbox" />

        {/* Page content */}
        <div class="drawer-content flex flex-col">
          <main class="flex-1 p-6">{children}</main>
        </div>

        {/* Sidebar */}
        <div class="drawer-side">
          <label
            aria-label="メニューを閉じる"
            class="drawer-overlay"
            htmlFor="drawer-toggle"
          ></label>
          <aside class="w-64 min-h-full bg-base-100">
            <div class="p-4">
              <h2 class="text-lg font-semibold mb-4">メニュー</h2>
              <ul class="menu">
                <li>
                  <a class="flex items-center gap-3" href="/app/admin">
                    <DashboardIcon ariaLabel="ダッシュボードアイコン" />
                    ダッシュボード
                  </a>
                </li>
                <li>
                  <a
                    class="flex items-center gap-3"
                    href="/app/admin/mcp-tools"
                  >
                    <ToolsIcon ariaLabel="MCPツールアイコン" />
                    MCPツール
                  </a>
                </li>
                <li>
                  <a
                    class="flex items-center gap-3"
                    href="/app/admin/data-sources"
                  >
                    <ServerIcon ariaLabel="データソースアイコン" />
                    データソース
                  </a>
                </li>
              </ul>
            </div>
          </aside>
        </div>
      </div>
    </div>
  )
}
