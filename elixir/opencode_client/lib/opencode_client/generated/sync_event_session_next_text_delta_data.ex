defmodule OpencodeClient.Generated.SyncEventSessionNextTextDeltaData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextTextDeltaData
  """

  @type t :: %__MODULE__{delta: String.t(), sessionID: String.t(), timestamp: number}

  defstruct [:delta, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [delta: :string, sessionID: :string, timestamp: :number]
  end
end
