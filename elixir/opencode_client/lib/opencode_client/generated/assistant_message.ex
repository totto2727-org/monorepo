defmodule OpencodeClient.Generated.AssistantMessage do
  @moduledoc """
  Provides struct and type for a AssistantMessage
  """

  @type t :: %__MODULE__{
          agent: String.t(),
          cost: number,
          error:
            OpencodeClient.Generated.APIError.t()
            | OpencodeClient.Generated.ContextOverflowError.t()
            | OpencodeClient.Generated.MessageAbortedError.t()
            | OpencodeClient.Generated.MessageOutputLengthError.t()
            | OpencodeClient.Generated.ProviderAuthError.t()
            | OpencodeClient.Generated.StructuredOutputError.t()
            | OpencodeClient.Generated.UnknownError.t()
            | nil,
          finish: String.t() | nil,
          id: String.t(),
          mode: String.t(),
          modelID: String.t(),
          parentID: String.t(),
          path: OpencodeClient.Generated.AssistantMessagePath.t(),
          providerID: String.t(),
          role: String.t(),
          sessionID: String.t(),
          structured: map | nil,
          summary: boolean | nil,
          time: OpencodeClient.Generated.AssistantMessageTime.t(),
          tokens: OpencodeClient.Generated.AssistantMessageTokens.t(),
          variant: String.t() | nil
        }

  defstruct [
    :agent,
    :cost,
    :error,
    :finish,
    :id,
    :mode,
    :modelID,
    :parentID,
    :path,
    :providerID,
    :role,
    :sessionID,
    :structured,
    :summary,
    :time,
    :tokens,
    :variant
  ]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      agent: :string,
      cost: :number,
      error:
        {:union,
         [
           {OpencodeClient.Generated.APIError, :t},
           {OpencodeClient.Generated.ContextOverflowError, :t},
           {OpencodeClient.Generated.MessageAbortedError, :t},
           {OpencodeClient.Generated.MessageOutputLengthError, :t},
           {OpencodeClient.Generated.ProviderAuthError, :t},
           {OpencodeClient.Generated.StructuredOutputError, :t},
           {OpencodeClient.Generated.UnknownError, :t}
         ]},
      finish: :string,
      id: :string,
      mode: :string,
      modelID: :string,
      parentID: :string,
      path: {OpencodeClient.Generated.AssistantMessagePath, :t},
      providerID: :string,
      role: {:const, "assistant"},
      sessionID: :string,
      structured: :map,
      summary: :boolean,
      time: {OpencodeClient.Generated.AssistantMessageTime, :t},
      tokens: {OpencodeClient.Generated.AssistantMessageTokens, :t},
      variant: :string
    ]
  end
end
