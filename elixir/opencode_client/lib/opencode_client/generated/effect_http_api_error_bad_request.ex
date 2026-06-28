defmodule OpencodeClient.Generated.EffectHttpApiErrorBadRequest do
  @moduledoc """
  Provides struct and type for a EffectHttpApiErrorBadRequest
  """

  @type t :: %__MODULE__{_tag: String.t()}

  defstruct [:_tag]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [_tag: {:const, "BadRequest"}]
  end
end
