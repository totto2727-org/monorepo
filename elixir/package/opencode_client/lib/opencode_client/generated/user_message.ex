defmodule OpencodeClient.Generated.UserMessage do
  @moduledoc """
  Provides struct and type for a UserMessage
  """

  @type t :: %__MODULE__{
          agent: String.t(),
          format:
            OpencodeClient.Generated.OutputFormatJsonSchema.t()
            | OpencodeClient.Generated.OutputFormatText.t()
            | nil,
          id: String.t(),
          model: OpencodeClient.Generated.UserMessageModel.t(),
          role: String.t(),
          sessionID: String.t(),
          summary: OpencodeClient.Generated.UserMessageSummary.t() | nil,
          system: String.t() | nil,
          time: OpencodeClient.Generated.UserMessageTime.t(),
          tools: map | nil
        }

  defstruct [:agent, :format, :id, :model, :role, :sessionID, :summary, :system, :time, :tools]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      agent: :string,
      format:
        {:union,
         [
           {OpencodeClient.Generated.OutputFormatJsonSchema, :t},
           {OpencodeClient.Generated.OutputFormatText, :t}
         ]},
      id: :string,
      model: {OpencodeClient.Generated.UserMessageModel, :t},
      role: {:const, "user"},
      sessionID: :string,
      summary: {OpencodeClient.Generated.UserMessageSummary, :t},
      system: :string,
      time: {OpencodeClient.Generated.UserMessageTime, :t},
      tools: :map
    ]
  end
end
