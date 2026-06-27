defmodule OpencodeClient.Generated.EventSessionDeletedProperties do
  @moduledoc """
  Provides struct and type for a EventSessionDeletedProperties
  """

  @type t :: %__MODULE__{info: OpencodeClient.Generated.Session.t(), sessionID: String.t()}

  defstruct [:info, :sessionID]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [info: {OpencodeClient.Generated.Session, :t}, sessionID: :string]
  end
end
