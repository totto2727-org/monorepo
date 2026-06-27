defmodule OpencodeClient.Generated.AccountV2Info do
  @moduledoc """
  Provides struct and type for a AccountV2Info
  """

  @type t :: %__MODULE__{
          credential:
            OpencodeClient.Generated.AccountV2ApiKeyCredential.t()
            | OpencodeClient.Generated.AccountV2oAuthCredential.t(),
          description: String.t(),
          id: String.t(),
          serviceID: String.t()
        }

  defstruct [:credential, :description, :id, :serviceID]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      credential:
        {:union,
         [
           {OpencodeClient.Generated.AccountV2ApiKeyCredential, :t},
           {OpencodeClient.Generated.AccountV2oAuthCredential, :t}
         ]},
      description: :string,
      id: :string,
      serviceID: :string
    ]
  end
end
