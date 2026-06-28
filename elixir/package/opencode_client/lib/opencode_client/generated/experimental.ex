defmodule OpencodeClient.Generated.Experimental do
  @moduledoc """
  Provides API endpoints related to experimental
  """

  @default_client OpencodeClient.Client

  @doc """
  Get active Console provider metadata

  Get the active Console org name and the set of provider IDs managed by that Console org.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec experimental_console_get(opts :: keyword) ::
          {:ok, OpencodeClient.Generated.ConsoleState.t()}
          | {:error,
             OpencodeClient.Generated.BadRequestError.t()
             | OpencodeClient.Generated.EffectHttpApiErrorInternalServerError.t()}
  def experimental_console_get(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Experimental, :experimental_console_get},
      url: "/experimental/console",
      method: :get,
      query: query,
      response: [
        {200, {OpencodeClient.Generated.ConsoleState, :t}},
        {400, {OpencodeClient.Generated.BadRequestError, :t}},
        {500, {OpencodeClient.Generated.EffectHttpApiErrorInternalServerError, :t}}
      ],
      opts: opts
    })
  end

  @type experimental_console_list_orgs_200_json_resp :: %{
          orgs: [
            OpencodeClient.Generated.Experimental.experimental_console_list_orgs_200_json_resp_orgs()
          ]
        }

  @type experimental_console_list_orgs_200_json_resp_orgs :: %{
          accountEmail: String.t(),
          accountID: String.t(),
          accountUrl: String.t(),
          active: boolean,
          orgID: String.t(),
          orgName: String.t()
        }

  @doc """
  List switchable Console orgs

  Get the available Console orgs across logged-in accounts, including the current active org.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec experimental_console_list_orgs(opts :: keyword) ::
          {:ok,
           OpencodeClient.Generated.Experimental.experimental_console_list_orgs_200_json_resp()}
          | {:error,
             OpencodeClient.Generated.BadRequestError.t()
             | OpencodeClient.Generated.EffectHttpApiErrorInternalServerError.t()}
  def experimental_console_list_orgs(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Experimental, :experimental_console_list_orgs},
      url: "/experimental/console/orgs",
      method: :get,
      query: query,
      response: [
        {200,
         {OpencodeClient.Generated.Experimental, :experimental_console_list_orgs_200_json_resp}},
        {400, {OpencodeClient.Generated.BadRequestError, :t}},
        {500, {OpencodeClient.Generated.EffectHttpApiErrorInternalServerError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Switch active Console org

  Persist a new active Console account/org selection for the current local OpenCode state.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec experimental_console_switch_org(body :: map, opts :: keyword) :: {:ok, boolean} | :error
  def experimental_console_switch_org(body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [body: body],
      call: {OpencodeClient.Generated.Experimental, :experimental_console_switch_org},
      url: "/experimental/console/switch",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", :map}],
      response: [{200, :boolean}],
      opts: opts
    })
  end

  @doc """
  Get MCP resources

  Get all available MCP resources from connected servers. Optionally filter by name.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec experimental_resource_list(opts :: keyword) ::
          {:ok, map} | {:error, OpencodeClient.Generated.BadRequestError.t()}
  def experimental_resource_list(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Experimental, :experimental_resource_list},
      url: "/experimental/resource",
      method: :get,
      query: query,
      response: [{200, :map}, {400, {OpencodeClient.Generated.BadRequestError, :t}}],
      opts: opts
    })
  end

  @doc """
  List sessions

  Get a list of all OpenCode sessions across projects, sorted by most recently updated. Archived sessions are excluded by default.

  ## Options

    * `directory`
    * `workspace`
    * `roots`
    * `start`
    * `cursor`
    * `search`
    * `limit`
    * `archived`

  """
  @spec experimental_session_list(opts :: keyword) ::
          {:ok, [OpencodeClient.Generated.GlobalSession.t()]}
          | {:error, OpencodeClient.Generated.BadRequestError.t()}
  def experimental_session_list(opts \\ []) do
    client = opts[:client] || @default_client

    query =
      Keyword.take(opts, [
        :archived,
        :cursor,
        :directory,
        :limit,
        :roots,
        :search,
        :start,
        :workspace
      ])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Experimental, :experimental_session_list},
      url: "/experimental/session",
      method: :get,
      query: query,
      response: [
        {200, [{OpencodeClient.Generated.GlobalSession, :t}]},
        {400, {OpencodeClient.Generated.BadRequestError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  List tool IDs

  Get a list of all available tool IDs, including both built-in tools and dynamically registered tools.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec tool_ids(opts :: keyword) ::
          {:ok, [String.t()]}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()}
  def tool_ids(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Experimental, :tool_ids},
      url: "/experimental/tool/ids",
      method: :get,
      query: query,
      response: [
        {200, [:string]},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}}
      ],
      opts: opts
    })
  end

  @doc """
  List tools

  Get a list of available tools with their JSON schema parameters for a specific provider and model combination.

  ## Options

    * `directory`
    * `workspace`
    * `provider`
    * `model`

  """
  @spec tool_list(opts :: keyword) ::
          {:ok, [OpencodeClient.Generated.ToolListItem.t()]}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()}
  def tool_list(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :model, :provider, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Experimental, :tool_list},
      url: "/experimental/tool",
      method: :get,
      query: query,
      response: [
        {200, [{OpencodeClient.Generated.ToolListItem, :t}]},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}}
      ],
      opts: opts
    })
  end

  @doc """
  Create worktree

  Create a new git worktree for the current project and run any configured startup scripts.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec worktree_create(body :: OpencodeClient.Generated.WorktreeCreateInput.t(), opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Worktree.t()}
          | {:error,
             OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.WorktreeError.t()}
  def worktree_create(body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [body: body],
      call: {OpencodeClient.Generated.Experimental, :worktree_create},
      url: "/experimental/worktree",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", {OpencodeClient.Generated.WorktreeCreateInput, :t}}],
      response: [
        {200, {OpencodeClient.Generated.Worktree, :t}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.InvalidRequestError, :t},
            {OpencodeClient.Generated.WorktreeError, :t}
          ]}}
      ],
      opts: opts
    })
  end

  @doc """
  List worktrees

  List all sandbox worktrees for the current project.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec worktree_list(opts :: keyword) ::
          {:ok, [String.t()]}
          | {:error,
             OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.WorktreeError.t()}
  def worktree_list(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Experimental, :worktree_list},
      url: "/experimental/worktree",
      method: :get,
      query: query,
      response: [
        {200, [:string]},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.InvalidRequestError, :t},
            {OpencodeClient.Generated.WorktreeError, :t}
          ]}}
      ],
      opts: opts
    })
  end

  @doc """
  Remove worktree

  Remove a git worktree and delete its branch.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec worktree_remove(body :: OpencodeClient.Generated.WorktreeRemoveInput.t(), opts :: keyword) ::
          {:ok, boolean}
          | {:error,
             OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.WorktreeError.t()}
  def worktree_remove(body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [body: body],
      call: {OpencodeClient.Generated.Experimental, :worktree_remove},
      url: "/experimental/worktree",
      body: body,
      method: :delete,
      query: query,
      request: [{"application/json", {OpencodeClient.Generated.WorktreeRemoveInput, :t}}],
      response: [
        {200, :boolean},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.InvalidRequestError, :t},
            {OpencodeClient.Generated.WorktreeError, :t}
          ]}}
      ],
      opts: opts
    })
  end

  @doc """
  Reset worktree

  Reset a worktree branch to the primary default branch.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec worktree_reset(body :: OpencodeClient.Generated.WorktreeResetInput.t(), opts :: keyword) ::
          {:ok, boolean}
          | {:error,
             OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.WorktreeError.t()}
  def worktree_reset(body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [body: body],
      call: {OpencodeClient.Generated.Experimental, :worktree_reset},
      url: "/experimental/worktree/reset",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", {OpencodeClient.Generated.WorktreeResetInput, :t}}],
      response: [
        {200, :boolean},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.InvalidRequestError, :t},
            {OpencodeClient.Generated.WorktreeError, :t}
          ]}}
      ],
      opts: opts
    })
  end

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(:experimental_console_list_orgs_200_json_resp) do
    [
      orgs: [
        {OpencodeClient.Generated.Experimental,
         :experimental_console_list_orgs_200_json_resp_orgs}
      ]
    ]
  end

  def __fields__(:experimental_console_list_orgs_200_json_resp_orgs) do
    [
      accountEmail: :string,
      accountID: :string,
      accountUrl: :string,
      active: :boolean,
      orgID: :string,
      orgName: :string
    ]
  end
end
