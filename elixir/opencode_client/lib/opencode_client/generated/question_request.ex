defmodule OpencodeClient.Generated.QuestionRequest do
  @moduledoc """
  Provides struct and type for a QuestionRequest
  """

  @type t :: %__MODULE__{
          id: String.t(),
          questions: [OpencodeClient.Generated.QuestionInfo.t()],
          sessionID: String.t(),
          tool: OpencodeClient.Generated.QuestionTool.t() | nil
        }

  defstruct [:id, :questions, :sessionID, :tool]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      questions: [{OpencodeClient.Generated.QuestionInfo, :t}],
      sessionID: :string,
      tool: {OpencodeClient.Generated.QuestionTool, :t}
    ]
  end
end
