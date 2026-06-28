defmodule OpencodeClient.Generated.SyncEventSessionNextRetriedData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextRetriedData
  """

  @type t :: %__MODULE__{
          attempt: number,
          error: OpencodeClient.Generated.SessionNextRetryError.t(),
          sessionID: String.t(),
          timestamp: number
        }

  defstruct [:attempt, :error, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      attempt: :number,
      error: {OpencodeClient.Generated.SessionNextRetryError, :t},
      sessionID: :string,
      timestamp: :number
    ]
  end
end
