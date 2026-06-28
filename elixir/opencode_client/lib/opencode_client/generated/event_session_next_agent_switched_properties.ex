defmodule OpencodeClient.Generated.EventSessionNextAgentSwitchedProperties do
  @moduledoc """
  Provides struct and type for a EventSessionNextAgentSwitchedProperties
  """

  @type t :: %__MODULE__{agent: String.t(), sessionID: String.t(), timestamp: number}

  defstruct [:agent, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [agent: :string, sessionID: :string, timestamp: :number]
  end
end
