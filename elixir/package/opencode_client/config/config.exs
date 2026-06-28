import Config

if config_env() == :dev do
  config :oapi_generator,
    default: [
      output: [
        base_module: OpencodeClient.Generated,
        default_client: OpencodeClient.Client,
        location: "lib/opencode_client/generated"
      ]
    ]
end
