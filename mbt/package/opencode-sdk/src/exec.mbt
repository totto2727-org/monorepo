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
  on_line : async (@agent_cli.JsonLine) -> Bool,
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
  let result = @agent_cli.run(
    @agent_cli.Invocation::new(
      command=self.executable_path.to_string(),
      arguments=command_args,
      environment~,
      inherit_environment~,
      input=args.input,
    ),
    on_line,
  ) catch {
    @agent_cli.AgentCliError::InvalidJson(line~, cause~) =>
      raise InvalidEvent(
        message="Failed to parse OpenCode event: \{line}; cause: \{cause}",
      )
    error => raise error
  }
  match result {
    @agent_cli.RunResult::Completed | @agent_cli.RunResult::Stopped => ()
    @agent_cli.RunResult::Failed(code~, stderr~) =>
      raise ExecFailed(code~, stderr~)
  }
}
