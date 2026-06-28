defmodule OpencodeClient.Generated.EventSessionNextToolProgressProperties do
  @moduledoc """
  Provides struct and type for a EventSessionNextToolProgressProperties
  """

  @type t :: %__MODULE__{
          callID: String.t(),
          content: [
            OpencodeClient.Generated.ToolFileContent.t()
            | OpencodeClient.Generated.ToolTextContent.t()
          ],
          sessionID: String.t(),
          structured: map,
          timestamp: number
        }

  defstruct [:callID, :content, :sessionID, :structured, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      callID: :string,
      content: [
        union: [
          {OpencodeClient.Generated.ToolFileContent, :t},
          {OpencodeClient.Generated.ToolTextContent, :t}
        ]
      ],
      sessionID: :string,
      structured: :map,
      timestamp: :number
    ]
  end
end
