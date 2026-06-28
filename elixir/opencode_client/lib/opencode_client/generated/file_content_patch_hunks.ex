defmodule OpencodeClient.Generated.FileContentPatchHunks do
  @moduledoc """
  Provides struct and type for a FileContentPatchHunks
  """

  @type t :: %__MODULE__{
          lines: [String.t()],
          newLines: integer,
          newStart: integer,
          oldLines: integer,
          oldStart: integer
        }

  defstruct [:lines, :newLines, :newStart, :oldLines, :oldStart]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      lines: [:string],
      newLines: :integer,
      newStart: :integer,
      oldLines: :integer,
      oldStart: :integer
    ]
  end
end
