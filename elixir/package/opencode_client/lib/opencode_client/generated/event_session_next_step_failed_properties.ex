defmodule OpencodeClient.Generated.EventSessionNextStepFailedProperties do
  @moduledoc """
  Provides struct and type for a EventSessionNextStepFailedProperties
  """

  @type t :: %__MODULE__{
          error: OpencodeClient.Generated.SessionErrorUnknown.t(),
          sessionID: String.t(),
          timestamp: number
        }

  defstruct [:error, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      error: {OpencodeClient.Generated.SessionErrorUnknown, :t},
      sessionID: :string,
      timestamp: :number
    ]
  end
end
