defmodule OpencodeClient.Generated.SyncEventSessionNextShellEndedData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextShellEndedData
  """

  @type t :: %__MODULE__{
          callID: String.t(),
          output: String.t(),
          sessionID: String.t(),
          timestamp: number
        }

  defstruct [:callID, :output, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [callID: :string, output: :string, sessionID: :string, timestamp: :number]
  end
end
