defmodule OpencodeClient.Generated.ProviderV2Info do
  @moduledoc """
  Provides struct and type for a ProviderV2Info
  """

  @type t :: %__MODULE__{
          enabled: false | OpencodeClient.Generated.ProviderV2InfoEnabled.t(),
          endpoint: OpencodeClient.Generated.ProviderV2InfoEndpoint.t(),
          env: [String.t()],
          id: String.t(),
          name: String.t(),
          options: OpencodeClient.Generated.ProviderV2InfoOptions.t()
        }

  defstruct [:enabled, :endpoint, :env, :id, :name, :options]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      enabled: {:union, [{OpencodeClient.Generated.ProviderV2InfoEnabled, :t}, const: false]},
      endpoint: {OpencodeClient.Generated.ProviderV2InfoEndpoint, :t},
      env: [:string],
      id: :string,
      name: :string,
      options: {OpencodeClient.Generated.ProviderV2InfoOptions, :t}
    ]
  end
end
