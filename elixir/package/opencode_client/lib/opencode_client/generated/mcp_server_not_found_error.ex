defmodule OpencodeClient.Generated.McpServerNotFoundError do
  @moduledoc """
  Provides struct and type for a McpServerNotFoundError
  """

  @type t :: %__MODULE__{_tag: String.t(), message: String.t(), name: String.t()}

  defstruct [:_tag, :message, :name]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "McpServerNotFoundError"}, message: :string, name: :string]
  end
end
