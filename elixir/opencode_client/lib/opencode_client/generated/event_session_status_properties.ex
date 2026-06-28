defmodule OpencodeClient.Generated.EventSessionStatusProperties do
  @moduledoc """
  Provides struct and type for a EventSessionStatusProperties
  """

  @type t :: %__MODULE__{
          sessionID: String.t(),
          status: OpencodeClient.Generated.EventSessionStatusPropertiesStatus.t()
        }

  defstruct [:sessionID, :status]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      sessionID: :string,
      status: {OpencodeClient.Generated.EventSessionStatusPropertiesStatus, :t}
    ]
  end
end
