defmodule OpencodeClient.Generated.PromptAgentAttachment do
  @moduledoc """
  Provides struct and type for a PromptAgentAttachment
  """

  @type t :: %__MODULE__{
          name: String.t(),
          source: OpencodeClient.Generated.PromptSource.t() | nil
        }

  defstruct [:name, :source]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [name: :string, source: {OpencodeClient.Generated.PromptSource, :t}]
  end
end
