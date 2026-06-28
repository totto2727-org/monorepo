defmodule OpencodeClient.Generated.Prompt do
  @moduledoc """
  Provides struct and type for a Prompt
  """

  @type t :: %__MODULE__{
          agents: [OpencodeClient.Generated.PromptAgentAttachment.t()] | nil,
          files: [OpencodeClient.Generated.PromptFileAttachment.t()] | nil,
          references: [OpencodeClient.Generated.PromptReferenceAttachment.t()] | nil,
          text: String.t()
        }

  defstruct [:agents, :files, :references, :text]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      agents: [{OpencodeClient.Generated.PromptAgentAttachment, :t}],
      files: [{OpencodeClient.Generated.PromptFileAttachment, :t}],
      references: [{OpencodeClient.Generated.PromptReferenceAttachment, :t}],
      text: :string
    ]
  end
end
