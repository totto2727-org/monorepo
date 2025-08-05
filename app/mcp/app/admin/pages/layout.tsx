import type { PropsWithChildren } from "hono/jsx"

export function AdminLayout({ children }: PropsWithChildren) {
  return (
    <div class="min-h-screen bg-base-200">
      {/* Header */}
      <div class="navbar bg-base-100 shadow-lg">
        <div class="flex-1">
          <h1 class="btn btn-ghost text-xl">MCP管理画面</h1>
        </div>
        <div class="flex-none">
          <button class="btn btn-square btn-ghost">
            <svg
              class="inline-block w-5 h-5 stroke-current"
              fill="none"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M5 12h.01M12 12h.01M19 12h.01M6 12a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0z"
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
              ></path>
            </svg>
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
          <label class="drawer-overlay" for="drawer-toggle"></label>
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
                    <svg
                      class="w-5 h-5"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                      ></path>
                    </svg>
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
                    <svg
                      class="w-5 h-5"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                      ></path>
                    </svg>
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
                    <svg
                      class="w-5 h-5"
                      fill="none"
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
                        d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                      ></path>
                    </svg>
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
                    <svg
                      class="w-5 h-5"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                      ></path>
                    </svg>
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
