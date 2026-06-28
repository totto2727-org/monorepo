defmodule OpencodeClient.Generated.EventWorktreeReady do
  @moduledoc """
  Provides struct and type for a EventWorktreeReady
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.EventWorktreeReadyProperties.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.EventWorktreeReadyProperties, :t},
      type: {:const, "worktree.ready"}
    ]
  end
end
