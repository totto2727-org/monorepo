defmodule OpencodeClient.Generated.Permission do
  @moduledoc """
  Provides API endpoints related to permission
  """

  @default_client OpencodeClient.Generated.Client

  @doc """
  List pending permissions

  Get all pending permission requests across all sessions.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec permission_list(opts :: keyword) ::
          {:ok, [OpencodeClient.Generated.PermissionRequest.t()]}
          | {:error, OpencodeClient.Generated.BadRequestError.t()}
  def permission_list(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Permission, :permission_list},
      url: "/permission",
      method: :get,
      query: query,
      response: [
        {200, [{OpencodeClient.Generated.PermissionRequest, :t}]},
        {400, {OpencodeClient.Generated.BadRequestError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Respond to permission request

  Approve or deny a permission request from the AI assistant.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec permission_reply(requestID :: String.t(), body :: map, opts :: keyword) ::
          {:ok, boolean}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.PermissionNotFoundError.t()}
  def permission_reply(requestID, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [requestID: requestID, body: body],
      call: {OpencodeClient.Generated.Permission, :permission_reply},
      url: "/permission/#{requestID}/reply",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {200, :boolean},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.PermissionNotFoundError, :t}}
      ],
      opts: opts
    })
  end
end
