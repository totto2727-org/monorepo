import { CheckIcon, DeleteIcon, EditIcon, PlusIcon } from "../ui/icons/icon.js"

export function DataSourcesManager() {
  // モックデータ
  const dataSources = [
    {
      createdAt: "2025-01-05T10:30:00Z",
      id: "ds_001",
      lastUpdated: "2025-01-05T15:45:00Z",
      sources: [
        {
          type: "text",
          url: "https://effect.website/docs/getting-started",
        },
      ],
      status: "active",
      target: "effect",
    },
  ]

  const availableTypes = [
    { label: "テキスト", value: "text" },
    { label: "Firecrawl", value: "firecrawl" },
  ]

  const availableTargets = [{ label: "Effect", value: "effect" }]

  return (
    <div class="space-y-6">
      {/* ページヘッダー */}
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">データソース管理</h1>
        <button
          class="btn btn-primary"
          onclick="document.getElementById('add-datasource-modal').showModal()"
          type="button"
        >
          <PlusIcon ariaLabel="追加アイコン" size="sm" />
          新しいデータソースを追加
        </button>
      </div>

      {/* 統計サマリー */}
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="stat bg-base-100 rounded-lg shadow">
          <div class="stat-title">総データソース数</div>
          <div class="stat-value text-primary">{dataSources.length}</div>
        </div>
        <div class="stat bg-base-100 rounded-lg shadow">
          <div class="stat-title">稼働中</div>
          <div class="stat-value text-success">
            {dataSources.filter((ds) => ds.status === "active").length}
          </div>
        </div>
        <div class="stat bg-base-100 rounded-lg shadow">
          <div class="stat-title">対象ドキュメント</div>
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
                hx-get="/app/admin/api/data-sources/search"
                hx-target="#datasources-table"
                hx-trigger="keyup changed delay:300ms"
                id="datasource-search"
                name="search"
                placeholder="データソースで検索..."
                type="text"
              />
            </div>
            <div class="form-control">
              <select
                class="select select-bordered"
                hx-get="/app/admin/api/data-sources/filter"
                hx-target="#datasources-table"
                hx-trigger="change"
                id="datasource-filter"
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

      {/* データソース一覧テーブル */}
      <div class="card bg-base-100 shadow-lg">
        <div class="card-body">
          <div class="overflow-x-auto" id="datasources-table">
            <table class="table table-zebra">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>対象ドキュメント</th>
                  <th>データソース</th>
                  <th>ステータス</th>
                  <th>最終更新</th>
                  <th>操作</th>
                </tr>
              </thead>
              <tbody>
                {dataSources.map((ds) => (
                  <tr key={ds.id}>
                    <td>
                      <div class="font-mono text-sm">{ds.id}</div>
                    </td>
                    <td>
                      <div class="badge badge-outline">{ds.target}</div>
                    </td>
                    <td>
                      <div class="space-y-1">
                        {ds.sources.map((source, index) => (
                          <div
                            class="flex items-center gap-2"
                            key={`${ds.id}-source-${index}`}
                          >
                            <div class="badge badge-sm">{source.type}</div>
                            <div class="text-sm text-base-content/70 truncate max-w-xs">
                              {source.url}
                            </div>
                          </div>
                        ))}
                      </div>
                    </td>
                    <td>
                      <div
                        class={`badge ${ds.status === "active" ? "badge-success" : "badge-warning"}`}
                      >
                        {ds.status === "active" ? "稼働中" : "停止中"}
                      </div>
                    </td>
                    <td>
                      <div class="text-sm">
                        {new Date(ds.lastUpdated).toLocaleString("ja-JP")}
                      </div>
                    </td>
                    <td>
                      <div class="flex gap-2">
                        <button
                          class="btn btn-sm btn-outline"
                          onclick={`editDataSource('${ds.id}')`}
                          type="button"
                        >
                          <EditIcon ariaLabel="編集アイコン" size="sm" />
                        </button>
                        <button
                          class="btn btn-sm btn-error btn-outline"
                          onclick={`deleteDataSource('${ds.id}')`}
                          type="button"
                        >
                          <DeleteIcon ariaLabel="削除アイコン" size="sm" />
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

      {/* 新規データソース追加モーダル */}
      <dialog class="modal" id="add-datasource-modal">
        <div class="modal-box w-11/12 max-w-2xl">
          <h3 class="font-bold text-lg mb-4">新しいデータソースを追加</h3>

          <form
            class="space-y-4"
            hx-on="htmx:afterRequest: if(event.detail.successful) document.getElementById('add-datasource-modal').close()"
            hx-post="/app/admin/api/data-sources"
            hx-target="#datasources-table"
          >
            {/* 対象ドキュメント */}
            <div class="form-control">
              <label class="label" htmlFor="datasource-target">
                <span class="label-text font-semibold">対象ドキュメント</span>
                <span class="label-text-alt text-error">必須</span>
              </label>
              <select
                class="select select-bordered"
                id="datasource-target"
                name="target"
                required
              >
                <option value="">対象を選択</option>
                {availableTargets.map((target) => (
                  <option key={target.value} value={target.value}>
                    {target.label}
                  </option>
                ))}
              </select>
            </div>

            {/* データソース設定 */}
            <div class="form-control">
              <label class="label" htmlFor="datasource-list">
                <span class="label-text font-semibold">データソース</span>
                <span class="label-text-alt text-error">最低1つ必須</span>
              </label>
              <div class="space-y-3" id="datasource-list">
                <div class="border border-base-300 rounded-lg p-4 datasource-item">
                  <div class="flex items-center justify-between mb-3">
                    <span class="font-medium">データソース #1</span>
                    <button
                      class="btn btn-sm btn-ghost btn-circle"
                      onclick="removeDataSource(this)"
                      type="button"
                    >
                      <DeleteIcon ariaLabel="削除" size="sm" />
                    </button>
                  </div>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div class="form-control">
                      <label class="label" htmlFor="datasource-0-type">
                        <span class="label-text">タイプ</span>
                      </label>
                      <select
                        class="select select-bordered select-sm"
                        id="datasource-0-type"
                        name="datasources[0][type]"
                        required
                      >
                        <option value="">選択</option>
                        {availableTypes.map((type) => (
                          <option key={type.value} value={type.value}>
                            {type.label}
                          </option>
                        ))}
                      </select>
                    </div>
                    <div class="form-control">
                      <label class="label" htmlFor="datasource-0-url">
                        <span class="label-text">URL</span>
                      </label>
                      <input
                        class="input input-bordered input-sm"
                        id="datasource-0-url"
                        name="datasources[0][url]"
                        placeholder="https://example.com"
                        required
                        type="url"
                      />
                    </div>
                  </div>
                </div>
              </div>
              <button
                class="btn btn-sm btn-outline mt-3"
                onclick="addDataSourceField()"
                type="button"
              >
                <PlusIcon ariaLabel="追加" size="sm" />
                データソースを追加
              </button>
            </div>

            <div class="modal-action">
              <button class="btn btn-primary" type="submit">
                <CheckIcon ariaLabel="保存アイコン" size="sm" />
                追加
              </button>
              <button
                class="btn btn-outline"
                onclick="document.getElementById('add-datasource-modal').close()"
                type="button"
              >
                キャンセル
              </button>
            </div>
          </form>
        </div>
        <form class="modal-backdrop" method="dialog">
          <button type="button">close</button>
        </form>
      </dialog>

      {/* JavaScript for client-side interactions */}
      <script>
        {`
          let dataSourceIndex = 1;

          function addDataSourceField() {
            const container = document.getElementById('datasource-list');
            const newItem = document.createElement('div');
            newItem.className = 'border border-base-300 rounded-lg p-4 datasource-item';
            newItem.innerHTML = \`
              <div class="flex items-center justify-between mb-3">
                <span class="font-medium">データソース #\${dataSourceIndex + 1}</span>
                <button class="btn btn-sm btn-ghost btn-circle" onclick="removeDataSource(this)" type="button">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" role="img" aria-label="削除">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                  </svg>
                </button>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">タイプ</span>
                  </label>
                  <select class="select select-bordered select-sm" name="datasources[\${dataSourceIndex}][type]" required>
                    <option value="">選択</option>
                    <option value="text">テキスト</option>
                    <option value="firecrawl">Firecrawl</option>
                  </select>
                </div>
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">URL</span>
                  </label>
                  <input class="input input-bordered input-sm" name="datasources[\${dataSourceIndex}][url]" placeholder="https://example.com" required type="url" />
                </div>
              </div>
            \`;
            container.appendChild(newItem);
            dataSourceIndex++;
          }

          function removeDataSource(button) {
            const item = button.closest('.datasource-item');
            const container = document.getElementById('datasource-list');
            if (container.children.length > 1) {
              item.remove();
            } else {
              alert('最低1つのデータソースが必要です。');
            }
          }

          function editDataSource(dataSourceId) {
            htmx.ajax('GET', '/app/admin/api/data-sources/' + dataSourceId + '/edit', {
              target: '#edit-datasource-content',
              swap: 'innerHTML'
            }).then(() => {
              document.getElementById('edit-datasource-modal').showModal();
            });
          }

          function deleteDataSource(dataSourceId) {
            if (confirm('このデータソースを削除してもよろしいですか？この操作は取り消せません。')) {
              htmx.ajax('DELETE', '/app/admin/api/data-sources/' + dataSourceId, {
                target: '#datasources-table',
                swap: 'outerHTML'
              });
            }
          }
        `}
      </script>

      {/* 編集モーダル（動的に内容が挿入される） */}
      <dialog class="modal" id="edit-datasource-modal">
        <div class="modal-box w-11/12 max-w-2xl">
          <div id="edit-datasource-content">
            {/* HTMXで内容が動的に挿入される */}
          </div>
        </div>
        <form class="modal-backdrop" method="dialog">
          <button type="button">close</button>
        </form>
      </dialog>
    </div>
  )
}
