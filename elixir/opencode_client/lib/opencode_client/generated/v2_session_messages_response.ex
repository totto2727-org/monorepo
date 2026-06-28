defmodule OpencodeClient.Generated.V2SessionMessagesResponse do
  @moduledoc """
  Provides struct and type for a V2SessionMessagesResponse
  """

  @type t :: %__MODULE__{
          cursor: OpencodeClient.Generated.V2SessionMessagesResponseCursor.t(),
          items: [
            OpencodeClient.Generated.SessionMessageAgentSwitched.t()
            | OpencodeClient.Generated.SessionMessageAssistant.t()
            | OpencodeClient.Generated.SessionMessageCompaction.t()
            | OpencodeClient.Generated.SessionMessageModelSwitched.t()
            | OpencodeClient.Generated.SessionMessageShell.t()
            | OpencodeClient.Generated.SessionMessageSynthetic.t()
            | OpencodeClient.Generated.SessionMessageUser.t()
          ]
        }

  defstruct [:cursor, :items]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      cursor: {OpencodeClient.Generated.V2SessionMessagesResponseCursor, :t},
      items: [
        union: [
          {OpencodeClient.Generated.SessionMessageAgentSwitched, :t},
          {OpencodeClient.Generated.SessionMessageAssistant, :t},
          {OpencodeClient.Generated.SessionMessageCompaction, :t},
          {OpencodeClient.Generated.SessionMessageModelSwitched, :t},
          {OpencodeClient.Generated.SessionMessageShell, :t},
          {OpencodeClient.Generated.SessionMessageSynthetic, :t},
          {OpencodeClient.Generated.SessionMessageUser, :t}
        ]
      ]
    ]
  end
end
