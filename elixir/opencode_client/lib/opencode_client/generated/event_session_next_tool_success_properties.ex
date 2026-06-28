defmodule OpencodeClient.Generated.EventSessionNextToolSuccessProperties do
  @moduledoc """
  Provides struct and type for a EventSessionNextToolSuccessProperties
  """

  @type t :: %__MODULE__{
          callID: String.t(),
          content: [
            OpencodeClient.Generated.ToolFileContent.t()
            | OpencodeClient.Generated.ToolTextContent.t()
          ],
          provider: OpencodeClient.Generated.EventSessionNextToolSuccessPropertiesProvider.t(),
          sessionID: String.t(),
          structured: map,
          timestamp: number
        }

  defstruct [:callID, :content, :provider, :sessionID, :structured, :timestamp]

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
      provider: {OpencodeClient.Generated.EventSessionNextToolSuccessPropertiesProvider, :t},
      sessionID: :string,
      structured: :map,
      timestamp: :number
    ]
  end
end
