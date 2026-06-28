defmodule OpencodeClient.Generated.SyncEventSessionNextToolInputEndedData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextToolInputEndedData
  """

  @type t :: %__MODULE__{
          callID: String.t(),
          sessionID: String.t(),
          text: String.t(),
          timestamp: number
        }

  defstruct [:callID, :sessionID, :text, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [callID: :string, sessionID: :string, text: :string, timestamp: :number]
  end
end
