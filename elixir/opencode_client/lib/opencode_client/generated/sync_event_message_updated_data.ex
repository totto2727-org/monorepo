defmodule OpencodeClient.Generated.SyncEventMessageUpdatedData do
  @moduledoc """
  Provides struct and type for a SyncEventMessageUpdatedData
  """

  @type t :: %__MODULE__{
          info:
            OpencodeClient.Generated.AssistantMessage.t()
            | OpencodeClient.Generated.UserMessage.t(),
          sessionID: String.t()
        }

  defstruct [:info, :sessionID]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      info:
        {:union,
         [
           {OpencodeClient.Generated.AssistantMessage, :t},
           {OpencodeClient.Generated.UserMessage, :t}
         ]},
      sessionID: :string
    ]
  end
end
