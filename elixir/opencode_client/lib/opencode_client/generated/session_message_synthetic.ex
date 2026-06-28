defmodule OpencodeClient.Generated.SessionMessageSynthetic do
  @moduledoc """
  Provides struct and type for a SessionMessageSynthetic
  """

  @type t :: %__MODULE__{
          id: String.t(),
          metadata: map | nil,
          sessionID: String.t(),
          text: String.t(),
          time: OpencodeClient.Generated.SessionMessageSyntheticTime.t(),
          type: String.t()
        }

  defstruct [:id, :metadata, :sessionID, :text, :time, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      metadata: :map,
      sessionID: :string,
      text: :string,
      time: {OpencodeClient.Generated.SessionMessageSyntheticTime, :t},
      type: {:const, "synthetic"}
    ]
  end
end
