defmodule OpencodeClient.Generated.EventSessionNextTextEnded do
  @moduledoc """
  Provides struct and type for a EventSessionNextTextEnded
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.EventSessionNextTextEndedProperties.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.EventSessionNextTextEndedProperties, :t},
      type: {:const, "session.next.text.ended"}
    ]
  end
end
