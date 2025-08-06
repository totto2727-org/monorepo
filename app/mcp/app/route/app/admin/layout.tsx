import type { PropsWithChildren } from "hono/jsx"
import {
  DashboardIcon,
  MenuIcon,
  ServerIcon,
  ToolsIcon,
} from "#@/ui/icons/icon.js"

export function AdminLayout({ children }: PropsWithChildren) {
  return (
    <div class="min-h-screen bg-base-200" hx-boost="true">
      <div class="navbar bg-base-100 shadow-lg">
        <div class="flex-1">
          <h1 class="btn btn-ghost text-xl">MCP Admin</h1>
        </div>
        <div class="flex-none">
          <button class="btn btn-square btn-ghost" type="button">
            <MenuIcon ariaLabel="Menu Icon" />
          </button>
        </div>
      </div>

      <div class="drawer lg:drawer-open">
        <input class="drawer-toggle" id="drawer-toggle" type="checkbox" />

        <div class="drawer-content flex flex-col">
          <main class="flex-1 p-6">{children}</main>
        </div>

        <div class="drawer-side">
          <label
            aria-label="Close menu"
            class="drawer-overlay"
            htmlFor="drawer-toggle"
          ></label>
          <aside class="w-64 min-h-full bg-base-100">
            <div class="p-4">
              <h2 class="text-lg font-semibold mb-4">Menu</h2>
              <ul class="menu">
                <li>
                  <a class="flex items-center gap-3" href="/app/admin">
                    <DashboardIcon ariaLabel="Dashboard Icon" />
                    Dashboard
                  </a>
                </li>
                <li>
                  <a
                    class="flex items-center gap-3"
                    href="/app/admin/mcp-tool"
                  >
                    <ToolsIcon ariaLabel="MCP Tools Icon" />
                    MCP Tools
                  </a>
                </li>
                <li>
                  <a
                    class="flex items-center gap-3"
                    href="/app/admin/data-source"
                  >
                    <ServerIcon ariaLabel="Data Sources Icon" />
                    Data Sources
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
