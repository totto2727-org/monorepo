defmodule OpencodeClient.Generated.SyncEventSessionNextAgentSwitched do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextAgentSwitched
  """

  @type t :: %__MODULE__{
          aggregateID: String.t(),
          data: OpencodeClient.Generated.SyncEventSessionNextAgentSwitchedData.t(),
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
      data: {OpencodeClient.Generated.SyncEventSessionNextAgentSwitchedData, :t},
      id: :string,
      name: {:const, "session.next.agent.switched.1"},
      seq: :number,
      type: {:const, "sync"}
    ]
  end
end
