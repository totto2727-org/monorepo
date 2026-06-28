defmodule OpencodeClient.Generated.Project do
  @moduledoc """
  Provides API endpoints related to project
  """

  @default_client OpencodeClient.Client

  @doc """
  Get current project

  Retrieve the currently active project that OpenCode is working with.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec project_current(opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Project.t()}
          | {:error, OpencodeClient.Generated.BadRequestError.t()}
  def project_current(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Project, :project_current},
      url: "/project/current",
      method: :get,
      query: query,
      response: [
        {200, {OpencodeClient.Generated.Project, :t}},
        {400, {OpencodeClient.Generated.BadRequestError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Initialize git repository

  Create a git repository for the current project and return the refreshed project info.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec project_init_git(opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Project.t()}
          | {:error, OpencodeClient.Generated.BadRequestError.t()}
  def project_init_git(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Project, :project_init_git},
      url: "/project/git/init",
      method: :post,
      query: query,
      response: [
        {200, {OpencodeClient.Generated.Project, :t}},
        {400, {OpencodeClient.Generated.BadRequestError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  List all projects

  Get a list of projects that have been opened with OpenCode.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec project_list(opts :: keyword) ::
          {:ok, [OpencodeClient.Generated.Project.t()]}
          | {:error, OpencodeClient.Generated.BadRequestError.t()}
  def project_list(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Project, :project_list},
      url: "/project",
      method: :get,
      query: query,
      response: [
        {200, [{OpencodeClient.Generated.Project, :t}]},
        {400, {OpencodeClient.Generated.BadRequestError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Update project

  Update project properties such as name, icon, and commands.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec project_update(projectID :: String.t(), body :: map, opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Project.t()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.ProjectNotFoundError.t()}
  def project_update(projectID, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [projectID: projectID, body: body],
      call: {OpencodeClient.Generated.Project, :project_update},
      url: "/project/#{projectID}",
      body: body,
      method: :patch,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {200, {OpencodeClient.Generated.Project, :t}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.ProjectNotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @type t :: %__MODULE__{
          commands: OpencodeClient.Generated.ProjectCommands.t() | nil,
          icon: OpencodeClient.Generated.ProjectIcon.t() | nil,
          id: String.t(),
          name: String.t() | nil,
          sandboxes: [String.t()],
          time: OpencodeClient.Generated.ProjectTime.t(),
          vcs: String.t() | nil,
          worktree: String.t()
        }

  defstruct [:commands, :icon, :id, :name, :sandboxes, :time, :vcs, :worktree]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      commands: {OpencodeClient.Generated.ProjectCommands, :t},
      icon: {OpencodeClient.Generated.ProjectIcon, :t},
      id: :string,
      name: :string,
      sandboxes: [:string],
      time: {OpencodeClient.Generated.ProjectTime, :t},
      vcs: {:const, "git"},
      worktree: :string
    ]
  end
end
