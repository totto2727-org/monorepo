defmodule OpencodeClient.Generated.SessionMessageToolStateCompleted do
  @moduledoc """
  Provides struct and type for a SessionMessageToolStateCompleted
  """

  @type t :: %__MODULE__{
          attachments: [OpencodeClient.Generated.PromptFileAttachment.t()] | nil,
          content: [
            OpencodeClient.Generated.ToolFileContent.t()
            | OpencodeClient.Generated.ToolTextContent.t()
          ],
          input: map,
          status: String.t(),
          structured: map
        }

  defstruct [:attachments, :content, :input, :status, :structured]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      attachments: [{OpencodeClient.Generated.PromptFileAttachment, :t}],
      content: [
        union: [
          {OpencodeClient.Generated.ToolFileContent, :t},
          {OpencodeClient.Generated.ToolTextContent, :t}
        ]
      ],
      input: :map,
      status: {:const, "completed"},
      structured: :map
    ]
  end
end
