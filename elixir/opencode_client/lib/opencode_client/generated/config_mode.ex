defmodule OpencodeClient.Generated.ConfigMode do
  @moduledoc """
  Provides struct and type for a ConfigMode
  """

  @type t :: %__MODULE__{
          build: OpencodeClient.Generated.AgentConfig.t() | nil,
          plan: OpencodeClient.Generated.AgentConfig.t() | nil
        }

  defstruct [:build, :plan]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      build: {OpencodeClient.Generated.AgentConfig, :t},
      plan: {OpencodeClient.Generated.AgentConfig, :t}
    ]
  end
end
