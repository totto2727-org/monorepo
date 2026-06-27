defmodule OpencodeClient.Generated.UnauthorizedError do
  @moduledoc """
  Provides struct and type for a UnauthorizedError
  """

  @type t :: %__MODULE__{_tag: String.t(), message: String.t()}

  defstruct [:_tag, :message]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "UnauthorizedError"}, message: :string]
  end
end
