defmodule OpencodeClient.Generated.EventMessagePartRemoved do
  @moduledoc """
  Provides struct and type for a EventMessagePartRemoved
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.EventMessagePartRemovedProperties.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.EventMessagePartRemovedProperties, :t},
      type: {:const, "message.part.removed"}
    ]
  end
end
