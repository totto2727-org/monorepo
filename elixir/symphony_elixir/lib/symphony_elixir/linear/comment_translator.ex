defmodule SymphonyElixir.Linear.CommentTranslator do
  @moduledoc false

  require Logger

  alias SymphonyElixir.Config
  alias SymphonyElixir.Opencode.AppServer

  @default_retry_attempts 3
  @translation_workspace_name ".linear-comment-translation"

  @type agent_fun :: (String.t(), String.t(), keyword() -> {:ok, String.t()} | {:error, term()})

  @spec translate_for_linear(String.t()) :: String.t()
  def translate_for_linear(body) when is_binary(body), do: translate_for_linear(body, [])

  @spec translate_for_linear(String.t(), keyword()) :: String.t()
  def translate_for_linear(body, opts) when is_binary(body) and is_list(opts) do
    case Config.linear_output_language() do
      language when is_binary(language) and language != "" ->
        translate_with_retries(body, language, opts)

      _ ->
        body
    end
  end

  @spec run_translation_agent(String.t(), String.t(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def run_translation_agent(body, language, opts) when is_binary(body) and is_binary(language) do
    workspace = Keyword.get_lazy(opts, :translation_workspace, &default_translation_workspace/0)
    agent_opts = Keyword.get(opts, :translation_agent_opts, [])
    system = translation_system_prompt(language)
    ref = make_ref()
    parent = self()

    on_message = fn message ->
      send(parent, {:linear_comment_translation_agent_message, ref, message})
      :ok
    end

    issue = %{id: "linear-comment-translation", identifier: "LINEAR-COMMENT-TRANSLATION"}

    with :ok <- File.mkdir_p(workspace),
         {:ok, _result} <-
           AppServer.run(
             workspace,
             body,
             issue,
             agent_opts
             |> Keyword.put(:on_message, on_message)
             |> Keyword.put(:system, system)
           ) do
      case collect_agent_output(ref) do
        translated when is_binary(translated) and translated != "" -> {:ok, translated}
        _ -> {:error, :empty_translation}
      end
    end
  end

  defp translate_with_retries(body, language, opts) do
    agent_fun = Keyword.get(opts, :translation_agent_fun, &run_translation_agent/3)
    attempts = Keyword.get(opts, :translation_retry_attempts, @default_retry_attempts)

    case do_translate_with_retries(body, language, opts, agent_fun, max(attempts, 1)) do
      {:ok, translated} ->
        translated

      {:error, reason} ->
        Logger.warning(
          "Linear comment translation failed after #{max(attempts, 1)} attempt(s); posting original body: #{inspect(reason)}"
        )

        body
    end
  end

  defp do_translate_with_retries(_body, _language, _opts, _agent_fun, 0),
    do: {:error, :retry_exhausted}

  defp do_translate_with_retries(body, language, opts, agent_fun, attempts_left) do
    case agent_fun.(body, language, opts) do
      {:ok, translated} when is_binary(translated) ->
        {:ok, translated}

      {:ok, other} ->
        retry_or_error(
          body,
          language,
          opts,
          agent_fun,
          attempts_left,
          {:invalid_translation, other}
        )

      {:error, reason} ->
        retry_or_error(body, language, opts, agent_fun, attempts_left, reason)
    end
  catch
    kind, reason ->
      retry_or_error(body, language, opts, agent_fun, attempts_left, {kind, reason})
  end

  defp retry_or_error(_body, _language, _opts, _agent_fun, 1, reason), do: {:error, reason}

  defp retry_or_error(body, language, opts, agent_fun, attempts_left, _reason) do
    do_translate_with_retries(body, language, opts, agent_fun, attempts_left - 1)
  end

  defp translation_system_prompt(language) do
    """
    You are a translation-only agent.

    Target language: #{language}

    Translate the user's input into the target language.
    Preserve Markdown structure, code fences, URLs, identifiers, checkboxes, and commands.
    If the text is already appropriate for the target language and no wording needs to change, output it unchanged.
    Output only the final comment body. Do not explain, summarize, quote, wrap, or add any other text.
    """
  end

  defp default_translation_workspace do
    Config.settings!().workspace.root
    |> Path.expand()
    |> Path.join(@translation_workspace_name)
  end

  defp collect_agent_output(ref, acc \\ []) do
    receive do
      {:linear_comment_translation_agent_message, ^ref, message} ->
        collect_agent_output(ref, collect_message_text(message, acc))
    after
      0 ->
        acc
        |> Enum.reverse()
        |> Enum.join("")
        |> String.trim()
    end
  end

  defp collect_message_text(%{event: :notification, type: type, payload: payload}, acc)
       when is_binary(type) do
    if String.contains?(type, "message") do
      case text_from_payload(payload) do
        text when is_binary(text) -> [text | acc]
        _ -> acc
      end
    else
      acc
    end
  end

  defp collect_message_text(_message, acc), do: acc

  defp text_from_payload(payload) do
    find_text(payload, [
      :delta,
      "delta",
      :text,
      "text",
      :content,
      "content",
      :message,
      "message",
      :output,
      "output",
      :result,
      "result"
    ])
  end

  defp find_text(nil, _keys), do: nil

  defp find_text(value, _keys) when is_binary(value), do: value

  defp find_text(value, keys) when is_list(value),
    do: Enum.find_value(value, &find_text(&1, keys))

  defp find_text(value, keys) when is_map(value) do
    Enum.find_value(keys, fn key ->
      case Map.get(value, key) do
        text when is_binary(text) -> text
        _ -> nil
      end
    end) ||
      value
      |> Map.values()
      |> Enum.find_value(&find_text(&1, keys))
  end

  defp find_text(_value, _keys), do: nil
end
