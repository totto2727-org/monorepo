defmodule OpencodeClient.Generated.SyncEventSessionNextReasoningEndedData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextReasoningEndedData
  """

  @type t :: %__MODULE__{
          reasoningID: String.t(),
          sessionID: String.t(),
          text: String.t(),
          timestamp: number
        }

  defstruct [:reasoningID, :sessionID, :text, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [reasoningID: :string, sessionID: :string, text: :string, timestamp: :number]
  end
end
