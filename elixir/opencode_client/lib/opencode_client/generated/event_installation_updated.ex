defmodule OpencodeClient.Generated.EventInstallationUpdated do
  @moduledoc """
  Provides struct and type for a EventInstallationUpdated
  """

  @type t :: %__MODULE__{
          id: String.t(),
          properties: OpencodeClient.Generated.EventInstallationUpdatedProperties.t(),
          type: String.t()
        }

  defstruct [:id, :properties, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      id: :string,
      properties: {OpencodeClient.Generated.EventInstallationUpdatedProperties, :t},
      type: {:const, "installation.updated"}
    ]
  end
end
