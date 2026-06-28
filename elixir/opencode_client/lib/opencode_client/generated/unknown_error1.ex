defmodule OpencodeClient.Generated.UnknownError1 do
  @moduledoc """
  Provides struct and type for a UnknownError1
  """

  @type t :: %__MODULE__{_tag: String.t(), message: String.t(), ref: String.t() | nil}

  defstruct [:_tag, :message, :ref]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "UnknownError"}, message: :string, ref: :string]
  end
end
