defmodule OpencodeClient.Generated.ConfigAgent do
  @moduledoc """
  Provides struct and type for a ConfigAgent
  """

  @type t :: %__MODULE__{
          build: OpencodeClient.Generated.AgentConfig.t() | nil,
          compaction: OpencodeClient.Generated.AgentConfig.t() | nil,
          explore: OpencodeClient.Generated.AgentConfig.t() | nil,
          general: OpencodeClient.Generated.AgentConfig.t() | nil,
          plan: OpencodeClient.Generated.AgentConfig.t() | nil,
          scout: OpencodeClient.Generated.AgentConfig.t() | nil,
          summary: OpencodeClient.Generated.AgentConfig.t() | nil,
          title: OpencodeClient.Generated.AgentConfig.t() | nil
        }

  defstruct [:build, :compaction, :explore, :general, :plan, :scout, :summary, :title]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      build: {OpencodeClient.Generated.AgentConfig, :t},
      compaction: {OpencodeClient.Generated.AgentConfig, :t},
      explore: {OpencodeClient.Generated.AgentConfig, :t},
      general: {OpencodeClient.Generated.AgentConfig, :t},
      plan: {OpencodeClient.Generated.AgentConfig, :t},
      scout: {OpencodeClient.Generated.AgentConfig, :t},
      summary: {OpencodeClient.Generated.AgentConfig, :t},
      title: {OpencodeClient.Generated.AgentConfig, :t}
    ]
  end
end
