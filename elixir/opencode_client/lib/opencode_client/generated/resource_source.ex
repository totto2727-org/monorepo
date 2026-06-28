defmodule OpencodeClient.Generated.ResourceSource do
  @moduledoc """
  Provides struct and type for a ResourceSource
  """

  @type t :: %__MODULE__{
          clientName: String.t(),
          text: OpencodeClient.Generated.FilePartSourceText.t(),
          type: String.t(),
          uri: String.t()
        }

  defstruct [:clientName, :text, :type, :uri]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      clientName: :string,
      text: {OpencodeClient.Generated.FilePartSourceText, :t},
      type: {:const, "resource"},
      uri: :string
    ]
  end
end
