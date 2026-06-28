defmodule OpencodeClient.Generated.EventSessionNextCompactionDeltaProperties do
  @moduledoc """
  Provides struct and type for a EventSessionNextCompactionDeltaProperties
  """

  @type t :: %__MODULE__{sessionID: String.t(), text: String.t(), timestamp: number}

  defstruct [:sessionID, :text, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [sessionID: :string, text: :string, timestamp: :number]
  end
end
