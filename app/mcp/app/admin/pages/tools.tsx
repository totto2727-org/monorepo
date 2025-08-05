export function ToolsManager() {
  // モックデータ
  const tools = [
    {
      createdAt: "2025-01-05T10:30:00Z",
      description: "Search Effect documentation and generate AI responses",
      id: "search_ai_effect",
      lastUsed: "2025-01-05T15:45:00Z",
      name: "search_ai_effect",
      status: "active",
      target: "effect",
      title: "Effect Documentation Search",
    },
  ]

  const availableTargets = [
    { label: "Effect", value: "effect" },
    { label: "Hono", value: "hono" },
    { label: "React", value: "react" },
    { label: "TypeScript", value: "typescript" },
  ]

  return (
    <div class="space-y-6">
      {/* ページヘッダー */}
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">検索ツール管理</h1>
        <button
          class="btn btn-primary"
          onclick="document.getElementById('add-tool-modal').showModal()"
        >
          <svg
            class="w-4 h-4"
            fill="none"
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
      </div>

      {/* 統計サマリー */}
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="stat bg-base-100 rounded-lg shadow">
          <div class="stat-title">総ツール数</div>
          <div class="stat-value text-primary">{tools.length}</div>
        </div>
        <div class="stat bg-base-100 rounded-lg shadow">
          <div class="stat-title">稼働中</div>
          <div class="stat-value text-success">
            {tools.filter((t) => t.status === "active").length}
          </div>
        </div>
        <div class="stat bg-base-100 rounded-lg shadow">
          <div class="stat-title">利用可能な対象</div>
          <div class="stat-value text-info">{availableTargets.length}</div>
        </div>
      </div>

      {/* 検索・フィルター */}
      <div class="card bg-base-100 shadow-lg">
        <div class="card-body">
          <div class="flex flex-col md:flex-row gap-4">
            <div class="form-control flex-1">
              <input
                class="input input-bordered"
                hx-get="/app/admin/api/tools/search"
                hx-target="#tools-table"
                hx-trigger="keyup changed delay:300ms"
                name="search"
                placeholder="ツール名で検索..."
                type="text"
              />
            </div>
            <div class="form-control">
              <select
                class="select select-bordered"
                hx-get="/app/admin/api/tools/filter"
                hx-target="#tools-table"
                hx-trigger="change"
                name="target"
              >
                <option value="">すべての対象</option>
                {availableTargets.map((target) => (
                  <option key={target.value} value={target.value}>
                    {target.label}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>
      </div>

      {/* ツール一覧テーブル */}
      <div class="card bg-base-100 shadow-lg">
        <div class="card-body">
          <div class="overflow-x-auto" id="tools-table">
            <table class="table table-zebra">
              <thead>
                <tr>
                  <th>ツール名</th>
                  <th>表示名</th>
                  <th>対象</th>
                  <th>ステータス</th>
                  <th>最終使用</th>
                  <th>操作</th>
                </tr>
              </thead>
              <tbody>
                {tools.map((tool) => (
                  <tr key={tool.id}>
                    <td>
                      <div class="font-mono text-sm">{tool.name}</div>
                    </td>
                    <td>
                      <div>
                        <div class="font-semibold">{tool.title}</div>
                        <div class="text-sm text-base-content/70 truncate max-w-xs">
                          {tool.description}
                        </div>
                      </div>
                    </td>
                    <td>
                      <div class="badge badge-outline">{tool.target}</div>
                    </td>
                    <td>
                      <div
                        class={`badge ${tool.status === "active" ? "badge-success" : "badge-warning"}`}
                      >
                        {tool.status === "active" ? "稼働中" : "停止中"}
                      </div>
                    </td>
                    <td>
                      <div class="text-sm">
                        {new Date(tool.lastUsed).toLocaleString("ja-JP")}
                      </div>
                    </td>
                    <td>
                      <div class="flex gap-2">
                        <button
                          class="btn btn-sm btn-outline"
                          onclick={`editTool('${tool.id}')`}
                        >
                          <svg
                            class="w-4 h-4"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                          >
                            <path
                              d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                            ></path>
                          </svg>
                        </button>
                        <button
                          class="btn btn-sm btn-error btn-outline"
                          onclick={`deleteTool('${tool.id}')`}
                        >
                          <svg
                            class="w-4 h-4"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                          >
                            <path
                              d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                            ></path>
                          </svg>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* 新規ツール追加モーダル */}
      <dialog class="modal" id="add-tool-modal">
        <div class="modal-box w-11/12 max-w-2xl">
          <h3 class="font-bold text-lg mb-4">新しい検索ツールを追加</h3>

          <form
            class="space-y-4"
            hx-on="htmx:afterRequest: if(event.detail.successful) document.getElementById('add-tool-modal').close()"
            hx-post="/app/admin/api/tools"
            hx-target="#tools-table"
          >
            {/* ツール名 */}
            <div class="form-control">
              <label class="label">
                <span class="label-text font-semibold">ツール名</span>
                <span class="label-text-alt text-error">必須</span>
              </label>
              <input
                class="input input-bordered"
                name="name"
                pattern="^[a-z][a-z0-9_]*$"
                placeholder="search_ai_example"
                required
                type="text"
              />
              <label class="label">
                <span class="label-text-alt">
                  英小文字、数字、アンダースコアのみ。先頭は文字
                </span>
              </label>
            </div>

            {/* 表示名 */}
            <div class="form-control">
              <label class="label">
                <span class="label-text font-semibold">表示名</span>
                <span class="label-text-alt text-error">必須</span>
              </label>
              <input
                class="input input-bordered"
                maxLength={100}
                name="title"
                placeholder="Example Documentation Search"
                required
                type="text"
              />
            </div>

            {/* 説明 */}
            <div class="form-control">
              <label class="label">
                <span class="label-text font-semibold">説明</span>
                <span class="label-text-alt text-error">必須</span>
              </label>
              <textarea
                class="textarea textarea-bordered h-24"
                maxLength={300}
                name="description"
                placeholder="このツールの機能と用途を説明してください"
                required
              ></textarea>
            </div>

            {/* 対象 */}
            <div class="form-control">
              <label class="label">
                <span class="label-text font-semibold">検索対象</span>
                <span class="label-text-alt text-error">必須</span>
              </label>
              <select class="select select-bordered" name="target" required>
                <option value="">対象を選択</option>
                {availableTargets.map((target) => (
                  <option key={target.value} value={target.value}>
                    {target.label}
                  </option>
                ))}
              </select>
            </div>

            <div class="modal-action">
              <button class="btn btn-primary" type="submit">
                <svg
                  class="w-4 h-4"
                  fill="none"
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
                追加
              </button>
              <button
                class="btn btn-outline"
                onclick="document.getElementById('add-tool-modal').close()"
                type="button"
              >
                キャンセル
              </button>
            </div>
          </form>
        </div>
        <form class="modal-backdrop" method="dialog">
          <button>close</button>
        </form>
      </dialog>

      {/* JavaScript for client-side interactions */}
      <script>
        {`
          function editTool(toolId) {
            // HTMXで編集フォームを取得して表示
            htmx.ajax('GET', '/app/admin/api/tools/' + toolId + '/edit', {
              target: '#edit-tool-content',
              swap: 'innerHTML'
            }).then(() => {
              document.getElementById('edit-tool-modal').showModal();
            });
          }

          function deleteTool(toolId) {
            if (confirm('このツールを削除してもよろしいですか？この操作は取り消せません。')) {
              htmx.ajax('DELETE', '/app/admin/api/tools/' + toolId, {
                target: '#tools-table',
                swap: 'outerHTML'
              });
            }
          }
        `}
      </script>

      {/* 編集モーダル（動的に内容が挿入される） */}
      <dialog class="modal" id="edit-tool-modal">
        <div class="modal-box w-11/12 max-w-2xl">
          <div id="edit-tool-content">{/* HTMXで内容が動的に挿入される */}</div>
        </div>
        <form class="modal-backdrop" method="dialog">
          <button>close</button>
        </form>
      </dialog>
    </div>
  )
}
