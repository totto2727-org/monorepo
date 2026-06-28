defmodule OpencodeClient.Generated.ModelV2Info do
  @moduledoc """
  Provides struct and type for a ModelV2Info
  """

  @type t :: %__MODULE__{
          apiID: String.t(),
          capabilities: OpencodeClient.Generated.ModelV2InfoCapabilities.t(),
          cost: [OpencodeClient.Generated.ModelV2InfoCost.t()],
          enabled: boolean,
          endpoint: OpencodeClient.Generated.ModelV2InfoEndpoint.t(),
          family: String.t() | nil,
          id: String.t(),
          limit: OpencodeClient.Generated.ModelV2InfoLimit.t(),
          name: String.t(),
          options: OpencodeClient.Generated.ModelV2InfoOptions.t(),
          providerID: String.t(),
          status: String.t(),
          time: OpencodeClient.Generated.ModelV2InfoTime.t(),
          variants: [OpencodeClient.Generated.ModelV2InfoVariants.t()]
        }

  defstruct [
    :apiID,
    :capabilities,
    :cost,
    :enabled,
    :endpoint,
    :family,
    :id,
    :limit,
    :name,
    :options,
    :providerID,
    :status,
    :time,
    :variants
  ]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      apiID: :string,
      capabilities: {OpencodeClient.Generated.ModelV2InfoCapabilities, :t},
      cost: [{OpencodeClient.Generated.ModelV2InfoCost, :t}],
      enabled: :boolean,
      endpoint: {OpencodeClient.Generated.ModelV2InfoEndpoint, :t},
      family: :string,
      id: :string,
      limit: {OpencodeClient.Generated.ModelV2InfoLimit, :t},
      name: :string,
      options: {OpencodeClient.Generated.ModelV2InfoOptions, :t},
      providerID: :string,
      status: {:enum, ["alpha", "beta", "deprecated", "active"]},
      time: {OpencodeClient.Generated.ModelV2InfoTime, :t},
      variants: [{OpencodeClient.Generated.ModelV2InfoVariants, :t}]
    ]
  end
end
