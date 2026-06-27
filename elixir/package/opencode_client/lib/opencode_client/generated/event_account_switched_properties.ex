defmodule OpencodeClient.Generated.EventAccountSwitchedProperties do
  @moduledoc """
  Provides struct and type for a EventAccountSwitchedProperties
  """

  @type t :: %__MODULE__{from: String.t() | nil, serviceID: String.t(), to: String.t() | nil}

  defstruct [:from, :serviceID, :to]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [from: :string, serviceID: :string, to: :string]
  end
end
