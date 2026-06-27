defmodule OpencodeClient.Generated.Question do
  @moduledoc """
  Provides API endpoints related to question
  """

  @default_client OpencodeClient.Generated.Client

  @doc """
  List pending questions

  Get all pending question requests across all sessions.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec question_list(opts :: keyword) ::
          {:ok, [OpencodeClient.Generated.QuestionRequest.t()]}
          | {:error, OpencodeClient.Generated.BadRequestError.t()}
  def question_list(opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [],
      call: {OpencodeClient.Generated.Question, :question_list},
      url: "/question",
      method: :get,
      query: query,
      response: [
        {200, [{OpencodeClient.Generated.QuestionRequest, :t}]},
        {400, {OpencodeClient.Generated.BadRequestError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Reject question request

  Reject a question request from the AI assistant.

  ## Options

    * `directory`
    * `workspace`

  """
  @spec question_reject(requestID :: String.t(), opts :: keyword) ::
          {:ok, boolean}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.QuestionNotFoundError.t()}
  def question_reject(requestID, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [requestID: requestID],
      call: {OpencodeClient.Generated.Question, :question_reject},
      url: "/question/#{requestID}/reject",
      method: :post,
      query: query,
      response: [
        {200, :boolean},
        {400,
         {:union,
          [
            {OpencodeClient.Generated.EffectHttpApiErrorBadRequest, :t},
            {OpencodeClient.Generated.InvalidRequestError, :t}
          ]}},
        {404, {OpencodeClient.Generated.QuestionNotFoundError, :t}}
      ],
      opts: opts
    })
  end

  @doc """
  Reply to question request

  Provide answers to a question request from the AI assistant.

  ## Options

    * `directory`
    * `workspace`

  ## Request Body

  **Content Types**: `application/json`
  """
  @spec question_reply(requestID :: String.t(), body :: map, opts :: keyword) ::
          {:ok, boolean}
          | {:error,
             OpencodeClient.Generated.EffectHttpApiErrorBadRequest.t()
             | OpencodeClient.Generated.InvalidRequestError.t()
             | OpencodeClient.Generated.QuestionNotFoundError.t()}
  def question_reply(requestID, body, opts \\ []) do
    client = opts[:client] || @default_client
    query = Keyword.take(opts, [:directory, :workspace])

    client.request(%{
      args: [requestID: requestID, body: body],
      call: {OpencodeClient.Generated.Question, :question_reply},
      url: "/question/#{requestID}/reply",
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
        {404, {OpencodeClient.Generated.QuestionNotFoundError, :t}}
      ],
      opts: opts
    })
  end
end
