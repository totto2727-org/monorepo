defmodule OpencodeClient.Generated.VcsApplyError do
  @moduledoc """
  Provides struct and type for a VcsApplyError
  """

  @type t :: %__MODULE__{data: OpencodeClient.Generated.VcsApplyErrorData.t(), name: String.t()}

  defstruct [:data, :name]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [data: {OpencodeClient.Generated.VcsApplyErrorData, :t}, name: {:const, "VcsApplyError"}]
  end
end
