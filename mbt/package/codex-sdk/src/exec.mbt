const INTERNAL_ORIGINATOR_ENV : String = "CODEX_INTERNAL_ORIGINATOR_OVERRIDE"

const MOONBIT_SDK_ORIGINATOR : String = "codex_sdk_mbt"

///| Executes the Codex CLI and streams its JSONL output.
struct CodexExec {
  executable_path : @path.Path
  env_override : Map[String, String]?
  config_overrides : CodexConfigObject?
}

///| Constructs the process adapter used by a Codex client.
fn CodexExec::CodexExec(options : CodexOptions) -> CodexExec {
  {
    executable_path: options.codex_path_override.unwrap_or(@path.Path("codex")),
    env_override: options.env,
    config_overrides: options.config,
  }
}

async fn CodexExec::run(
  self : CodexExec,
  args : CodexExecArgs,
  on_line : async (String) -> Unit,
) -> Unit raise {
  let command_args = build_command_args(args, self.config_overrides)
  let (environment, inherit_environment) = self.environment(args.api_key)
  @async.with_task_group(fn(group) {
    let (child_input, input_writer) = @process.write_to_process()
    let (output_reader, child_output) = @process.read_from_process()
    let (error_reader, child_error) = @process.read_from_process()
    group.spawn_bg(fn() {
      defer input_writer.close()
      input_writer.write(args.input)
    })
    let stderr_task = group.spawn(fn() {
      defer error_reader.close()
      error_reader.read_all().text()
    })
    let stdout_task = group.spawn(fn() {
      defer output_reader.close()
      while output_reader.read_until("\n") is Some(line) {
        on_line(line)
      }
    })
    let child = @process.spawn(
      group,
      "\{self.executable_path}",
      command_args,
      extra_env=environment,
      inherit_env=inherit_environment,
      stdin=child_input,
      stdout=child_output,
      stderr=child_error,
    )
    let code = child.wait()
    if code != 0 {
      stdout_task.cancel()
      try stdout_task.wait() catch {
        error =>
          if !@async.is_cancellation_error(error) {
            raise error
          }
      }
    } else {
      stdout_task.wait()
    }
    let stderr = stderr_task.wait()
    if code != 0 {
      raise ExecFailed(code=code, stderr=stderr)
    }
  })
}

fn CodexExec::environment(
  self : CodexExec,
  api_key : String?,
) -> (Map[String, String], Bool) {
  let environment = match self.env_override {
    Some(environment_override) => environment_override.copy()
    None => Map::new()
  }
  let inherited_originator = if self.env_override is None {
    @env.get_env_var(INTERNAL_ORIGINATOR_ENV)
  } else {
    None
  }
  if environment.get(INTERNAL_ORIGINATOR_ENV) is None &&
    inherited_originator is None {
    environment.set(INTERNAL_ORIGINATOR_ENV, MOONBIT_SDK_ORIGINATOR)
  }
  if api_key is Some(value) {
    environment.set("CODEX_API_KEY", value)
  }
  (environment, self.env_override is None)
}
