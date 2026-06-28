defmodule OpencodeClient.Generated.EventSessionNextStepEndedProperties do
  @moduledoc """
  Provides struct and type for a EventSessionNextStepEndedProperties
  """

  @type t :: %__MODULE__{
          cost: number,
          finish: String.t(),
          sessionID: String.t(),
          snapshot: String.t() | nil,
          timestamp: number,
          tokens: OpencodeClient.Generated.EventSessionNextStepEndedPropertiesTokens.t()
        }

  defstruct [:cost, :finish, :sessionID, :snapshot, :timestamp, :tokens]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      cost: :number,
      finish: :string,
      sessionID: :string,
      snapshot: :string,
      timestamp: :number,
      tokens: {OpencodeClient.Generated.EventSessionNextStepEndedPropertiesTokens, :t}
    ]
  end
end
