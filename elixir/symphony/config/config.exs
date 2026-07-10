import Config

config :phoenix, :json_library, Jason

config :symphony, SymphonyWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: SymphonyWeb.ErrorHTML, json: SymphonyWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Symphony.PubSub,
  live_view: [signing_salt: "symphony-live-view"],
  secret_key_base: String.duplicate("s", 64),
  check_origin: false,
  server: false

if config_env() == :test do
  config :symphony,
    workflow_file_path: Path.expand("../../../WORKFLOW.md", __DIR__)
end
