defmodule OpencodeClient.Generated.EventSessionNextCompactionDelta do
  @moduledoc """
  Provides struct and type for a EventSessionNextCompactionDelta
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.EventSessionNextCompactionDeltaProperties.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.EventSessionNextCompactionDeltaProperties, :t},
      type: {:const, "session.next.compaction.delta"}
    ]
  end
end
