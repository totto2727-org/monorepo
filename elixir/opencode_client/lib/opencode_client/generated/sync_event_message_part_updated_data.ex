defmodule OpencodeClient.Generated.SyncEventMessagePartUpdatedData do
  @moduledoc """
  Provides struct and type for a SyncEventMessagePartUpdatedData
  """

  @type t :: %__MODULE__{
          part:
            OpencodeClient.Generated.AgentPart.t()
            | OpencodeClient.Generated.CompactionPart.t()
            | OpencodeClient.Generated.FilePart.t()
            | OpencodeClient.Generated.PatchPart.t()
            | OpencodeClient.Generated.ReasoningPart.t()
            | OpencodeClient.Generated.RetryPart.t()
            | OpencodeClient.Generated.SnapshotPart.t()
            | OpencodeClient.Generated.StepFinishPart.t()
            | OpencodeClient.Generated.StepStartPart.t()
            | OpencodeClient.Generated.SubtaskPart.t()
            | OpencodeClient.Generated.TextPart.t()
            | OpencodeClient.Generated.ToolPart.t(),
          sessionID: String.t(),
          time: integer
        }

  defstruct [:part, :sessionID, :time]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      part:
        {:union,
         [
           {OpencodeClient.Generated.AgentPart, :t},
           {OpencodeClient.Generated.CompactionPart, :t},
           {OpencodeClient.Generated.FilePart, :t},
           {OpencodeClient.Generated.PatchPart, :t},
           {OpencodeClient.Generated.ReasoningPart, :t},
           {OpencodeClient.Generated.RetryPart, :t},
           {OpencodeClient.Generated.SnapshotPart, :t},
           {OpencodeClient.Generated.StepFinishPart, :t},
           {OpencodeClient.Generated.StepStartPart, :t},
           {OpencodeClient.Generated.SubtaskPart, :t},
           {OpencodeClient.Generated.TextPart, :t},
           {OpencodeClient.Generated.ToolPart, :t}
         ]},
      sessionID: :string,
      time: :integer
    ]
  end
end
