defmodule OpencodeClient.Generated.V2Models do
  @moduledoc """
  Provides API endpoint related to v2 models
  """

  @default_client OpencodeClient.Client

  @doc """
  List v2 models

  Retrieve available v2 models ordered by release date.

  ## Options

    * `location`

  """
  @spec v2_model_list(opts :: keyword) ::
          {:ok, [OpencodeClient.Generated.ModelV2Info.t()]}
          | {:error,
             OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.ServiceUnavailableError.t()
             | OpencodeClient.Generated.UnauthorizedError.t()}
  def v2_model_list(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:location])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.V2Models, :v2_model_list},
      url: "/api/model",
      method: :get,
      query: query,
      response: [
        {200, [{OpencodeClient.Generated.ModelV2Info, :t}]},
        {400, {OpencodeClient.Generated.InvalidRequestError, :t}},
        {401, {OpencodeClient.Generated.UnauthorizedError, :t}},
        {503, {OpencodeClient.Generated.ServiceUnavailableError, :t}}
      ],
      opts: opts
    })
  end
end
