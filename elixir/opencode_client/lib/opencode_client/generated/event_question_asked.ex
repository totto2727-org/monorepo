defmodule OpencodeClient.Generated.EventQuestionAsked do
  @moduledoc """
  Provides struct and type for a EventQuestionAsked
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.QuestionRequest.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.QuestionRequest, :t},
      type: {:const, "question.asked"}
    ]
  end
end
