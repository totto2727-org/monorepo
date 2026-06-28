defmodule OpencodeClient.Generated.EventSessionNextReasoningDeltaProperties do
  @moduledoc """
  Provides struct and type for a EventSessionNextReasoningDeltaProperties
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
