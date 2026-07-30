// OpenCode CLI argument and JSONL contracts:
// https://dev.opencode.ai/docs/cli/
// https://github.com/anomalyco/opencode/blob/1e17856ba4b5b052650c8115060852f3f023844e/packages/opencode/src/cli/cmd/run.ts#L416-L428

///|
priv struct OpenCodeExecArgs {
  input : String
  session_id : String?
  files : Array[@path.Path]
  model : String?
  agent : String?
  working_directory : @path.Path?
  variant : String?
  title : String?
  thinking : Bool
}

///|
/// Process adapter for `opencode run --format json`.
struct OpenCodeExec {
  executable_path : @path.Path
  env_override : Map[String, String]?
  config : OpenCodeConfigObject?
}

///|
/// Construct the process adapter used by an OpenCode client.
fn OpenCodeExec::OpenCodeExec(
  executable_path : @path.Path?,
  env : Map[String, String]?,
  config : OpenCodeConfigObject?,
) -> OpenCodeExec {
  {
    executable_path: executable_path.unwrap_or(@path.Path("opencode")),
    env_override: env,
    config,
  }
}

///|
/// Execute the OpenCode CLI and deliver each JSONL line to `on_line`.
async fn OpenCodeExec::run(
  self : OpenCodeExec,
  args : OpenCodeExecArgs,
  on_line : async (String) -> Bool,
) -> Unit {
  let command_args = ["run", "--format", "json"]
  if args.session_id is Some(session_id) {
    command_args.push("--session")
    command_args.push(session_id)
  }
  if args.model is Some(model) {
    command_args.push("--model")
    command_args.push(model)
  }
  if args.agent is Some(agent) {
    command_args.push("--agent")
    command_args.push(agent)
  }
  if args.working_directory is Some(directory) {
    command_args.push("--dir")
    command_args.push(directory.to_string())
  }
  if args.variant is Some(variant) {
    command_args.push("--variant")
    command_args.push(variant)
  }
  if args.title is Some(title) {
    command_args.push("--title")
    command_args.push(title)
  }
  if args.thinking {
    command_args.push("--thinking")
  }
  for file in args.files {
    command_args.push("--file")
    command_args.push(file.to_string())
  }

  let environment = match self.env_override {
    Some(environment_override) => environment_override.copy()
    None => Map([])
  }
  if self.config is Some(config) {
    environment["OPENCODE_CONFIG_CONTENT"] = config_object_to_json(config).stringify()
  }
  let inherit_environment = self.env_override is None
  let stop_requested = Ref(false)
  @async.with_task_group(async fn(group) {
    let (child_input, input_writer) = @process.write_to_process()
    let (output_reader, child_output) = @process.read_from_process()
    let (error_reader, child_error) = @process.read_from_process()
    group.spawn_bg(async fn() {
      defer input_writer.close()
      input_writer.write(args.input)
    })
    let stderr_task = group.spawn(async fn() {
      defer error_reader.close()
      error_reader.read_all().text()
    })
    let child = @process.spawn(
      group,
      self.executable_path.to_string(),
      command_args,
      extra_env=environment,
      inherit_env=inherit_environment,
      stdin=child_input,
      stdout=child_output,
      stderr=child_error,
      cancel_handler=@process.hard_cancel(),
    )
    let stdout_task = group.spawn(async fn() {
      defer output_reader.close()
      while output_reader.read_until("\n") is Some(line) {
        if !on_line(line) {
          stop_requested.val = true
          child.cancel()
          break
        }
      }
    })
    let code = child.wait()
    if code != 0 && !stop_requested.val {
      stdout_task.cancel()
      stdout_task.wait() catch {
        error => if !@async.is_cancellation_error(error) { raise error }
      }
    } else {
      stdout_task.wait()
    }
    let stderr = if stop_requested.val {
      stderr_task.cancel()
      try stderr_task.wait() |> ignore catch {
        error => if !@async.is_cancellation_error(error) { raise error }
      }
      ""
    } else {
      stderr_task.wait()
    }
    if code != 0 && !stop_requested.val {
      raise ExecFailed(code~, stderr~)
    }
  })
}
