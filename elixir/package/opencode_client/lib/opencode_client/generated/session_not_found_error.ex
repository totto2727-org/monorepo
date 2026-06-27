defmodule OpencodeClient.Generated.SessionNotFoundError do
  @moduledoc """
  Provides struct and type for a SessionNotFoundError
  """

  @type t :: %__MODULE__{_tag: String.t(), message: String.t(), sessionID: String.t()}

  defstruct [:_tag, :message, :sessionID]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "SessionNotFoundError"}, message: :string, sessionID: :string]
  end
end
