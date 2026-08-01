///|
let server_log_level_lens : @lens.Lens[String?] = @lens.root()
  .string("logLevel")
  .optional()

///|
priv struct ServerConfig {
  log_level : String?
}

///|
impl FromJson for ServerConfig with fn from_json(json, _path) {
  let log_level = server_log_level_lens.get(json) catch { _ => None }
  { log_level, }
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
  let config : ServerConfig = @json.from_json(options.config) catch {
    _ => { log_level: None }
  }
  match config.log_level {
    Some(log_level) => args.push("--log-level=\{log_level}")
    None => ()
  }
  args
}
