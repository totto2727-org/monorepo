defmodule OpencodeClient.Generated.EventTuiToastShow1 do
  @moduledoc """
  Provides struct and type for a EventTuiToastShow1
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.EventTuiToastShow1Properties.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.EventTuiToastShow1Properties, :t},
      type: {:const, "tui.toast.show"}
    ]
  end
end
