defmodule OpencodeClient.Generated.EventSessionNextReasoningStarted do
  @moduledoc """
  Provides struct and type for a EventSessionNextReasoningStarted
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.EventSessionNextReasoningStartedProperties.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.EventSessionNextReasoningStartedProperties, :t},
      type: {:const, "session.next.reasoning.started"}
    ]
  end
end
