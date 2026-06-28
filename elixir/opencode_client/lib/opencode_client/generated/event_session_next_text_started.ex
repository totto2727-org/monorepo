defmodule OpencodeClient.Generated.EventSessionNextTextStarted do
  @moduledoc """
  Provides struct and type for a EventSessionNextTextStarted
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.EventSessionNextTextStartedProperties.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.EventSessionNextTextStartedProperties, :t},
      type: {:const, "session.next.text.started"}
    ]
  end
end
