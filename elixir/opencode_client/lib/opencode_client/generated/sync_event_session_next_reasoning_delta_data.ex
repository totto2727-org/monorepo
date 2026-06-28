defmodule OpencodeClient.Generated.SyncEventSessionNextReasoningDeltaData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextReasoningDeltaData
  """

  @type t :: %__MODULE__{
          delta: String.t(),
          reasoningID: String.t(),
          sessionID: String.t(),
          timestamp: number
        }

  defstruct [:delta, :reasoningID, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [delta: :string, reasoningID: :string, sessionID: :string, timestamp: :number]
  end
end
