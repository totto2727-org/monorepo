defmodule OpencodeClient.Generated.Sync do
  @moduledoc """
  Provides API endpoints related to sync
  """

  @default_client OpencodeClient.Generated.Client

  @type sync_history_list_200_json_resp :: %{
          aggregate_id: String.t(),
          data: map,
          id: String.t(),
          seq: integer,
          type: String.t()
        }

  @doc """
  List sync events

  List sync events for all aggregates. Keys are aggregate IDs the client already knows about, values are the last known sequence ID. Events with seq > value are returned for those aggregates. Aggregates not listed in the input get their full history.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec sync_history_list(body :: map, opts :: keyword) ::
          {:ok, [OpencodeClient.Generated.Sync.sync_history_list_200_json_resp()]}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()}
  def sync_history_list(body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [body: body],
      call: {OpencodeClient.Generated.Sync, :sync_history_list},
      url: "/sync/history",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {200, [{OpencodeClient.Generated.Sync, :sync_history_list_200_json_resp}]},
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

  @type sync_replay_200_json_resp :: %{sessionID: String.t()}

  @doc """
  Replay sync events

  Validate and replay a complete sync event history.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec sync_replay(body :: map, opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Sync.sync_replay_200_json_resp()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()}
  def sync_replay(body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [body: body],
      call: {OpencodeClient.Generated.Sync, :sync_replay},
      url: "/sync/replay",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {200, {OpencodeClient.Generated.Sync, :sync_replay_200_json_resp}},
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
  Start workspace sync

  Start sync loops for workspaces in the current project that have active sessions.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec sync_start(opts :: keyword) ::
          {:ok, boolean} | {:error, OpencodeClient.Generated.BadRequestError.t()}
  def sync_start(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Sync, :sync_start},
      url: "/sync/start",
      method: :post,
      query: query,
      response: [{200, :boolean}, {400, {OpencodeClient.Generated.BadRequestError, :t}}],
      opts: opts
    })
  end

  @type sync_steal_200_json_resp :: %{sessionID: String.t()}

  @doc """
  Steal session into workspace

  Update a session to belong to the current workspace through the sync event system.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec sync_steal(body :: map, opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Sync.sync_steal_200_json_resp()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()}
  def sync_steal(body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [body: body],
      call: {OpencodeClient.Generated.Sync, :sync_steal},
      url: "/sync/steal",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {200, {OpencodeClient.Generated.Sync, :sync_steal_200_json_resp}},
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

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(:sync_history_list_200_json_resp) do
    [aggregate_id: :string, data: :map, id: :string, seq: :integer, type: :string]
  end

  def __fields__(:sync_replay_200_json_resp) do
    [sessionID: :string]
  end

  def __fields__(:sync_steal_200_json_resp) do
    [sessionID: :string]
  end
end
