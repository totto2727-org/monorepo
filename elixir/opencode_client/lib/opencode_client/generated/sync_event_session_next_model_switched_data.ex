defmodule OpencodeClient.Generated.SyncEventSessionNextModelSwitchedData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextModelSwitchedData
  """

  @type t :: %__MODULE__{
          model: OpencodeClient.Generated.SyncEventSessionNextModelSwitchedDataModel.t(),
          sessionID: String.t(),
          timestamp: number
        }

  defstruct [:model, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      model: {OpencodeClient.Generated.SyncEventSessionNextModelSwitchedDataModel, :t},
      sessionID: :string,
      timestamp: :number
    ]
  end
end
