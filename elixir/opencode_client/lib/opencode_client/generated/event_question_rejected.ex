defmodule OpencodeClient.Generated.EventQuestionRejected do
  @moduledoc """
  Provides struct and type for a EventQuestionRejected
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.QuestionRejected.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.QuestionRejected, :t},
      type: {:const, "question.rejected"}
    ]
  end
end
