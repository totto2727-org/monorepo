defmodule OpencodeClient.Generated.WorkspaceWarpError do
  @moduledoc """
  Provides struct and type for a WorkspaceWarpError
  """

  @type t :: %__MODULE__{
          data: OpencodeClient.Generated.WorkspaceWarpErrorData.t(),
          name: String.t()
        }

  defstruct [:data, :name]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      data: {OpencodeClient.Generated.WorkspaceWarpErrorData, :t},
      name: {:const, "WorkspaceWarpError"}
    ]
  end
end
