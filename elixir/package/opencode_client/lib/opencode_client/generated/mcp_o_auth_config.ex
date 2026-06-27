defmodule OpencodeClient.Generated.McpOAuthConfig do
  @moduledoc """
  Provides struct and type for a McpOAuthConfig
  """

  @type t :: %__MODULE__{
          callbackPort: integer | nil,
          clientId: String.t() | nil,
          clientSecret: String.t() | nil,
          redirectUri: String.t() | nil,
          scope: String.t() | nil
        }

  defstruct [:callbackPort, :clientId, :clientSecret, :redirectUri, :scope]

  @doc false
  @spec __fields__(atom) :: keyword
  def __fields__(type \\ :t)

  def __fields__(:t) do
    [
      callbackPort: :integer,
      clientId: :string,
      clientSecret: :string,
      redirectUri: :string,
      scope: :string
    ]
  end
end
