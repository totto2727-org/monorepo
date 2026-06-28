defmodule OpencodeClient.Generated.PermissionNotFoundError do
  @moduledoc """
  Provides struct and type for a PermissionNotFoundError
  """

  @type t :: %__MODULE__{_tag: String.t(), message: String.t(), requestID: String.t()}

  defstruct [:_tag, :message, :requestID]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "PermissionNotFoundError"}, message: :string, requestID: :string]
  end
end
