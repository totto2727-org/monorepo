defmodule OpencodeClient.Generated.V2SessionsResponse do
  @moduledoc """
  Provides struct and type for a V2SessionsResponse
  """

  @type t :: %__MODULE__{
          cursor: OpencodeClient.Generated.V2SessionsResponseCursor.t(),
          items: [OpencodeClient.Generated.SessionInfo.t()]
        }

  defstruct [:cursor, :items]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      cursor: {OpencodeClient.Generated.V2SessionsResponseCursor, :t},
      items: [{OpencodeClient.Generated.SessionInfo, :t}]
    ]
  end
end
