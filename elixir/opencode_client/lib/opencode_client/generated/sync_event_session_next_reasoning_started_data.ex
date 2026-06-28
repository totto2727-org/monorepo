defmodule OpencodeClient.Generated.SyncEventSessionNextReasoningStartedData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextReasoningStartedData
  """

  @type t :: %__MODULE__{reasoningID: String.t(), sessionID: String.t(), timestamp: number}

  defstruct [:reasoningID, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [reasoningID: :string, sessionID: :string, timestamp: :number]
  end
end
