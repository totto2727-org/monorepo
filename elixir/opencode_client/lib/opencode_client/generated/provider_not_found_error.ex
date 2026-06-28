defmodule OpencodeClient.Generated.ProviderNotFoundError do
  @moduledoc """
  Provides struct and type for a ProviderNotFoundError
  """

  @type t :: %__MODULE__{_tag: String.t(), message: String.t(), providerID: String.t()}

  defstruct [:_tag, :message, :providerID]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "ProviderNotFoundError"}, message: :string, providerID: :string]
  end
end
