defmodule OpencodeClient.Generated.OAuth do
  @moduledoc """
  Provides struct and type for a OAuth
  """

  @type t :: %__MODULE__{
          access: String.t(),
          accountId: String.t() | nil,
          enterpriseUrl: String.t() | nil,
          expires: integer,
          refresh: String.t(),
          type: String.t()
        }

  defstruct [:access, :accountId, :enterpriseUrl, :expires, :refresh, :type]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      access: :string,
      accountId: :string,
      enterpriseUrl: :string,
      expires: :integer,
      refresh: :string,
      type: {:const, "oauth"}
    ]
  end
end
