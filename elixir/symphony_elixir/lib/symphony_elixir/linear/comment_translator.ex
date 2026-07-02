defmodule SymphonyElixir.Linear.CommentTranslator do
  @moduledoc false

  alias SymphonyElixir.Config

  @spec translate_for_linear(String.t()) :: String.t()
  def translate_for_linear(body) when is_binary(body) do
    case Config.linear_output_language() do
      "ja" -> translate_to_japanese(body)
      "jp" -> translate_to_japanese(body)
      "japanese" -> translate_to_japanese(body)
      _ -> body
    end
  end

  defp translate_to_japanese(body) do
    body
    |> replace_heading("## OpenCode Workpad", "## OpenCode ワークパッド")
    |> replace_heading("### Plan", "### 計画")
    |> replace_heading("### Acceptance Criteria", "### 受け入れ基準")
    |> replace_heading("### Validation", "### 検証")
    |> replace_heading("### Notes", "### メモ")
    |> replace_heading("### Confusions", "### 混乱・疑問")
    |> String.replace("Parent task", "親タスク")
    |> String.replace("Child task", "子タスク")
    |> String.replace("Criterion ", "基準 ")
    |> String.replace("targeted tests:", "対象テスト:")
    |> String.replace("<short progress note with timestamp>", "<短い進捗メモ（タイムスタンプ付き）>")
    |> String.replace(
      "<only include when something was confusing during execution>",
      "<実行中に混乱や疑問があった場合のみ記載>"
    )
  end

  defp replace_heading(body, from, to) do
    String.replace(body, from, to)
  end
end
