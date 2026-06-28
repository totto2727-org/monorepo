defmodule OpenCodeClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :opencode_client,
      version: "0.1.0",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:req_server_sent_events, "~> 0.2.1"},
      {:oapi_generator, "~> 0.4.0", only: :dev, runtime: false}
    ]
  end
end
