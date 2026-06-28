defmodule OpencodeClient.Generated.EventAccountRemoved do
  @moduledoc """
  Provides struct and type for a EventAccountRemoved
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.EventAccountRemovedProperties.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.EventAccountRemovedProperties, :t},
      type: {:const, "account.removed"}
    ]
  end
end
