defmodule OpencodeClient.Generated.EventSessionNextShellStartedProperties do
  @moduledoc """
  Provides struct and type for a EventSessionNextShellStartedProperties
  """

  @type t :: %__MODULE__{
          callID: String.t(),
          command: String.t(),
          sessionID: String.t(),
          timestamp: number
        }

  defstruct [:callID, :command, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [callID: :string, command: :string, sessionID: :string, timestamp: :number]
  end
end
