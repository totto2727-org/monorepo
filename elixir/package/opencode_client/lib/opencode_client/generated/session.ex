defmodule OpencodeClient.Generated.Session do
  @moduledoc """
  Provides API endpoints related to session
  """

  @default_client OpencodeClient.Generated.Client

  @doc """
  delete `/session/{sessionID}/message/{messageID}/part/{partID}`

  Delete a part from a message.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec part_delete(
          sessionID :: String.t(),
          messageID :: String.t(),
          partID :: String.t(),
          opts :: keyword
        ) ::
          {:ok, boolean}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def part_delete(sessionID, messageID, partID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID, messageID: messageID, partID: partID],
      call: {OpencodeClient.Generated.Session, :part_delete},
      url: "/session/#{sessionID}/message/#{messageID}/part/#{partID}",
      method: :delete,
      query: query,
      response: [
        {200, :boolean},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  patch `/session/{sessionID}/message/{messageID}/part/{partID}`

  Update a part in a message.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec part_update(
          sessionID :: String.t(),
          messageID :: String.t(),
          partID :: String.t(),
          body ::
            OpencodeClient.Generated.AgentPart.t()
            | OpencodeClient.Generated.CompactionPart.t()
            | OpencodeClient.Generated.FilePart.t()
            | OpencodeClient.Generated.PatchPart.t()
            | OpencodeClient.Generated.ReasoningPart.t()
            | OpencodeClient.Generated.RetryPart.t()
            | OpencodeClient.Generated.SnapshotPart.t()
            | OpencodeClient.Generated.StepFinishPart.t()
            | OpencodeClient.Generated.StepStartPart.t()
            | OpencodeClient.Generated.SubtaskPart.t()
            | OpencodeClient.Generated.TextPart.t()
            | OpencodeClient.Generated.ToolPart.t(),
          opts :: keyword
        ) ::
          {:ok,
           OpencodeClient.Generated.AgentPart.t()
           | OpencodeClient.Generated.CompactionPart.t()
           | OpencodeClient.Generated.FilePart.t()
           | OpencodeClient.Generated.PatchPart.t()
           | OpencodeClient.Generated.ReasoningPart.t()
           | OpencodeClient.Generated.RetryPart.t()
           | OpencodeClient.Generated.SnapshotPart.t()
           | OpencodeClient.Generated.StepFinishPart.t()
           | OpencodeClient.Generated.StepStartPart.t()
           | OpencodeClient.Generated.SubtaskPart.t()
           | OpencodeClient.Generated.TextPart.t()
           | OpencodeClient.Generated.ToolPart.t()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def part_update(sessionID, messageID, partID, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID, messageID: messageID, partID: partID, body: body],
      call: {OpencodeClient.Generated.Session, :part_update},
      url: "/session/#{sessionID}/message/#{messageID}/part/#{partID}",
      body: body,
      method: :patch,
      query: query,
      request: [
        {"application/json",
         {:union,
          [
            {OpencodeClient.Generated.AgentPart, :t},
            {OpencodeClient.Generated.CompactionPart, :t},
            {OpencodeClient.Generated.FilePart, :t},
            {OpencodeClient.Generated.PatchPart, :t},
            {OpencodeClient.Generated.ReasoningPart, :t},
            {OpencodeClient.Generated.RetryPart, :t},
            {OpencodeClient.Generated.SnapshotPart, :t},
            {OpencodeClient.Generated.StepFinishPart, :t},
            {OpencodeClient.Generated.StepStartPart, :t},
            {OpencodeClient.Generated.SubtaskPart, :t},
            {OpencodeClient.Generated.TextPart, :t},
            {OpencodeClient.Generated.ToolPart, :t}
          ]}}
      ],
      response: [
        {200,
         {:union,
          [
            {OpencodeClient.Generated.AgentPart, :t},
            {OpencodeClient.Generated.CompactionPart, :t},
            {OpencodeClient.Generated.FilePart, :t},
            {OpencodeClient.Generated.PatchPart, :t},
            {OpencodeClient.Generated.ReasoningPart, :t},
            {OpencodeClient.Generated.RetryPart, :t},
            {OpencodeClient.Generated.SnapshotPart, :t},
            {OpencodeClient.Generated.StepFinishPart, :t},
            {OpencodeClient.Generated.StepStartPart, :t},
            {OpencodeClient.Generated.SubtaskPart, :t},
            {OpencodeClient.Generated.TextPart, :t},
            {OpencodeClient.Generated.ToolPart, :t}
          ]}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Respond to permission

  Approve or deny a permission request from the AI assistant.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec permission_respond(
          sessionID :: String.t(),
          permissionID :: String.t(),
          body :: map,
          opts :: keyword
        ) ::
          {:ok, boolean}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()
             | OpencodeClient.Generated.PermissionNotFoundError.t()}
  def permission_respond(sessionID, permissionID, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID, permissionID: permissionID, body: body],
      call: {OpencodeClient.Generated.Session, :permission_respond},
      url: "/session/#{sessionID}/permissions/#{permissionID}",
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
        {404,
         {:union,
          [
            {OpencodeClient.Generated.NotFoundError, :t},
            {OpencodeClient.Generated.PermissionNotFoundError, :t}
          ]}}
      ],
      opts: opts
    })
  end

  @doc """
  Abort session

  Abort an active session and stop any ongoing AI processing or command execution.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec session_abort(sessionID :: String.t(), opts :: keyword) ::
          {:ok, boolean}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()}
  def session_abort(sessionID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID],
      call: {OpencodeClient.Generated.Session, :session_abort},
      url: "/session/#{sessionID}/abort",
      method: :post,
      query: query,
      response: [
        {200, :boolean},
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
  Get session children

  Retrieve all child sessions that were forked from the specified parent session.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec session_children(sessionID :: String.t(), opts :: keyword) ::
          {:ok, [OpencodeClient.Generated.Session.t()]}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_children(sessionID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID],
      call: {OpencodeClient.Generated.Session, :session_children},
      url: "/session/#{sessionID}/children",
      method: :get,
      query: query,
      response: [
        {200, [{OpencodeClient.Generated.Session, :t}]},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @type session_command_200_json_resp :: %{
          info: OpencodeClient.Generated.AssistantMessage.t(),
          parts: [
            OpencodeClient.Generated.AgentPart.t()
            | OpencodeClient.Generated.CompactionPart.t()
            | OpencodeClient.Generated.FilePart.t()
            | OpencodeClient.Generated.PatchPart.t()
            | OpencodeClient.Generated.ReasoningPart.t()
            | OpencodeClient.Generated.RetryPart.t()
            | OpencodeClient.Generated.SnapshotPart.t()
            | OpencodeClient.Generated.StepFinishPart.t()
            | OpencodeClient.Generated.StepStartPart.t()
            | OpencodeClient.Generated.SubtaskPart.t()
            | OpencodeClient.Generated.TextPart.t()
            | OpencodeClient.Generated.ToolPart.t()
          ]
        }

  @doc """
  Send command

  Send a new command to a session for execution by the AI assistant.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec session_command(sessionID :: String.t(), body :: map, opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Session.session_command_200_json_resp()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_command(sessionID, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID, body: body],
      call: {OpencodeClient.Generated.Session, :session_command},
      url: "/session/#{sessionID}/command",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {200, {OpencodeClient.Generated.Session, :session_command_200_json_resp}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Create session

  Create a new OpenCode session for interacting with AI assistants and managing conversations.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec session_create(body :: map, opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Session.t()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()}
  def session_create(body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [body: body],
      call: {OpencodeClient.Generated.Session, :session_create},
      url: "/session",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {200, {OpencodeClient.Generated.Session, :t}},
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
  Delete session

  Delete a session and permanently remove all associated data, including messages and history.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec session_delete(sessionID :: String.t(), opts :: keyword) ::
          {:ok, boolean}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_delete(sessionID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID],
      call: {OpencodeClient.Generated.Session, :session_delete},
      url: "/session/#{sessionID}",
      method: :delete,
      query: query,
      response: [
        {200, :boolean},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Delete message

  Permanently delete a specific message and all of its parts from a session without reverting file changes.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec session_delete_message(sessionID :: String.t(), messageID :: String.t(), opts :: keyword) ::
          {:ok, boolean}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()
             | OpencodeClient.Generated.SessionBusyError.t()}
  def session_delete_message(sessionID, messageID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID, messageID: messageID],
      call: {OpencodeClient.Generated.Session, :session_delete_message},
      url: "/session/#{sessionID}/message/#{messageID}",
      method: :delete,
      query: query,
      response: [
        {200, :boolean},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}},
        {409, {OpencodeClient.Generated.SessionBusyError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Get message diff

  Get the file changes (diff) that resulted from a specific user message in the session.

  ## Options

    * `directory`
    * `workspace`
    * `messageID`

  """
  @spec session_diff(sessionID :: String.t(), opts :: keyword) ::
          {:ok, [OpencodeClient.Generated.SnapshotFileDiff.t()]}
          | {:error, OpencodeClient.Generated.BadRequestError.t()}
  def session_diff(sessionID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :messageID, :workspace])

    client.request(%{
      args: [sessionID: sessionID],
      call: {OpencodeClient.Generated.Session, :session_diff},
      url: "/session/#{sessionID}/diff",
      method: :get,
      query: query,
      response: [
        {200, [{OpencodeClient.Generated.SnapshotFileDiff, :t}]},
        {400, {OpencodeClient.Generated.BadRequestError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Fork session

  Create a new session by forking an existing session at a specific message point.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec session_fork(sessionID :: String.t(), body :: map, opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Session.t()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_fork(sessionID, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID, body: body],
      call: {OpencodeClient.Generated.Session, :session_fork},
      url: "/session/#{sessionID}/fork",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {200, {OpencodeClient.Generated.Session, :t}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Get session

  Retrieve detailed information about a specific OpenCode session.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec session_get(sessionID :: String.t(), opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Session.t()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_get(sessionID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID],
      call: {OpencodeClient.Generated.Session, :session_get},
      url: "/session/#{sessionID}",
      method: :get,
      query: query,
      response: [
        {200, {OpencodeClient.Generated.Session, :t}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Initialize session

  Analyze the current application and create an AGENTS.md file with project-specific agent configurations.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec session_init(sessionID :: String.t(), body :: map, opts :: keyword) ::
          {:ok, boolean}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_init(sessionID, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID, body: body],
      call: {OpencodeClient.Generated.Session, :session_init},
      url: "/session/#{sessionID}/init",
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
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  List sessions

  Get a list of all OpenCode sessions, sorted by most recently updated.

  ## Options

    * `directory`
    * `workspace`
    * `scope`
    * `path`
    * `roots`
    * `start`
    * `search`
    * `limit`

  """
  @spec session_list(opts :: keyword) ::
          {:ok, [OpencodeClient.Generated.Session.t()]}
          | {:error, OpencodeClient.Generated.BadRequestError.t()}
  def session_list(opts \\ []) do
    client = opts[:client] || @default_client

    query =
      Keyword.take(opts, [:directory, :limit, :path, :roots, :scope, :search, :start, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Session, :session_list},
      url: "/session",
      method: :get,
      query: query,
      response: [
        {200, [{OpencodeClient.Generated.Session, :t}]},
        {400, {OpencodeClient.Generated.BadRequestError, :t}}
      ],
      opts: opts
    })
  end

  @type session_message_200_json_resp :: %{
          info:
            OpencodeClient.Generated.AssistantMessage.t()
            | OpencodeClient.Generated.UserMessage.t(),
          parts: [
            OpencodeClient.Generated.AgentPart.t()
            | OpencodeClient.Generated.CompactionPart.t()
            | OpencodeClient.Generated.FilePart.t()
            | OpencodeClient.Generated.PatchPart.t()
            | OpencodeClient.Generated.ReasoningPart.t()
            | OpencodeClient.Generated.RetryPart.t()
            | OpencodeClient.Generated.SnapshotPart.t()
            | OpencodeClient.Generated.StepFinishPart.t()
            | OpencodeClient.Generated.StepStartPart.t()
            | OpencodeClient.Generated.SubtaskPart.t()
            | OpencodeClient.Generated.TextPart.t()
            | OpencodeClient.Generated.ToolPart.t()
          ]
        }

  @doc """
  Get message

  Retrieve a specific message from a session by its message ID.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec session_message(sessionID :: String.t(), messageID :: String.t(), opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Session.session_message_200_json_resp()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_message(sessionID, messageID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID, messageID: messageID],
      call: {OpencodeClient.Generated.Session, :session_message},
      url: "/session/#{sessionID}/message/#{messageID}",
      method: :get,
      query: query,
      response: [
        {200, {OpencodeClient.Generated.Session, :session_message_200_json_resp}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @type session_messages_200_json_resp :: %{
          info:
            OpencodeClient.Generated.AssistantMessage.t()
            | OpencodeClient.Generated.UserMessage.t(),
          parts: [
            OpencodeClient.Generated.AgentPart.t()
            | OpencodeClient.Generated.CompactionPart.t()
            | OpencodeClient.Generated.FilePart.t()
            | OpencodeClient.Generated.PatchPart.t()
            | OpencodeClient.Generated.ReasoningPart.t()
            | OpencodeClient.Generated.RetryPart.t()
            | OpencodeClient.Generated.SnapshotPart.t()
            | OpencodeClient.Generated.StepFinishPart.t()
            | OpencodeClient.Generated.StepStartPart.t()
            | OpencodeClient.Generated.SubtaskPart.t()
            | OpencodeClient.Generated.TextPart.t()
            | OpencodeClient.Generated.ToolPart.t()
          ]
        }

  @doc """
  Get session messages

  Retrieve all messages in a session, including user prompts and AI responses.

  ## Options

    * `directory`
    * `workspace`
    * `limit`
    * `before`

  """
  @spec session_messages(sessionID :: String.t(), opts :: keyword) ::
          {:ok, [OpencodeClient.Generated.Session.session_messages_200_json_resp()]}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_messages(sessionID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:before, :directory, :limit, :workspace])

    client.request(%{
      args: [sessionID: sessionID],
      call: {OpencodeClient.Generated.Session, :session_messages},
      url: "/session/#{sessionID}/message",
      method: :get,
      query: query,
      response: [
        {200, [{OpencodeClient.Generated.Session, :session_messages_200_json_resp}]},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @type session_prompt_200_json_resp :: %{
          info: OpencodeClient.Generated.AssistantMessage.t(),
          parts: [
            OpencodeClient.Generated.AgentPart.t()
            | OpencodeClient.Generated.CompactionPart.t()
            | OpencodeClient.Generated.FilePart.t()
            | OpencodeClient.Generated.PatchPart.t()
            | OpencodeClient.Generated.ReasoningPart.t()
            | OpencodeClient.Generated.RetryPart.t()
            | OpencodeClient.Generated.SnapshotPart.t()
            | OpencodeClient.Generated.StepFinishPart.t()
            | OpencodeClient.Generated.StepStartPart.t()
            | OpencodeClient.Generated.SubtaskPart.t()
            | OpencodeClient.Generated.TextPart.t()
            | OpencodeClient.Generated.ToolPart.t()
          ]
        }

  @doc """
  Send message

  Create and send a new message to a session, streaming the AI response.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec session_prompt(sessionID :: String.t(), body :: map, opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Session.session_prompt_200_json_resp()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_prompt(sessionID, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID, body: body],
      call: {OpencodeClient.Generated.Session, :session_prompt},
      url: "/session/#{sessionID}/message",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {200, {OpencodeClient.Generated.Session, :session_prompt_200_json_resp}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Send async message

  Create and send a new message to a session asynchronously, starting the session if needed and returning immediately.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec session_prompt_async(sessionID :: String.t(), body :: map, opts :: keyword) ::
          :ok
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_prompt_async(sessionID, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID, body: body],
      call: {OpencodeClient.Generated.Session, :session_prompt_async},
      url: "/session/#{sessionID}/prompt_async",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {204, :null},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Revert message

  Revert a specific message in a session, undoing its effects and restoring the previous state.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec session_revert(sessionID :: String.t(), body :: map, opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Session.t()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()
             | OpencodeClient.Generated.SessionBusyError.t()}
  def session_revert(sessionID, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID, body: body],
      call: {OpencodeClient.Generated.Session, :session_revert},
      url: "/session/#{sessionID}/revert",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {200, {OpencodeClient.Generated.Session, :t}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}},
        {409, {OpencodeClient.Generated.SessionBusyError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Share session

  Create a shareable link for a session, allowing others to view the conversation.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec session_share(sessionID :: String.t(), opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Session.t()}
          | {:error,
             OpencodeClient.Generated.BadRequestError.t()
             | OpencodeClient.Generated.EffectHttpApiErrorInternalServerError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_share(sessionID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID],
      call: {OpencodeClient.Generated.Session, :session_share},
      url: "/session/#{sessionID}/share",
      method: :post,
      query: query,
      response: [
        {200, {OpencodeClient.Generated.Session, :t}},
        {400, {OpencodeClient.Generated.BadRequestError, :t}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}},
        {500, {OpencodeClient.Generated.EffectHttpApiErrorInternalServerError, :t}}
      ],
      opts: opts
    })
  end

  @type session_shell_200_json_resp :: %{
          info:
            OpencodeClient.Generated.AssistantMessage.t()
            | OpencodeClient.Generated.UserMessage.t(),
          parts: [
            OpencodeClient.Generated.AgentPart.t()
            | OpencodeClient.Generated.CompactionPart.t()
            | OpencodeClient.Generated.FilePart.t()
            | OpencodeClient.Generated.PatchPart.t()
            | OpencodeClient.Generated.ReasoningPart.t()
            | OpencodeClient.Generated.RetryPart.t()
            | OpencodeClient.Generated.SnapshotPart.t()
            | OpencodeClient.Generated.StepFinishPart.t()
            | OpencodeClient.Generated.StepStartPart.t()
            | OpencodeClient.Generated.SubtaskPart.t()
            | OpencodeClient.Generated.TextPart.t()
            | OpencodeClient.Generated.ToolPart.t()
          ]
        }

  @doc """
  Run shell command

  Execute a shell command within the session context and return the AI's response.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec session_shell(sessionID :: String.t(), body :: map, opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Session.session_shell_200_json_resp()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()
             | OpencodeClient.Generated.SessionBusyError.t()}
  def session_shell(sessionID, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID, body: body],
      call: {OpencodeClient.Generated.Session, :session_shell},
      url: "/session/#{sessionID}/shell",
      body: body,
      method: :post,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {200, {OpencodeClient.Generated.Session, :session_shell_200_json_resp}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}},
        {409, {OpencodeClient.Generated.SessionBusyError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Get session status

  Retrieve the current status of all sessions, including active, idle, and completed states.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec session_status(opts :: keyword) ::
          {:ok, map}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()}
  def session_status(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Session, :session_status},
      url: "/session/status",
      method: :get,
      query: query,
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
  Summarize session

  Generate a concise summary of the session using AI compaction to preserve key information.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec session_summarize(sessionID :: String.t(), body :: map, opts :: keyword) ::
          {:ok, boolean}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_summarize(sessionID, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID, body: body],
      call: {OpencodeClient.Generated.Session, :session_summarize},
      url: "/session/#{sessionID}/summarize",
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
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Get session todos

  Retrieve the todo list associated with a specific session, showing tasks and action items.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec session_todo(sessionID :: String.t(), opts :: keyword) ::
          {:ok, [OpencodeClient.Generated.Todo.t()]}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_todo(sessionID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID],
      call: {OpencodeClient.Generated.Session, :session_todo},
      url: "/session/#{sessionID}/todo",
      method: :get,
      query: query,
      response: [
        {200, [{OpencodeClient.Generated.Todo, :t}]},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Restore reverted messages

  Restore all previously reverted messages in a session.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec session_unrevert(sessionID :: String.t(), opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Session.t()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()
             | OpencodeClient.Generated.SessionBusyError.t()}
  def session_unrevert(sessionID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID],
      call: {OpencodeClient.Generated.Session, :session_unrevert},
      url: "/session/#{sessionID}/unrevert",
      method: :post,
      query: query,
      response: [
        {200, {OpencodeClient.Generated.Session, :t}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}},
        {409, {OpencodeClient.Generated.SessionBusyError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Unshare session

  Remove the shareable link for a session, making it private again.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec session_unshare(sessionID :: String.t(), opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Session.t()}
          | {:error,
             OpencodeClient.Generated.BadRequestError.t()
             | OpencodeClient.Generated.EffectHttpApiErrorInternalServerError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_unshare(sessionID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID],
      call: {OpencodeClient.Generated.Session, :session_unshare},
      url: "/session/#{sessionID}/share",
      method: :delete,
      query: query,
      response: [
        {200, {OpencodeClient.Generated.Session, :t}},
        {400, {OpencodeClient.Generated.BadRequestError, :t}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}},
        {500, {OpencodeClient.Generated.EffectHttpApiErrorInternalServerError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Update session

  Update properties of an existing session, such as title or other metadata.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec session_update(sessionID :: String.t(), body :: map, opts :: keyword) ::
          {:ok, OpencodeClient.Generated.Session.t()}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.NotFoundError.t()}
  def session_update(sessionID, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [sessionID: sessionID, body: body],
      call: {OpencodeClient.Generated.Session, :session_update},
      url: "/session/#{sessionID}",
      body: body,
      method: :patch,
      query: query,
      request: [{"application/json", :map}],
      response: [
        {200, {OpencodeClient.Generated.Session, :t}},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.NotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @type t :: %__MODULE__{
          agent: String.t() | nil,
          cost: number | nil,
          directory: String.t(),
          id: String.t(),
          metadata: map | nil,
          model: OpencodeClient.Generated.SessionModel.t() | nil,
          parentID: String.t() | nil,
          path: String.t() | nil,
          permission: [OpencodeClient.Generated.PermissionRule.t()] | nil,
          projectID: String.t(),
          revert: OpencodeClient.Generated.SessionRevert.t() | nil,
          share: OpencodeClient.Generated.SessionShare.t() | nil,
          slug: String.t(),
          summary: OpencodeClient.Generated.SessionSummary.t() | nil,
          time: OpencodeClient.Generated.SessionTime.t(),
          title: String.t(),
          tokens: OpencodeClient.Generated.SessionTokens.t() | nil,
          version: String.t(),
          workspaceID: String.t() | nil
        }

  defstruct [
    :agent,
    :cost,
    :directory,
    :id,
    :metadata,
    :model,
    :parentID,
    :path,
    :permission,
    :projectID,
    :revert,
    :share,
    :slug,
    :summary,
    :time,
    :title,
    :tokens,
    :version,
    :workspaceID
  ]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:session_command_200_json_resp) do
    [
      info: {OpencodeClient.Generated.AssistantMessage, :t},
      parts: [
        union: [
          {OpencodeClient.Generated.AgentPart, :t},
          {OpencodeClient.Generated.CompactionPart, :t},
          {OpencodeClient.Generated.FilePart, :t},
          {OpencodeClient.Generated.PatchPart, :t},
          {OpencodeClient.Generated.ReasoningPart, :t},
          {OpencodeClient.Generated.RetryPart, :t},
          {OpencodeClient.Generated.SnapshotPart, :t},
          {OpencodeClient.Generated.StepFinishPart, :t},
          {OpencodeClient.Generated.StepStartPart, :t},
          {OpencodeClient.Generated.SubtaskPart, :t},
          {OpencodeClient.Generated.TextPart, :t},
          {OpencodeClient.Generated.ToolPart, :t}
        ]
      ]
    ]
  end

  def __fields__(:session_message_200_json_resp) do
    [
      info:
        {:union,
         [
           {OpencodeClient.Generated.AssistantMessage, :t},
           {OpencodeClient.Generated.UserMessage, :t}
         ]},
      parts: [
        union: [
          {OpencodeClient.Generated.AgentPart, :t},
          {OpencodeClient.Generated.CompactionPart, :t},
          {OpencodeClient.Generated.FilePart, :t},
          {OpencodeClient.Generated.PatchPart, :t},
          {OpencodeClient.Generated.ReasoningPart, :t},
          {OpencodeClient.Generated.RetryPart, :t},
          {OpencodeClient.Generated.SnapshotPart, :t},
          {OpencodeClient.Generated.StepFinishPart, :t},
          {OpencodeClient.Generated.StepStartPart, :t},
          {OpencodeClient.Generated.SubtaskPart, :t},
          {OpencodeClient.Generated.TextPart, :t},
          {OpencodeClient.Generated.ToolPart, :t}
        ]
      ]
    ]
  end

  def __fields__(:session_messages_200_json_resp) do
    [
      info:
        {:union,
         [
           {OpencodeClient.Generated.AssistantMessage, :t},
           {OpencodeClient.Generated.UserMessage, :t}
         ]},
      parts: [
        union: [
          {OpencodeClient.Generated.AgentPart, :t},
          {OpencodeClient.Generated.CompactionPart, :t},
          {OpencodeClient.Generated.FilePart, :t},
          {OpencodeClient.Generated.PatchPart, :t},
          {OpencodeClient.Generated.ReasoningPart, :t},
          {OpencodeClient.Generated.RetryPart, :t},
          {OpencodeClient.Generated.SnapshotPart, :t},
          {OpencodeClient.Generated.StepFinishPart, :t},
          {OpencodeClient.Generated.StepStartPart, :t},
          {OpencodeClient.Generated.SubtaskPart, :t},
          {OpencodeClient.Generated.TextPart, :t},
          {OpencodeClient.Generated.ToolPart, :t}
        ]
      ]
    ]
  end

  def __fields__(:session_prompt_200_json_resp) do
    [
      info: {OpencodeClient.Generated.AssistantMessage, :t},
      parts: [
        union: [
          {OpencodeClient.Generated.AgentPart, :t},
          {OpencodeClient.Generated.CompactionPart, :t},
          {OpencodeClient.Generated.FilePart, :t},
          {OpencodeClient.Generated.PatchPart, :t},
          {OpencodeClient.Generated.ReasoningPart, :t},
          {OpencodeClient.Generated.RetryPart, :t},
          {OpencodeClient.Generated.SnapshotPart, :t},
          {OpencodeClient.Generated.StepFinishPart, :t},
          {OpencodeClient.Generated.StepStartPart, :t},
          {OpencodeClient.Generated.SubtaskPart, :t},
          {OpencodeClient.Generated.TextPart, :t},
          {OpencodeClient.Generated.ToolPart, :t}
        ]
      ]
    ]
  end

  def __fields__(:session_shell_200_json_resp) do
    [
      info:
        {:union,
         [
           {OpencodeClient.Generated.AssistantMessage, :t},
           {OpencodeClient.Generated.UserMessage, :t}
         ]},
      parts: [
        union: [
          {OpencodeClient.Generated.AgentPart, :t},
          {OpencodeClient.Generated.CompactionPart, :t},
          {OpencodeClient.Generated.FilePart, :t},
          {OpencodeClient.Generated.PatchPart, :t},
          {OpencodeClient.Generated.ReasoningPart, :t},
          {OpencodeClient.Generated.RetryPart, :t},
          {OpencodeClient.Generated.SnapshotPart, :t},
          {OpencodeClient.Generated.StepFinishPart, :t},
          {OpencodeClient.Generated.StepStartPart, :t},
          {OpencodeClient.Generated.SubtaskPart, :t},
          {OpencodeClient.Generated.TextPart, :t},
          {OpencodeClient.Generated.ToolPart, :t}
        ]
      ]
    ]
  end

  def __fields__(:t) do
    [
      agent: :string,
      cost: :number,
      directory: :string,
      id: :string,
      metadata: :map,
      model: {OpencodeClient.Generated.SessionModel, :t},
      parentID: :string,
      path: :string,
      permission: [{OpencodeClient.Generated.PermissionRule, :t}],
      projectID: :string,
      revert: {OpencodeClient.Generated.SessionRevert, :t},
      share: {OpencodeClient.Generated.SessionShare, :t},
      slug: :string,
      summary: {OpencodeClient.Generated.SessionSummary, :t},
      time: {OpencodeClient.Generated.SessionTime, :t},
      title: :string,
      tokens: {OpencodeClient.Generated.SessionTokens, :t},
      version: :string,
      workspaceID: :string
    ]
  end
end
