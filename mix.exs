defmodule Monorepo.MixProject do
  use Mix.Project

  def project do
    [
      name: "Monorepo",
      apps_path: "elixir",
      apps: [:opencode_client, :symphony],
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp deps do
    []
  end
end
