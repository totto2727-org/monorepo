defmodule OpencodeClient.Generated.PtyNotFoundError do
  @moduledoc """
  Provides struct and type for a PtyNotFoundError
  """

  @type t :: %__MODULE__{_tag: String.t(), message: String.t(), ptyID: String.t()}

  defstruct [:_tag, :message, :ptyID]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "PtyNotFoundError"}, message: :string, ptyID: :string]
  end
end
