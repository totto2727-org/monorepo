import Config

if config_env() == :dev do
  config :oapi_generator,
    default: [
      output: [
        base_module: OpencodeClient.Generated,
        location: "lib/opencode_client/generated"
      ]
    ]
end
