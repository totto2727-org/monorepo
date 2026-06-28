defmodule OpencodeClient.Generated.ReasoningPart do
  @moduledoc """
  Provides struct and type for a ReasoningPart
  """

  @type t :: %__MODULE__{
          id: String.t(),
          messageID: String.t(),
          metadata: map | nil,
          sessionID: String.t(),
          text: String.t(),
          time: OpencodeClient.Generated.ReasoningPartTime.t(),
          type: String.t()
        }

  defstruct [:id, :messageID, :metadata, :sessionID, :text, :time, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      messageID: :string,
      metadata: :map,
      sessionID: :string,
      text: :string,
      time: {OpencodeClient.Generated.ReasoningPartTime, :t},
      type: {:const, "reasoning"}
    ]
  end
end
