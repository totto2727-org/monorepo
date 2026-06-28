defmodule OpencodeClient.Generated.SyncEventSessionNextToolInputStartedData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextToolInputStartedData
  """

  @type t :: %__MODULE__{
          callID: String.t(),
          name: String.t(),
          sessionID: String.t(),
          timestamp: number
        }

  defstruct [:callID, :name, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [callID: :string, name: :string, sessionID: :string, timestamp: :number]
  end
end
