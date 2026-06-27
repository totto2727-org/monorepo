defmodule OpencodeClient.Generated.SessionMessageAssistantTool do
  @moduledoc """
  Provides struct and type for a SessionMessageAssistantTool
  """

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          provider: OpencodeClient.Generated.SessionMessageAssistantToolProvider.t() | nil,
          state:
            OpencodeClient.Generated.SessionMessageToolStateCompleted.t()
            | OpencodeClient.Generated.SessionMessageToolStateError.t()
            | OpencodeClient.Generated.SessionMessageToolStatePending.t()
            | OpencodeClient.Generated.SessionMessageToolStateRunning.t(),
          time: OpencodeClient.Generated.SessionMessageAssistantToolTime.t(),
          type: String.t()
        }

  defstruct [:id, :name, :provider, :state, :time, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      name: :string,
      provider: {OpencodeClient.Generated.SessionMessageAssistantToolProvider, :t},
      state:
        {:union,
         [
           {OpencodeClient.Generated.SessionMessageToolStateCompleted, :t},
           {OpencodeClient.Generated.SessionMessageToolStateError, :t},
           {OpencodeClient.Generated.SessionMessageToolStatePending, :t},
           {OpencodeClient.Generated.SessionMessageToolStateRunning, :t}
         ]},
      time: {OpencodeClient.Generated.SessionMessageAssistantToolTime, :t},
      type: {:const, "tool"}
    ]
  end
end
