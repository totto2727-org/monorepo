defmodule OpencodeClient.Generated.SessionInfoTokens do
  @moduledoc """
  Provides struct and type for a SessionInfoTokens
  """

  @type t :: %__MODULE__{
          cache: OpencodeClient.Generated.SessionInfoTokensCache.t(),
          input: number,
          output: number,
          reasoning: number
        }

  defstruct [:cache, :input, :output, :reasoning]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      cache: {OpencodeClient.Generated.SessionInfoTokensCache, :t},
      input: :number,
      output: :number,
      reasoning: :number
    ]
  end
end
