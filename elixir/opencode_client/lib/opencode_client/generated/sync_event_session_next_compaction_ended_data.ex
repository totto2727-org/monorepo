defmodule OpencodeClient.Generated.SyncEventSessionNextCompactionEndedData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextCompactionEndedData
  """

  @type t :: %__MODULE__{
          include: String.t() | nil,
          sessionID: String.t(),
          text: String.t(),
          timestamp: number
        }

  defstruct [:include, :sessionID, :text, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [include: :string, sessionID: :string, text: :string, timestamp: :number]
  end
end
