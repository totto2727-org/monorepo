///|
fn config_log_level(config : Json) -> String? {
  // Copied from the OpenCode TypeScript SDK log-level selection:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/server.ts#L32-L33
  match config {
    Json::Object(object) =>
      match object.get("logLevel") {
        Some(Json::String(value)) => Some(value)
        _ => None
      }
    _ => None
  }
}

///|
fn server_args(options : ServerOptions) -> Array[String] {
  // Copied from the OpenCode TypeScript SDK argument construction:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/server.ts#L32-L33
  let args = [
    "serve",
    "--hostname=\{options.hostname}",
    "--port=\{options.port}",
  ]
  match config_log_level(options.config) {
    Some(log_level) => args.push("--log-level=\{log_level}")
    None => ()
  }
  args
}
