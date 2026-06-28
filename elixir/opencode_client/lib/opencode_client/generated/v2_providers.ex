defmodule OpencodeClient.Generated.V2Providers do
  @moduledoc """
  Provides API endpoints related to v2 providers
  """

  @default_client OpencodeClient.Client

  @doc """
  Get v2 provider

  Retrieve a single v2 AI provider so clients can inspect its availability and endpoint settings.

  ## Options

    * `location`

  """
  @spec v2_provider_get(providerID :: String.t(), opts :: keyword) ::
          {:ok, OpencodeClient.Generated.ProviderV2Info.t()}
          | {:error,
             OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.ProviderNotFoundError.t()
             | OpencodeClient.Generated.ServiceUnavailableError.t()
             | OpencodeClient.Generated.UnauthorizedError.t()}
  def v2_provider_get(providerID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:location])

    client.request(%{
      args: [providerID: providerID],
      call: {OpencodeClient.Generated.V2Providers, :v2_provider_get},
      url: "/api/provider/#{providerID}",
      method: :get,
      query: query,
      response: [
        {200, {OpencodeClient.Generated.ProviderV2Info, :t}},
        {400, {OpencodeClient.Generated.InvalidRequestError, :t}},
        {401, {OpencodeClient.Generated.UnauthorizedError, :t}},
        {404, {OpencodeClient.Generated.ProviderNotFoundError, :t}},
        {503, {OpencodeClient.Generated.ServiceUnavailableError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  List v2 providers

  Retrieve active v2 AI providers so clients can show provider availability and configuration.

  ## Options

    * `location`

  """
  @spec v2_provider_list(opts :: keyword) ::
          {:ok, [OpencodeClient.Generated.ProviderV2Info.t()]}
          | {:error,
             OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.ServiceUnavailableError.t()
             | OpencodeClient.Generated.UnauthorizedError.t()}
  def v2_provider_list(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:location])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.V2Providers, :v2_provider_list},
      url: "/api/provider",
      method: :get,
      query: query,
      response: [
        {200, [{OpencodeClient.Generated.ProviderV2Info, :t}]},
        {400, {OpencodeClient.Generated.InvalidRequestError, :t}},
        {401, {OpencodeClient.Generated.UnauthorizedError, :t}},
        {503, {OpencodeClient.Generated.ServiceUnavailableError, :t}}
      ],
      opts: opts
    })
  end
end
