defmodule MonorepoElixir.MixProject do
  use Mix.Project

  def project do
    [
      name: "Monorepo Elixir",
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp deps do
    [
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      test: ["test"],
      lint: ["credo --strict"]
    ]
  end
end
