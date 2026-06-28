defmodule OpencodeClient.Generated.SyncEventSessionUpdatedData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionUpdatedData
  """

  @type t :: %__MODULE__{
          info: OpencodeClient.Generated.SyncEventSessionUpdatedDataInfo.t(),
          sessionID: String.t()
        }

  defstruct [:info, :sessionID]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [info: {OpencodeClient.Generated.SyncEventSessionUpdatedDataInfo, :t}, sessionID: :string]
  end
end
