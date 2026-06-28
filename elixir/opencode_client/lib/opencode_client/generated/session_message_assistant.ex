defmodule OpencodeClient.Generated.SessionMessageAssistant do
  @moduledoc """
  Provides struct and type for a SessionMessageAssistant
  """

  @type t :: %__MODULE__{
          agent: String.t(),
          content: [
            OpencodeClient.Generated.SessionMessageAssistantReasoning.t()
            | OpencodeClient.Generated.SessionMessageAssistantText.t()
            | OpencodeClient.Generated.SessionMessageAssistantTool.t()
          ],
          cost: number | nil,
          error: OpencodeClient.Generated.SessionErrorUnknown.t() | nil,
          finish: String.t() | nil,
          id: String.t(),
          metadata: map | nil,
          model: OpencodeClient.Generated.SessionMessageAssistantModel.t(),
          snapshot: OpencodeClient.Generated.SessionMessageAssistantSnapshot.t() | nil,
          time: OpencodeClient.Generated.SessionMessageAssistantTime.t(),
          tokens: OpencodeClient.Generated.SessionMessageAssistantTokens.t() | nil,
          type: String.t()
        }

  defstruct [
    :agent,
    :content,
    :cost,
    :error,
    :finish,
    :id,
    :metadata,
    :model,
    :snapshot,
    :time,
    :tokens,
    :type
  ]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      agent: :string,
      content: [
        union: [
          {OpencodeClient.Generated.SessionMessageAssistantReasoning, :t},
          {OpencodeClient.Generated.SessionMessageAssistantText, :t},
          {OpencodeClient.Generated.SessionMessageAssistantTool, :t}
        ]
      ],
      cost: :number,
      error: {OpencodeClient.Generated.SessionErrorUnknown, :t},
      finish: :string,
      id: :string,
      metadata: :map,
      model: {OpencodeClient.Generated.SessionMessageAssistantModel, :t},
      snapshot: {OpencodeClient.Generated.SessionMessageAssistantSnapshot, :t},
      time: {OpencodeClient.Generated.SessionMessageAssistantTime, :t},
      tokens: {OpencodeClient.Generated.SessionMessageAssistantTokens, :t},
      type: {:const, "assistant"}
    ]
  end
end
