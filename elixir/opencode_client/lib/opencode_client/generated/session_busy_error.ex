defmodule OpencodeClient.Generated.SessionBusyError do
  @moduledoc """
  Provides struct and type for a SessionBusyError
  """

  @type t :: %__MODULE__{_tag: String.t(), message: String.t(), sessionID: String.t()}

  defstruct [:_tag, :message, :sessionID]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "SessionBusyError"}, message: :string, sessionID: :string]
  end
end
