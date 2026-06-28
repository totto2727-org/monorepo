defmodule OpencodeClient.Generated.SyncEventSessionNextCompactionStartedData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextCompactionStartedData
  """

  @type t :: %__MODULE__{reason: String.t(), sessionID: String.t(), timestamp: number}

  defstruct [:reason, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [reason: {:enum, ["auto", "manual"]}, sessionID: :string, timestamp: :number]
  end
end
