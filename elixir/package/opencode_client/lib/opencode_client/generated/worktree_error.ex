defmodule OpencodeClient.Generated.WorktreeError do
  @moduledoc """
  Provides struct and type for a WorktreeError
  """

  @type t :: %__MODULE__{data: OpencodeClient.Generated.WorktreeErrorData.t(), name: String.t()}

  defstruct [:data, :name]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      data: {OpencodeClient.Generated.WorktreeErrorData, :t},
      name:
        {:enum,
         [
           "WorktreeNotGitError",
           "WorktreeNameGenerationFailedError",
           "WorktreeCreateFailedError",
           "WorktreeStartCommandFailedError",
           "WorktreeRemoveFailedError",
           "WorktreeResetFailedError",
           "WorktreeListFailedError"
         ]}
    ]
  end
end
