defmodule OpencodeClient.Generated.ProjectNotFoundError do
  @moduledoc """
  Provides struct and type for a ProjectNotFoundError
  """

  @type t :: %__MODULE__{_tag: String.t(), message: String.t(), projectID: String.t()}

  defstruct [:_tag, :message, :projectID]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "ProjectNotFoundError"}, message: :string, projectID: :string]
  end
end
