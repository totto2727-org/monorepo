defmodule OpencodeClient.Generated.EventSessionNextModelSwitchedProperties do
  @moduledoc """
  Provides struct and type for a EventSessionNextModelSwitchedProperties
  """

  @type t :: %__MODULE__{
          model: OpencodeClient.Generated.EventSessionNextModelSwitchedPropertiesModel.t(),
          sessionID: String.t(),
          timestamp: number
        }

  defstruct [:model, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      model: {OpencodeClient.Generated.EventSessionNextModelSwitchedPropertiesModel, :t},
      sessionID: :string,
      timestamp: :number
    ]
  end
end
