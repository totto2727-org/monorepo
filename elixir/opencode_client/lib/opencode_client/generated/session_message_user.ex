defmodule OpencodeClient.Generated.SessionMessageUser do
  @moduledoc """
  Provides struct and type for a SessionMessageUser
  """

  @type t :: %__MODULE__{
          agents: [OpencodeClient.Generated.PromptAgentAttachment.t()] | nil,
          files: [OpencodeClient.Generated.PromptFileAttachment.t()] | nil,
          id: String.t(),
          metadata: map | nil,
          references: [OpencodeClient.Generated.PromptReferenceAttachment.t()] | nil,
          text: String.t(),
          time: OpencodeClient.Generated.SessionMessageUserTime.t(),
          type: String.t()
        }

  defstruct [:agents, :files, :id, :metadata, :references, :text, :time, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      agents: [{OpencodeClient.Generated.PromptAgentAttachment, :t}],
      files: [{OpencodeClient.Generated.PromptFileAttachment, :t}],
      id: :string,
      metadata: :map,
      references: [{OpencodeClient.Generated.PromptReferenceAttachment, :t}],
      text: :string,
      time: {OpencodeClient.Generated.SessionMessageUserTime, :t},
      type: {:const, "user"}
    ]
  end
end
