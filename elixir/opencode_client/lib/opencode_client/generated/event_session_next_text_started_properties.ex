defmodule OpencodeClient.Generated.EventSessionNextTextStartedProperties do
  @moduledoc """
  Provides struct and type for a EventSessionNextTextStartedProperties
  """

  @type t :: %__MODULE__{sessionID: String.t(), timestamp: number}

  defstruct [:sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [sessionID: :string, timestamp: :number]
  end
end
