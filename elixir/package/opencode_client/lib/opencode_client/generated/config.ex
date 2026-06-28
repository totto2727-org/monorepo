defmodule OpencodeClient.Generated.Config do
  @moduledoc """
  Provides API endpoints related to config
  """

  @default_client OpencodeClient.Client

  @doc """
  Get configuration

  Retrieve the current OpenCode configuration settings and preferences.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec config_get(opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Config.t()}
          | {:error, OpencodeClient.Generated.BadRequestError.t()}
  def config_get(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Config, :config_get},
      url: "/config",
      method: :get,
      query: query,
      response: [
        {200, {OpencodeClient.Generated.Config, :t}},
        {400, {OpencodeClient.Generated.BadRequestError, :t}}
      ],
      opts: opts
    })
  end

  @type config_providers_200_json_resp :: %{
          default: map,
          providers: [OpencodeClient.Generated.Provider.t()]
        }

  @doc """
  List config providers

  Get a list of all configured AI providers and their default models.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec config_providers(opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Config.config_providers_200_json_resp()}
          | {:error, OpencodeClient.Generated.BadRequestError.t()}
  def config_providers(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Config, :config_providers},
      url: "/config/providers",
      method: :get,
      query: query,
      response: [
        {200, {OpencodeClient.Generated.Config, :config_providers_200_json_resp}},
        {400, {OpencodeClient.Generated.BadRequestError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Update configuration

  Update OpenCode configuration settings and preferences.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec config_update(body :: OpencodeClient.Generated.Config.t(), opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Config.t()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()}
  def config_update(body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [body: body],
      call: {OpencodeClient.Generated.Config, :config_update},
      url: "/config",
      body: body,
      method: :patch,
      query: query,
      request: [{"application/json", {OpencodeClient.Generated.Config, :t}}],
      response: [
        {200, {OpencodeClient.Generated.Config, :t}},
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

  @type t :: %__MODULE__{
          "$schema": String.t() | nil,
          agent: OpencodeClient.Generated.ConfigAgent.t() | nil,
          attachment: OpencodeClient.Generated.AttachmentConfig.t() | nil,
          autoshare: boolean | nil,
          autoupdate: boolean | String.t() | nil,
          command: map | nil,
          compaction: OpencodeClient.Generated.ConfigCompaction.t() | nil,
          default_agent: String.t() | nil,
          disabled_providers: [String.t()] | nil,
          enabled_providers: [String.t()] | nil,
          enterprise: OpencodeClient.Generated.ConfigEnterprise.t() | nil,
          experimental: OpencodeClient.Generated.ConfigExperimental.t() | nil,
          formatter: boolean | map | nil,
          instructions: [String.t()] | nil,
          layout: String.t() | nil,
          logLevel: String.t() | nil,
          lsp: boolean | map | nil,
          mcp: map | nil,
          mode: OpencodeClient.Generated.ConfigMode.t() | nil,
          model: String.t() | nil,
          permission: map | String.t() | nil,
          plugin: [String.t() | [any]] | nil,
          provider: map | nil,
          reference: map | nil,
          server: OpencodeClient.Generated.ServerConfig.t() | nil,
          share: String.t() | nil,
          shell: String.t() | nil,
          skills: OpencodeClient.Generated.ConfigSkills.t() | nil,
          small_model: String.t() | nil,
          snapshot: boolean | nil,
          tool_output: OpencodeClient.Generated.ConfigToolOutput.t() | nil,
          tools: map | nil,
          username: String.t() | nil,
          watcher: OpencodeClient.Generated.ConfigWatcher.t() | nil
        }

  defstruct [
    :"$schema",
    :agent,
    :attachment,
    :autoshare,
    :autoupdate,
    :command,
    :compaction,
    :default_agent,
    :disabled_providers,
    :enabled_providers,
    :enterprise,
    :experimental,
    :formatter,
    :instructions,
    :layout,
    :logLevel,
    :lsp,
    :mcp,
    :mode,
    :model,
    :permission,
    :plugin,
    :provider,
    :reference,
    :server,
    :share,
    :shell,
    :skills,
    :small_model,
    :snapshot,
    :tool_output,
    :tools,
    :username,
    :watcher
  ]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:config_providers_200_json_resp) do
    [default: :map, providers: [{OpencodeClient.Generated.Provider, :t}]]
  end

  def __fields__(:t) do
    [
      "$schema": :string,
      agent: {OpencodeClient.Generated.ConfigAgent, :t},
      attachment: {OpencodeClient.Generated.AttachmentConfig, :t},
      autoshare: :boolean,
      autoupdate: {:union, [:boolean, const: "notify"]},
      command: :map,
      compaction: {OpencodeClient.Generated.ConfigCompaction, :t},
      default_agent: :string,
      disabled_providers: [:string],
      enabled_providers: [:string],
      enterprise: {OpencodeClient.Generated.ConfigEnterprise, :t},
      experimental: {OpencodeClient.Generated.ConfigExperimental, :t},
      formatter: {:union, [:boolean, :map]},
      instructions: [:string],
      layout: {:enum, ["auto", "stretch"]},
      logLevel: {:enum, ["DEBUG", "INFO", "WARN", "ERROR"]},
      lsp: {:union, [:boolean, :map]},
      mcp: :map,
      mode: {OpencodeClient.Generated.ConfigMode, :t},
      model: :string,
      permission: {:union, [:map, enum: ["ask", "allow", "deny"]]},
      plugin: [union: [:string, [:unknown]]],
      provider: :map,
      reference: :map,
      server: {OpencodeClient.Generated.ServerConfig, :t},
      share: {:enum, ["manual", "auto", "disabled"]},
      shell: :string,
      skills: {OpencodeClient.Generated.ConfigSkills, :t},
      small_model: :string,
      snapshot: :boolean,
      tool_output: {OpencodeClient.Generated.ConfigToolOutput, :t},
      tools: :map,
      username: :string,
      watcher: {OpencodeClient.Generated.ConfigWatcher, :t}
    ]
  end
end
