defmodule OpencodeClient.Generated.SyncEventSessionNextCompactionStarted do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextCompactionStarted
  """

  @type t :: %__MODULE__{
          aggregateID: String.t(),
          data: OpencodeClient.Generated.SyncEventSessionNextCompactionStartedData.t(),
          id: String.t(),
          name: String.t(),
          seq: number,
          type: String.t()
        }

  defstruct [:aggregateID, :data, :id, :name, :seq, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      aggregateID: {:const, "sessionID"},
      data: {OpencodeClient.Generated.SyncEventSessionNextCompactionStartedData, :t},
      id: :string,
      name: {:const, "session.next.compaction.started.1"},
      seq: :number,
      type: {:const, "sync"}
    ]
  end
end
