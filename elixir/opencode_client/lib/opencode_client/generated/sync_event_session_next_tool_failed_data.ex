defmodule OpencodeClient.Generated.SyncEventSessionNextToolFailedData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextToolFailedData
  """

  @type t :: %__MODULE__{
          callID: String.t(),
          error: OpencodeClient.Generated.SessionErrorUnknown.t(),
          provider: OpencodeClient.Generated.SyncEventSessionNextToolFailedDataProvider.t(),
          sessionID: String.t(),
          timestamp: number
        }

  defstruct [:callID, :error, :provider, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      callID: :string,
      error: {OpencodeClient.Generated.SessionErrorUnknown, :t},
      provider: {OpencodeClient.Generated.SyncEventSessionNextToolFailedDataProvider, :t},
      sessionID: :string,
      timestamp: :number
    ]
  end
end
