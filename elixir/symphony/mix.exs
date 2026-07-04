# このファイルは元のApache 2.0ライセンスのコードから変更されています
# 変更日: 2026-06-28
# 変更者: totto2727
# 変更内容: monorepo umbrella 構成向けの deps/lockfile 設定、OpenCode 連携依存追加、旧バックエンド関連処理削除

defmodule Symphony.MixProject do
  use Mix.Project

  def project do
    [
      app: :symphony,
      version: "0.1.0",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [
        summary: [
          threshold: 100
        ],
        ignore_modules: [
          Symphony.Config,
          Symphony.Linear.Client,
          Symphony.SpecsCheck,
          Symphony.Orchestrator,
          Symphony.Orchestrator.State,
          Symphony.AgentRunner,
          Symphony.CLI,
          Symphony.Opencode.AppServer,
          Symphony.Opencode.AgentRunner,
          Symphony.HttpServer,
          Symphony.StatusDashboard,
          Symphony.LogFile,
          Symphony.Opencode.ConnectionManager,
          Symphony.Workspace,
          SymphonyWeb.DashboardLive,
          SymphonyWeb.Endpoint,
          SymphonyWeb.ErrorHTML,
          SymphonyWeb.ErrorJSON,
          SymphonyWeb.Layouts,
          SymphonyWeb.ObservabilityApiController,
          SymphonyWeb.Presenter,
          SymphonyWeb.StaticAssetController,
          SymphonyWeb.StaticAssets,
          SymphonyWeb.Router,
          SymphonyWeb.Router.Helpers
        ]
      ],
      test_ignore_filters: [
        "test/support/snapshot_support.exs",
        "test/support/test_support.exs"
      ],
      dialyzer: [
        plt_local_path: "../../_build/#{Mix.env()}",
        plt_add_apps: [:mix]
      ],
      escript: escript(),
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Symphony.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.8"},
      {:floki, ">= 0.30.0", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix, "~> 1.8.0"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_view, "~> 1.1.0"},
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:yaml_elixir, "~> 2.12"},
      {:solid, "~> 1.2"},
      {:ecto, "~> 3.13"},
      {:opencode_client, in_umbrella: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      build: ["escript.build"],
      lint: ["specs.check", "credo --strict"]
    ]
  end

  defp escript do
    [
      app: nil,
      main_module: Symphony.CLI,
      name: "symphony",
      path: "bin/symphony"
    ]
  end
end
