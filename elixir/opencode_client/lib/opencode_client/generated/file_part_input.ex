defmodule OpencodeClient.Generated.FilePartInput do
  @moduledoc """
  Provides struct and type for a FilePartInput
  """

  @type t :: %__MODULE__{
          filename: String.t() | nil,
          id: String.t() | nil,
          mime: String.t(),
          source:
            OpencodeClient.Generated.FileSource.t()
            | OpencodeClient.Generated.ResourceSource.t()
            | OpencodeClient.Generated.SymbolSource.t()
            | nil,
          type: String.t(),
          url: String.t()
        }

  defstruct [:filename, :id, :mime, :source, :type, :url]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      filename: :string,
      id: :string,
      mime: :string,
      source:
        {:union,
         [
           {OpencodeClient.Generated.FileSource, :t},
           {OpencodeClient.Generated.ResourceSource, :t},
           {OpencodeClient.Generated.SymbolSource, :t}
         ]},
      type: {:const, "file"},
      url: :string
    ]
  end
end
