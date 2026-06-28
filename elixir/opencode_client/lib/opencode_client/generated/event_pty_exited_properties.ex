defmodule OpencodeClient.Generated.EventPtyExitedProperties do
  @moduledoc """
  Provides struct and type for a EventPtyExitedProperties
  """

  @type t :: %__MODULE__{exitCode: integer, id: String.t()}

  defstruct [:exitCode, :id]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [exitCode: :integer, id: :string]
  end
end
