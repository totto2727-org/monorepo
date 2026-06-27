defmodule OpencodeClient.Generated.Mcp do
  @moduledoc """
  Provides API endpoints related to mcp
  """

  @default_client OpencodeClient.Generated.Client

  @doc """
  Add MCP server

  Dynamically add a new Model Context Protocol (MCP) server to the system.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec mcp_add(body :: map, opts :: keyword) ::
          {:ok, map}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()}
  def mcp_add(body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [body: body],
      call: {OpencodeClient.Generated.Mcp, :mcp_add},
      url: "/mcp",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {200, :map},
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
  Authenticate MCP OAuth

  Start OAuth flow and wait for callback (opens browser).

  ## Options

    * `directory`
    * `workspace`

  """
  @spec mcp_auth_authenticate(name :: String.t(), opts :: keyword) ::
          {:ok,
           OpencodeClient.Generated.MCPStatusConnected.t()
           | OpencodeClient.Generated.MCPStatusDisabled.t()
           | OpencodeClient.Generated.MCPStatusFailed.t()
           | OpencodeClient.Generated.MCPStatusNeedsAuth.t()
           | OpencodeClient.Generated.MCPStatusNeedsClientRegistration.t()}
          | {:error,
             OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.McpServerNotFoundError.t()
             | OpencodeClient.Generated.McpUnsupportedOAuthError.t()}
  def mcp_auth_authenticate(name, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [name: name],
      call: {OpencodeClient.Generated.Mcp, :mcp_auth_authenticate},
      url: "/mcp/#{name}/auth/authenticate",
      method: :post,
      query: query,
      response: [
        {200,
         {:union,
          [
            {OpencodeClient.Generated.MCPStatusConnected, :t},
            {OpencodeClient.Generated.MCPStatusDisabled, :t},
            {OpencodeClient.Generated.MCPStatusFailed, :t},
            {OpencodeClient.Generated.MCPStatusNeedsAuth, :t},
            {OpencodeClient.Generated.MCPStatusNeedsClientRegistration, :t}
          ]}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.InvalidRequestError, :t},
            {OpencodeClient.Generated.McpUnsupportedOAuthError, :t}
          ]}},
        {404, {OpencodeClient.Generated.McpServerNotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Complete MCP OAuth

  Complete OAuth authentication for a Model Context Protocol (MCP) server using the authorization code.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec mcp_auth_callback(name :: String.t(), body :: map, opts :: keyword) ::
          {:ok,
           OpencodeClient.Generated.MCPStatusConnected.t()
           | OpencodeClient.Generated.MCPStatusDisabled.t()
           | OpencodeClient.Generated.MCPStatusFailed.t()
           | OpencodeClient.Generated.MCPStatusNeedsAuth.t()
           | OpencodeClient.Generated.MCPStatusNeedsClientRegistration.t()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.McpServerNotFoundError.t()}
  def mcp_auth_callback(name, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [name: name, body: body],
      call: {OpencodeClient.Generated.Mcp, :mcp_auth_callback},
      url: "/mcp/#{name}/auth/callback",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {200,
         {:union,
          [
            {OpencodeClient.Generated.MCPStatusConnected, :t},
            {OpencodeClient.Generated.MCPStatusDisabled, :t},
            {OpencodeClient.Generated.MCPStatusFailed, :t},
            {OpencodeClient.Generated.MCPStatusNeedsAuth, :t},
            {OpencodeClient.Generated.MCPStatusNeedsClientRegistration, :t}
          ]}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.McpServerNotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @type mcp_auth_remove_200_json_resp :: %{success: true}

  @doc """
  Remove MCP OAuth

  Remove OAuth credentials for an MCP server.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec mcp_auth_remove(name :: String.t(), opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Mcp.mcp_auth_remove_200_json_resp()}
          | {:error,
             OpencodeClient.Generated.BadRequestError.t()
             | OpencodeClient.Generated.McpServerNotFoundError.t()}
  def mcp_auth_remove(name, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [name: name],
      call: {OpencodeClient.Generated.Mcp, :mcp_auth_remove},
      url: "/mcp/#{name}/auth",
      method: :delete,
      query: query,
      response: [
        {200, {OpencodeClient.Generated.Mcp, :mcp_auth_remove_200_json_resp}},
        {400, {OpencodeClient.Generated.BadRequestError, :t}},
        {404, {OpencodeClient.Generated.McpServerNotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @type mcp_auth_start_200_json_resp :: %{authorizationUrl: String.t(), oauthState: String.t()}

  @doc """
  Start MCP OAuth

  Start OAuth authentication flow for a Model Context Protocol (MCP) server.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec mcp_auth_start(name :: String.t(), opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Mcp.mcp_auth_start_200_json_resp()}
          | {:error,
             OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.McpServerNotFoundError.t()
             | OpencodeClient.Generated.McpUnsupportedOAuthError.t()}
  def mcp_auth_start(name, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [name: name],
      call: {OpencodeClient.Generated.Mcp, :mcp_auth_start},
      url: "/mcp/#{name}/auth",
      method: :post,
      query: query,
      response: [
        {200, {OpencodeClient.Generated.Mcp, :mcp_auth_start_200_json_resp}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.InvalidRequestError, :t},
            {OpencodeClient.Generated.McpUnsupportedOAuthError, :t}
          ]}},
        {404, {OpencodeClient.Generated.McpServerNotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  post `/mcp/{name}/connect`

  Connect an MCP server.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec mcp_connect(name :: String.t(), opts :: keyword) ::
          {:ok, boolean}
          | {:error,
             OpencodeClient.Generated.BadRequestError.t()
             | OpencodeClient.Generated.McpServerNotFoundError.t()}
  def mcp_connect(name, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [name: name],
      call: {OpencodeClient.Generated.Mcp, :mcp_connect},
      url: "/mcp/#{name}/connect",
      method: :post,
      query: query,
      response: [
        {200, :boolean},
        {400, {OpencodeClient.Generated.BadRequestError, :t}},
        {404, {OpencodeClient.Generated.McpServerNotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  post `/mcp/{name}/disconnect`

  Disconnect an MCP server.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec mcp_disconnect(name :: String.t(), opts :: keyword) ::
          {:ok, boolean}
          | {:error,
             OpencodeClient.Generated.BadRequestError.t()
             | OpencodeClient.Generated.McpServerNotFoundError.t()}
  def mcp_disconnect(name, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [name: name],
      call: {OpencodeClient.Generated.Mcp, :mcp_disconnect},
      url: "/mcp/#{name}/disconnect",
      method: :post,
      query: query,
      response: [
        {200, :boolean},
        {400, {OpencodeClient.Generated.BadRequestError, :t}},
        {404, {OpencodeClient.Generated.McpServerNotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Get MCP status

  Get the status of all Model Context Protocol (MCP) servers.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec mcp_status(opts :: keyword) ::
          {:ok, map} | {:error, OpencodeClient.Generated.BadRequestError.t()}
  def mcp_status(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Mcp, :mcp_status},
      url: "/mcp",
      method: :get,
      query: query,
      response: [{200, :map}, {400, {OpencodeClient.Generated.BadRequestError, :t}}],
      opts: opts
    })
  end

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(:mcp_auth_remove_200_json_resp) do
    [success: {:const, true}]
  end

  def __fields__(:mcp_auth_start_200_json_resp) do
    [authorizationUrl: :string, oauthState: :string]
  end
end
