defmodule OpencodeClient.Generated.SyncEventSessionUpdatedDataInfoModel do
  @moduledoc """
  Provides struct and type for a SyncEventSessionUpdatedDataInfoModel
  """

  @type t :: %__MODULE__{id: String.t(), providerID: String.t(), variant: String.t() | nil}

  defstruct [:id, :providerID, :variant]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [id: :string, providerID: :string, variant: :string]
  end
end
