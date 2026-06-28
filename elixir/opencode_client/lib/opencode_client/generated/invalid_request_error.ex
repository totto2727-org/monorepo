defmodule OpencodeClient.Generated.InvalidRequestError do
  @moduledoc """
  Provides struct and type for a InvalidRequestError
  """

  @type t :: %__MODULE__{
          _tag: String.t(),
          field: String.t() | nil,
          kind: String.t() | nil,
          message: String.t()
        }

  defstruct [:_tag, :field, :kind, :message]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "InvalidRequestError"}, field: :string, kind: :string, message: :string]
  end
end
