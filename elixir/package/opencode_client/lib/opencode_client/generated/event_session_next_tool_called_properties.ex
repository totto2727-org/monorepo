defmodule OpencodeClient.Generated.EventSessionNextToolCalledProperties do
  @moduledoc """
  Provides struct and type for a EventSessionNextToolCalledProperties
  """

  @type t :: %__MODULE__{
          callID: String.t(),
          input: map,
          provider: OpencodeClient.Generated.EventSessionNextToolCalledPropertiesProvider.t(),
          sessionID: String.t(),
          timestamp: number,
          tool: String.t()
        }

  defstruct [:callID, :input, :provider, :sessionID, :timestamp, :tool]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      callID: :string,
      input: :map,
      provider: {OpencodeClient.Generated.EventSessionNextToolCalledPropertiesProvider, :t},
      sessionID: :string,
      timestamp: :number,
      tool: :string
    ]
  end
end
