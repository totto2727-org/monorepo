defmodule OpencodeClient.Generated.V2Messages do
  @moduledoc """
  Provides API endpoint related to v2 messages
  """

  @default_client OpencodeClient.Generated.Client

  @doc """
  Get v2 session messages

  Retrieve projected v2 messages for a session. Items keep the requested order across pages; use cursor.next or cursor.previous to move through the ordered timeline.

  ## Options

    * `directory`
    * `workspace`
    * `limit`
    * `order`
    * `cursor`

  """
  @spec v2_session_messages(sessionID :: String.t(), opts :: keyword) ::
          {:ok, OpencodeClient.Generated.V2SessionMessagesResponse.t()}
          | {:error,
             OpencodeClient.Generated.InvalidCursorError.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.SessionNotFoundError.t()
             | OpencodeClient.Generated.UnauthorizedError.t()
             | OpencodeClient.Generated.UnknownError1.t()}
  def v2_session_messages(sessionID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:cursor, :directory, :limit, :order, :workspace])

    client.request(%{
      args: [sessionID: sessionID],
      call: {OpencodeClient.Generated.V2Messages, :v2_session_messages},
      url: "/api/session/#{sessionID}/message",
      method: :get,
      query: query,
      response: [
        {200, {OpencodeClient.Generated.V2SessionMessagesResponse, :t}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.InvalidCursorError, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {401, {OpencodeClient.Generated.UnauthorizedError, :t}},
        {404, {OpencodeClient.Generated.SessionNotFoundError, :t}},
        {500, {OpencodeClient.Generated.UnknownError1, :t}}
      ],
      opts: opts
    })
  end
end
