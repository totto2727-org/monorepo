defmodule OpencodeClient.Generated.SyncEventSessionNextStepStartedData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextStepStartedData
  """

  @type t :: %__MODULE__{
          agent: String.t(),
          model: OpencodeClient.Generated.SyncEventSessionNextStepStartedDataModel.t(),
          sessionID: String.t(),
          snapshot: String.t() | nil,
          timestamp: number
        }

  defstruct [:agent, :model, :sessionID, :snapshot, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      agent: :string,
      model: {OpencodeClient.Generated.SyncEventSessionNextStepStartedDataModel, :t},
      sessionID: :string,
      snapshot: :string,
      timestamp: :number
    ]
  end
end
