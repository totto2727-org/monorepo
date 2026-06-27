defmodule OpencodeClient.Generated.EventSessionNextToolFailedProperties do
  @moduledoc """
  Provides struct and type for a EventSessionNextToolFailedProperties
  """

  @type t :: %__MODULE__{
          callID: String.t(),
          error: OpencodeClient.Generated.SessionErrorUnknown.t(),
          provider: OpencodeClient.Generated.EventSessionNextToolFailedPropertiesProvider.t(),
          sessionID: String.t(),
          timestamp: number
        }

  defstruct [:callID, :error, :provider, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      callID: :string,
      error: {OpencodeClient.Generated.SessionErrorUnknown, :t},
      provider: {OpencodeClient.Generated.EventSessionNextToolFailedPropertiesProvider, :t},
      sessionID: :string,
      timestamp: :number
    ]
  end
end
