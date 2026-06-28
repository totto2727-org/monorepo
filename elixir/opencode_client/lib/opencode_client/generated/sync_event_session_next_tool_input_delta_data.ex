defmodule OpencodeClient.Generated.SyncEventSessionNextToolInputDeltaData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextToolInputDeltaData
  """

  @type t :: %__MODULE__{
          callID: String.t(),
          delta: String.t(),
          sessionID: String.t(),
          timestamp: number
        }

  defstruct [:callID, :delta, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [callID: :string, delta: :string, sessionID: :string, timestamp: :number]
  end
end
