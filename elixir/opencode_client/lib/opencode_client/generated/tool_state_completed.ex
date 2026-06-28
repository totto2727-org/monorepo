defmodule OpencodeClient.Generated.ToolStateCompleted do
  @moduledoc """
  Provides struct and type for a ToolStateCompleted
  """

  @type t :: %__MODULE__{
          attachments: [OpencodeClient.Generated.FilePart.t()] | nil,
          input: map,
          metadata: map,
          output: String.t(),
          status: String.t(),
          time: OpencodeClient.Generated.ToolStateCompletedTime.t(),
          title: String.t()
        }

  defstruct [:attachments, :input, :metadata, :output, :status, :time, :title]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      attachments: [{OpencodeClient.Generated.FilePart, :t}],
      input: :map,
      metadata: :map,
      output: :string,
      status: {:const, "completed"},
      time: {OpencodeClient.Generated.ToolStateCompletedTime, :t},
      title: :string
    ]
  end
end
