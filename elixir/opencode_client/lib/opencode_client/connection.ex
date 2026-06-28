# このファイルは元のApache 2.0ライセンスのコードから新規に追加されています
# 変更日: 2026-06-28
# 変更者: totto2727
# 変更内容: OpenCode server 起動と generated client 用オプション構築を集約

defmodule OpencodeClient.Connection do
  @moduledoc """
  Starts or connects to an OpenCode server and builds generated-client options.

  Callers that already have an OpenCode server can pass `:base_url`.  Otherwise
  this module owns starting `opencode serve` through `OpencodeClient.Server` and
  returns the request options needed by generated operation modules.
  """

  alias OpencodeClient.Server

  @type t :: %{
          client: keyword(),
          server: GenServer.server() | nil,
          server_module: module()
        }

  @spec start(keyword()) :: {:ok, t()} | {:error, term()}
  def start(opts \\ []) do
    base_url = explicit_base_url(opts)

    cond do
      is_binary(base_url) ->
        {:ok, build_connection(opts, base_url, nil, Keyword.get(opts, :server_module, Server))}

      Keyword.get(opts, :allow_server_start, true) ->
        start_local_server(opts)

      true ->
        {:error, :opencode_base_url_required}
    end
  end

  @spec stop(t()) :: :ok
  def stop(%{server: nil}), do: :ok

  def stop(%{server: server, server_module: server_module}) do
    server_module.stop(server)
    :ok
  catch
    _, _ -> :ok
  end

  @spec metadata(t()) :: map()
  def metadata(%{client: client, server: server}) do
    %{
      opencode_base_url: Keyword.get(client, :base_url)
    }
    |> maybe_put(:opencode_server_pid, server_pid(server))
  end

  defp start_local_server(opts) do
    server_module = Keyword.get(opts, :server_module, Server)

    case server_module.start(server_opts(opts)) do
      {:ok, server} ->
        case server_module.url(server) do
          base_url when is_binary(base_url) ->
            {:ok, build_connection(opts, base_url, server, server_module)}

          {:error, reason} ->
            stop(%{server: server, server_module: server_module})
            {:error, {:opencode_server_url_failed, reason}}

          other ->
            stop(%{server: server, server_module: server_module})
            {:error, {:opencode_server_url_failed, other}}
        end

      {:error, reason} ->
        {:error, {:opencode_server_start_failed, reason}}
    end
  end

  defp build_connection(opts, base_url, server, server_module) do
    %{
      client: build_client(opts, base_url),
      server: server,
      server_module: server_module
    }
  end

  defp build_client(opts, base_url) do
    client_opts = Keyword.get(opts, :client_opts, [])
    auth = Keyword.get(opts, :auth, Keyword.get(client_opts, :auth, env_auth()))

    client_opts
    |> Keyword.put(:base_url, base_url)
    |> Keyword.put(:auth, auth)
  end

  defp explicit_base_url(opts) do
    opts
    |> Keyword.get(:base_url, System.get_env("OPENCODE_BASE_URL"))
    |> case do
      url when is_binary(url) ->
        url = String.trim(url)
        if url == "", do: nil, else: url

      _ ->
        nil
    end
  end

  defp env_auth do
    case {System.get_env("OPENCODE_AUTH_USER"), System.get_env("OPENCODE_AUTH_PASS")} do
      {user, pass} when is_binary(user) and is_binary(pass) -> {:basic, user, pass}
      _ -> nil
    end
  end

  defp server_opts(opts) do
    opts
    |> Keyword.get(:server_opts, [])
    |> Keyword.put_new(:config, Keyword.get(opts, :server_config, %{}))
  end

  defp server_pid(nil), do: nil
  defp server_pid(server) when is_pid(server), do: inspect(server)
  defp server_pid(_server), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
