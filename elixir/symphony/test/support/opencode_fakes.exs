# このファイルは元のApache 2.0ライセンスのコードから新規に追加されています
# 変更日: 2026-06-28
# 変更者: totto2727
# 変更内容: OpenCode バックエンドテスト用の fake session/event/server を追加

defmodule Symphony.OpencodeFakes.SessionApi do
  @moduledoc false

  @spec session_create(map(), keyword()) :: {:ok, map()}
  def session_create(body, opts) do
    notify(opts, {:opencode_session_create, body, opts})
    {:ok, %{"id" => Keyword.get(opts, :session_id, "ses_test")}}
  end

  @spec session_prompt_async(String.t(), map(), keyword()) :: :ok
  def session_prompt_async(session_id, body, opts) do
    maybe_verify_git_toplevel(opts)
    notify(opts, {:opencode_prompt_async, session_id, body, opts})
    :ok
  end

  @spec session_delete(String.t(), keyword()) :: {:ok, boolean()}
  def session_delete(session_id, opts) do
    notify(opts, {:opencode_session_delete, session_id, opts})
    {:ok, true}
  end

  defp maybe_verify_git_toplevel(opts) do
    if Keyword.get(opts, :assert_git_toplevel, false) do
      directory = Keyword.fetch!(opts, :directory)
      {top_level, 0} = System.cmd("git", ["-C", directory, "rev-parse", "--show-toplevel"])
      notify(opts, {:opencode_git_toplevel, String.trim(top_level), directory})
    end
  end

  defp notify(opts, message) do
    case Keyword.get(opts, :test_pid) do
      pid when is_pid(pid) -> send(pid, message)
      _ -> :ok
    end
  end
end

defmodule Symphony.OpencodeFakes.EventStream do
  @moduledoc false

  @spec stream(keyword()) :: {:ok, Enumerable.t()}
  def stream(client) do
    session_id = Keyword.get(client, :session_id, "ses_test")
    {:ok, Keyword.get(client, :events, [idle_event(session_id)])}
  end

  @spec idle_event(String.t()) :: map()
  def idle_event(session_id) do
    %{type: "session.idle", data: %{"properties" => %{"sessionID" => session_id}}}
  end
end

defmodule Symphony.OpencodeFakes.Server do
  @moduledoc false

  @spec start(keyword()) :: {:ok, map()} | {:error, term()}
  def start(opts) do
    case Keyword.get(opts, :start_error) do
      nil ->
        server = %{
          test_pid: Keyword.get(opts, :test_pid),
          url: Keyword.get(opts, :url, "http://127.0.0.1:4096")
        }

        notify(server, {:opencode_server_start, opts})
        {:ok, server}

      error ->
        {:error, error}
    end
  end

  @spec url(map()) :: String.t() | {:error, term()}
  def url(%{url: url}), do: url

  @spec stop(map()) :: :ok
  def stop(server) do
    notify(server, {:opencode_server_stop, server})
    :ok
  end

  defp notify(%{test_pid: pid}, message) when is_pid(pid), do: send(pid, message)
  defp notify(_server, _message), do: :ok
end
