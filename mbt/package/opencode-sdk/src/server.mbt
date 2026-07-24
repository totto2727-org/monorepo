///|
// Copied from the OpenCode TypeScript SDK defaults and option shape:
// https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/server.ts#L5-L30
let server_listening_prefix = "opencode server listening"

///|
let startup_poll_interval_ms = 10

///|
/// Options for starting an OpenCode server.
///
/// Defaults match the official TypeScript SDK.
pub struct ServerOptions {
  hostname : String
  port : Int
  timeout_ms : Int
  config : Json
} derive(Debug)

///|
/// Construct server options using the official SDK defaults.
pub fn ServerOptions::ServerOptions(
  hostname? : String = "127.0.0.1",
  port? : Int = 4096,
  timeout_ms? : Int = 5000,
  config? : Json = Json::empty_object(),
) -> ServerOptions {
  // Copied from the OpenCode TypeScript SDK defaults:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/server.ts#L22-L30
  { hostname, port, timeout_ms, config }
}

///|
/// Failures that can occur while starting or stopping an OpenCode server.
pub(all) suberror ServerError {
  /// The server process or its log files could not be created.
  StartFailed(String)
  /// The server did not announce readiness before the configured timeout.
  StartTimeout(timeout_ms~ : Int, output~ : String)
  /// The server emitted the readiness prefix without a valid HTTP URL.
  MalformedOutput(line~ : String)
  /// The server exited before announcing readiness.
  ServerExited(code~ : Int, output~ : String)
  /// A started server could not be stopped or cleaned up.
  CleanupFailed(String)
} derive(Debug)

///|
/// A running OpenCode server owned by the task group passed at creation.
pub struct Server {
  url : String
  process : @process.Process
  log_dir : String
  mut closed : Bool
}

///|
/// Return the HTTP base URL announced by the OpenCode server.
pub fn Server::url(self : Server) -> String {
  self.url
}

///|
fn parse_server_url(output : String) -> String? raise ServerError {
  // Copied from the OpenCode TypeScript SDK readiness parser:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/server.ts#L49-L71
  for line_view in output.split("\n") {
    let line = line_view.trim().to_owned()
    if line.has_prefix(server_listening_prefix) {
      match line.find(" on ") {
        Some(index) => {
          let url = line[index + 4:].trim().to_owned()
          guard (url.has_prefix("http://") || url.has_prefix("https://")) &&
            url.find(" ") is None else {
            raise MalformedOutput(line~)
          }
          return Some(url)
        }
        None => raise MalformedOutput(line~)
      }
    }
  }
  None
}

///|
async fn read_log(path : String) -> String raise ServerError {
  @fs.read_file(path).text() catch {
    err =>
      raise StartFailed(
        "failed to read server output: \{@debug.to_string(err)}",
      )
  }
}

///|
async fn combined_output(
  stdout_path : String,
  stderr_path : String,
) -> String raise ServerError {
  let stdout = read_log(stdout_path)
  let stderr = read_log(stderr_path)
  match (stdout.trim(), stderr.trim()) {
    ("", "") => ""
    (_, "") => stdout
    ("", _) => stderr
    _ => stdout + "\n" + stderr
  }
}

///|
async fn remove_log_dir(log_dir : String) -> Unit raise ServerError {
  @fs.rmdir(log_dir, recursive=true) catch {
    err =>
      raise CleanupFailed(
        "failed to remove server logs: \{@debug.to_string(err)}",
      )
  }
}

///|
async fn stop_process(process : @process.Process) -> Unit raise ServerError {
  // Adapted from the OpenCode TypeScript SDK process-stop behavior:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/process.ts#L3-L12
  let process_result = process.try_wait() catch {
    err if @async.is_cancellation_error(err) => None
    err =>
      raise CleanupFailed(
        "failed to inspect server process: \{@debug.to_string(err)}",
      )
  }
  if process_result is None {
    process.cancel()
  }
  (process.wait() |> ignore) catch {
    err if @async.is_cancellation_error(err) => ()
    err =>
      raise CleanupFailed(
        "failed to wait for server process: \{@debug.to_string(err)}",
      )
  }
}

///|
async fn cleanup_start_failure(
  process : @process.Process,
  log_dir : String,
) -> Unit raise ServerError {
  stop_process(process)
  remove_log_dir(log_dir)
}

///|
async fn wait_for_server(
  process : @process.Process,
  stdout_path : String,
  stderr_path : String,
  timeout_ms : Int,
) -> String raise ServerError {
  // Adapted from the OpenCode TypeScript SDK timeout, output, and early-exit
  // handling:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/server.ts#L43-L91
  let mut elapsed_ms = 0
  for ;; {
    let stdout = read_log(stdout_path)
    match parse_server_url(stdout) {
      Some(url) => return url
      None => ()
    }
    match (process.try_wait() catch {
      err =>
        raise StartFailed(
          "failed to inspect server process: \{@debug.to_string(err)}",
        )
    }) {
      Some(code) => {
        let output = combined_output(stdout_path, stderr_path)
        raise ServerExited(code~, output~)
      }
      None => ()
    }
    if elapsed_ms >= timeout_ms {
      let output = combined_output(stdout_path, stderr_path)
      raise StartTimeout(timeout_ms~, output~)
    }
    @async.sleep(startup_poll_interval_ms) catch {
      err =>
        raise StartFailed(
          "startup wait was interrupted: \{@debug.to_string(err)}",
        )
    }
    elapsed_ms = elapsed_ms + startup_poll_interval_ms
  }
}

///|
async fn[X] create_opencode_server_with_command(
  group : @async.TaskGroup[X],
  options : ServerOptions,
  command : String,
  extra_env : Map[String, String],
) -> Server raise ServerError {
  let log_dir = @fs.tmpdir(prefix="opencode-sdk-") catch {
    err =>
      raise StartFailed(
        "failed to create server log directory: \{@debug.to_string(err)}",
      )
  }
  let stdout_path = "\{log_dir}/stdout.log"
  let stderr_path = "\{log_dir}/stderr.log"
  let stdout = @process.redirect_to_file(
    stdout_path,
    create_mode=CreateOrTruncate,
  ) catch {
    err => {
      remove_log_dir(log_dir)
      raise StartFailed(
        "failed to redirect server stdout: \{@debug.to_string(err)}",
      )
    }
  }
  let stderr = @process.redirect_to_file(
    stderr_path,
    create_mode=CreateOrTruncate,
  ) catch {
    err => {
      remove_log_dir(log_dir)
      raise StartFailed(
        "failed to redirect server stderr: \{@debug.to_string(err)}",
      )
    }
  }
  let env : Map[String, String] = Map([])
  for key, value in extra_env {
    env[key] = value
  }
  // Copied from the OpenCode TypeScript SDK process environment:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/server.ts#L35-L40
  env["OPENCODE_CONFIG_CONTENT"] = options.config.stringify()
  let process = @process.spawn(
    group,
    command,
    server_args(options),
    extra_env=env,
    stdout~,
    stderr~,
    cancel_handler=@process.hard_cancel(),
  ) catch {
    err => {
      remove_log_dir(log_dir)
      raise StartFailed(
        "failed to start OpenCode server: \{@debug.to_string(err)}",
      )
    }
  }
  let url = wait_for_server(
    process,
    stdout_path,
    stderr_path,
    options.timeout_ms,
  ) catch {
    err => {
      cleanup_start_failure(process, log_dir)
      raise err
    }
  }
  { url, process, log_dir, closed: false }
}

///|
/// Start an OpenCode server in `group`.
///
/// The task group must outlive the returned server. The process is started as
/// `opencode serve`, receives `OPENCODE_CONFIG_CONTENT`, and is hard-cancelled
/// when startup fails or `close` is called.
pub async fn[X] create_opencode_server(
  group : @async.TaskGroup[X],
  options? : ServerOptions = ServerOptions::ServerOptions(),
) -> Server raise ServerError {
  // Copied from the OpenCode TypeScript SDK executable selection:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/server.ts#L32-L40
  create_opencode_server_with_command(group, options, "opencode", Map([]))
}

///|
/// Return moonllm client configuration for this server.
///
/// The builder is bound to the announced server URL and uses no automatic
/// authentication. Callers may add timeout or header settings before `build`.
pub fn Server::moonllm_config(self : Server) -> @moonllm.ClientBuilder {
  // Adapted from the OpenCode TypeScript SDK's URL-bound client composition:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/index.ts#L8-L20
  @moonllm.ClientBuilder::new()
    .base_url(self.url)
    .auth(@moonllm.NoAuth)
}

///|
/// Stop the server, wait for its process, and remove its temporary logs.
///
/// Calling `close` again after a successful close has no effect.
pub async fn Server::close(self : Server) -> Unit raise ServerError {
  // Adapted from the OpenCode TypeScript SDK close and process-stop behavior:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/server.ts#L93-L99
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/process.ts#L3-L12
  guard !self.closed else { return }
  stop_process(self.process)
  remove_log_dir(self.log_dir)
  self.closed = true
}
