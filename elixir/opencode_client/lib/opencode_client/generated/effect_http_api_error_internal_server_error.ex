defmodule OpencodeClient.Generated.EffectHttpApiErrorInternalServerError do
  @moduledoc """
  Provides struct and type for a EffectHttpApiErrorInternalServerError
  """

  @type t :: %__MODULE__{_tag: String.t()}

  defstruct [:_tag]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "InternalServerError"}]
  end
end
