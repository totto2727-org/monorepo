defmodule OpencodeClient.Generated.EventSessionCompacted do
  @moduledoc """
  Provides struct and type for a EventSessionCompacted
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.EventSessionCompactedProperties.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.EventSessionCompactedProperties, :t},
      type: {:const, "session.compacted"}
    ]
  end
end
