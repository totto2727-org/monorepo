defmodule OpencodeClient.Generated.EventWorkspaceReady do
  @moduledoc """
  Provides struct and type for a EventWorkspaceReady
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.EventWorkspaceReadyProperties.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.EventWorkspaceReadyProperties, :t},
      type: {:const, "workspace.ready"}
    ]
  end
end
