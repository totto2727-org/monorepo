defmodule OpencodeClient.Generated.PtyForbiddenError do
  @moduledoc """
  Provides struct and type for a PtyForbiddenError
  """

  @type t :: %__MODULE__{_tag: String.t(), message: String.t()}

  defstruct [:_tag, :message]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "PtyForbiddenError"}, message: :string]
  end
end
