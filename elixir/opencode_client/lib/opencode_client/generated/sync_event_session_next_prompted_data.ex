defmodule OpencodeClient.Generated.SyncEventSessionNextPromptedData do
  @moduledoc """
  Provides struct and type for a SyncEventSessionNextPromptedData
  """

  @type t :: %__MODULE__{
          prompt: OpencodeClient.Generated.Prompt.t(),
          sessionID: String.t(),
          timestamp: number
        }

  defstruct [:prompt, :sessionID, :timestamp]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [prompt: {OpencodeClient.Generated.Prompt, :t}, sessionID: :string, timestamp: :number]
  end
end
