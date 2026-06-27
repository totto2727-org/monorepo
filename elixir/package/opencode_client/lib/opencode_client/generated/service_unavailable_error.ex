defmodule OpencodeClient.Generated.ServiceUnavailableError do
  @moduledoc """
  Provides struct and type for a ServiceUnavailableError
  """

  @type t :: %__MODULE__{_tag: String.t(), message: String.t(), service: String.t() | nil}

  defstruct [:_tag, :message, :service]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "ServiceUnavailableError"}, message: :string, service: :string]
  end
end
