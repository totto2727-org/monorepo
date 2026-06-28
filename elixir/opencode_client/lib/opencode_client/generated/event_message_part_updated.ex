defmodule OpencodeClient.Generated.EventMessagePartUpdated do
  @moduledoc """
  Provides struct and type for a EventMessagePartUpdated
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.EventMessagePartUpdatedProperties.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.EventMessagePartUpdatedProperties, :t},
      type: {:const, "message.part.updated"}
    ]
  end
end
