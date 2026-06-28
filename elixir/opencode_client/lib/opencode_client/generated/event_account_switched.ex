defmodule OpencodeClient.Generated.EventAccountSwitched do
  @moduledoc """
  Provides struct and type for a EventAccountSwitched
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.EventAccountSwitchedProperties.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.EventAccountSwitchedProperties, :t},
      type: {:const, "account.switched"}
    ]
  end
end
