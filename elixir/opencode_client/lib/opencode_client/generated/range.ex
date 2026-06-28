defmodule OpencodeClient.Generated.Range do
  @moduledoc """
  Provides struct and type for a Range
  """

  @type t :: %__MODULE__{
          end: OpencodeClient.Generated.RangeEnd.t(),
          start: OpencodeClient.Generated.RangeStart.t()
        }

  defstruct [:end, :start]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      end: {OpencodeClient.Generated.RangeEnd, :t},
      start: {OpencodeClient.Generated.RangeStart, :t}
    ]
  end
end
