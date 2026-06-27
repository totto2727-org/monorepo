defmodule OpencodeClient.Generated.EventSessionNextStepStartedProperties do
  @moduledoc """
  Provides struct and type for a EventSessionNextStepStartedProperties
  """

  @type t :: %__MODULE__{
          agent: String.t(),
          model: OpencodeClient.Generated.EventSessionNextStepStartedPropertiesModel.t(),
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
      model: {OpencodeClient.Generated.EventSessionNextStepStartedPropertiesModel, :t},
      sessionID: :string,
      snapshot: :string,
      timestamp: :number
    ]
  end
end
