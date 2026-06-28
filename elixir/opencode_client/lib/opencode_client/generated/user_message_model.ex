defmodule OpencodeClient.Generated.UserMessageModel do
  @moduledoc """
  Provides struct and type for a UserMessageModel
  """

  @type t :: %__MODULE__{modelID: String.t(), providerID: String.t(), variant: String.t() | nil}

  defstruct [:modelID, :providerID, :variant]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [modelID: :string, providerID: :string, variant: :string]
  end
end
