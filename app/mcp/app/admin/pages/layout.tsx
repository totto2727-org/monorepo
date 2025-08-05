import type { PropsWithChildren } from "hono/jsx"
import {
  DashboardIcon,
  MenuIcon,
  ServerIcon,
  SystemIcon,
  ToolsIcon,
} from "../ui/icons/icon.js"

export function AdminLayout({ children }: PropsWithChildren) {
  return (
    <div class="min-h-screen bg-base-200">
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
                  <a
                    class="flex items-center gap-3"
                    href="/app/admin"
                    hx-get="/app/admin"
                    hx-push-url="true"
                    hx-target="main"
                  >
                    <DashboardIcon ariaLabel="ダッシュボードアイコン" />
                    ダッシュボード
                  </a>
                </li>
                <li>
                  <a
                    class="flex items-center gap-3"
                    href="/app/admin/server"
                    hx-get="/app/admin/server"
                    hx-push-url="true"
                    hx-target="main"
                  >
                    <ServerIcon ariaLabel="サーバー設定アイコン" />
                    サーバー設定
                  </a>
                </li>
                <li>
                  <a
                    class="flex items-center gap-3"
                    href="/app/admin/tools"
                    hx-get="/app/admin/tools"
                    hx-push-url="true"
                    hx-target="main"
                  >
                    <ToolsIcon ariaLabel="検索ツールアイコン" />
                    検索ツール
                  </a>
                </li>
                <li>
                  <a
                    class="flex items-center gap-3"
                    href="/app/admin/system"
                    hx-get="/app/admin/system"
                    hx-push-url="true"
                    hx-target="main"
                  >
                    <SystemIcon ariaLabel="システム設定アイコン" />
                    システム設定
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
