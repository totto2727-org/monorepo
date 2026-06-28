defmodule OpencodeClient.Config do
  @moduledoc false

  @default_base_url "http://localhost:4096"

  @spec base_url() :: String.t()
  def base_url do
    Application.get_env(:opencode_client, :base_url, @default_base_url)
  end

  @spec auth() :: OpencodeClient.Auth.t()
  def auth do
    Application.get_env(:opencode_client, :auth)
  end
end
