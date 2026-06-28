defmodule OpencodeClient.Generated.QuestionNotFoundError do
  @moduledoc """
  Provides struct and type for a QuestionNotFoundError
  """

  @type t :: %__MODULE__{_tag: String.t(), message: String.t(), requestID: String.t()}

  defstruct [:_tag, :message, :requestID]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "QuestionNotFoundError"}, message: :string, requestID: :string]
  end
end
