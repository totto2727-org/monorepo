defmodule OpencodeClient.Generated.EventWorkspaceStatusProperties do
  @moduledoc """
  Provides struct and type for a EventWorkspaceStatusProperties
  """

  @type t :: %__MODULE__{status: String.t(), workspaceID: String.t()}

  defstruct [:status, :workspaceID]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [status: {:enum, ["connected", "connecting", "disconnected", "error"]}, workspaceID: :string]
  end
end
