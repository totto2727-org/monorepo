// Direct port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts
// allow: SIZE_OK — this file intentionally preserves the upstream exec.ts responsibility boundary.

///| Mirrors CodexExecArgs from the upstream implementation.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L10-L41
///| MoonBit uses Path for filesystem values and task cancellation instead of an AbortSignal field.
priv struct CodexExecArgs {
  input : String
  base_url : String?
  api_key : String?
  thread_id : String?
  images : Array[@path.Path]
  model : String?
  sandbox_mode : SandboxMode?
  working_directory : @path.Path?
  additional_directories : Array[@path.Path]
  skip_git_repo_check : Bool?
  output_schema_file : @path.Path?
  model_reasoning_effort : ModelReasoningEffort?
  network_access_enabled : Bool?
  web_search_mode : WebSearchMode?
  web_search_enabled : Bool?
  approval_policy : ApprovalMode?
}

///| Mirrors the upstream internal originator variable.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L43-L45
const INTERNAL_ORIGINATOR_ENV : String = "CODEX_INTERNAL_ORIGINATOR_OVERRIDE"

// Type/language difference: the originator identifies this MoonBit port instead of the TypeScript SDK.
// Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L43-L45
const MOONBIT_SDK_ORIGINATOR : String = "codex_sdk_mbt"

///| Executes the Codex CLI and streams its JSONL output.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L63-L67
///| Runtime type difference: the upstream type stores `pathDirs` for directories bundled in the npm platform package; this MoonBit package has no npm optional-package resolver, so that property is intentionally absent.
///| Upstream path type and bundled-directory resolution: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L58-L65 and https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L412-L430
struct CodexExec {
  executable_path : @path.Path
  env_override : Map[String, String]?
  config_overrides : CodexConfigObject?
}

///| Constructs the process adapter used by a Codex client.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L69-L84
///| Runtime difference: MoonBit packages have no Node optional-package resolution context, so an omitted override resolves `codex` through PATH.
fn CodexExec::CodexExec(
  executable_path : @path.Path?,
  env : Map[String, String]?,
  config_overrides : CodexConfigObject?,
) -> CodexExec {
  {
    // Runtime default-resolution difference: the upstream implementation resolves its npm platform package and bundled executable, whereas MoonBit resolves `codex` through the process PATH when no override is supplied.
    // Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L69-L81 and https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L334-L410
    executable_path: executable_path.unwrap_or(@path.Path("codex")),
    env_override: env,
    config_overrides,
  }
}

///| Runs the CLI with the same argument ordering, environment behavior, and process lifecycle as the upstream generator.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L86-L243
///| Async type difference: MoonBit has no AsyncGenerator, so each output line is delivered to an async callback returning whether iteration should continue.
///| Cancellation type difference: cancelling the owning MoonBit task replaces the upstream AbortSignal.
async fn CodexExec::run(
  self : CodexExec,
  args : CodexExecArgs,
  on_line : async (String) -> Bool,
) -> Unit raise {
  let command_args = ["exec", "--experimental-json"]
  if self.config_overrides is Some(config) {
    for item in serialize_config_overrides(config) {
      command_args.push("--config")
      command_args.push(item)
    }
  }
  if args.base_url is Some(base_url) {
    command_args.push("--config")
    command_args.push(
      "openai_base_url=\{to_toml_value(ConfigString(base_url), "openai_base_url")}",
    )
  }
  if args.model is Some(model) {
    command_args.push("--model")
    command_args.push(model)
  }
  if args.sandbox_mode is Some(mode) {
    command_args.push("--sandbox")
    command_args.push(mode.to_string())
  }
  if args.working_directory is Some(directory) {
    command_args.push("--cd")
    command_args.push("\{directory}")
  }
  for directory in args.additional_directories {
    command_args.push("--add-dir")
    command_args.push("\{directory}")
  }
  if args.skip_git_repo_check == Some(true) {
    command_args.push("--skip-git-repo-check")
  }
  if args.output_schema_file is Some(schema_path) {
    command_args.push("--output-schema")
    command_args.push("\{schema_path}")
  }
  if args.model_reasoning_effort is Some(effort) {
    command_args.push("--config")
    command_args.push("model_reasoning_effort=\"\{effort.to_string()}\"")
  }
  if args.network_access_enabled is Some(enabled) {
    command_args.push("--config")
    command_args.push(
      "sandbox_workspace_write.network_access=\{if enabled { "true" } else { "false" }}",
    )
  }
  match (args.web_search_mode, args.web_search_enabled) {
    (Some(mode), _) => {
      command_args.push("--config")
      command_args.push("web_search=\"\{mode.to_string()}\"")
    }
    (None, Some(true)) => {
      command_args.push("--config")
      command_args.push("web_search=\"live\"")
    }
    (None, Some(false)) => {
      command_args.push("--config")
      command_args.push("web_search=\"disabled\"")
    }
    (None, None) => ()
  }
  if args.approval_policy is Some(policy) {
    command_args.push("--config")
    command_args.push("approval_policy=\"\{policy.to_string()}\"")
  }
  if args.thread_id is Some(thread_id) {
    command_args.push("resume")
    command_args.push(thread_id)
  }
  for image in args.images {
    command_args.push("--image")
    command_args.push("\{image}")
  }

  let environment = match self.env_override {
    Some(environment_override) => environment_override.copy()
    None => Map([])
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
  if args.api_key is Some(value) {
    environment.set("CODEX_API_KEY", value)
  }
  // Runtime PATH difference: the upstream implementation prepends its bundled `pathDirs` here; MoonBit performs no equivalent mutation because it neither resolves nor stores npm-bundled directories.
  // Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L177-L179
  let inherit_environment = self.env_override is None

  let moonbit_internal_stop_requested = Ref(false)
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
    let child = @process.spawn(
      group,
      "\{self.executable_path}",
      command_args,
      extra_env=environment,
      inherit_env=inherit_environment,
      stdin=child_input,
      stdout=child_output,
      stderr=child_error,
      // Runtime difference: MoonBit's default process cancellation waits up to five seconds before escalation, while the upstream generator cleanup terminates before returning control to the consumer.
      // Upstream generator cleanup: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L235-L242
      cancel_handler=@process.hard_cancel(),
    )
    let stdout_task = group.spawn(fn() {
      defer output_reader.close()
      while output_reader.read_until("\n") is Some(line) {
        if !on_line(line) {
          moonbit_internal_stop_requested.val = true
          // Async type difference: cancelling the process explicitly replaces AsyncGenerator cleanup when the upstream consumer stops iteration.
          // Upstream generator cleanup: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L235-L242
          child.cancel()
          break
        }
      }
    })
    let code = child.wait()
    // Runtime difference: MoonBit pipe reads are separate tasks. Cancel the reader after an early nonzero exit so a descendant holding stdout cannot block error delivery.
    // Upstream lifecycle: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L208-L243
    if code != 0 && !moonbit_internal_stop_requested.val {
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
    let stderr = if moonbit_internal_stop_requested.val {
      // Runtime difference: a descendant can retain the stderr pipe after the CLI process is terminated, so callback-requested generator cleanup also cancels the MoonBit reader task.
      // Upstream generator cleanup: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L235-L242
      stderr_task.cancel()
      try stderr_task.wait() |> ignore catch {
        error =>
          if !@async.is_cancellation_error(error) {
            raise error
          }
      }
      ""
    } else {
      stderr_task.wait()
    }
    if code != 0 && !moonbit_internal_stop_requested.val {
      raise ExecFailed(code=code, stderr=stderr)
    }
  })
}

///| Serializes global config overrides before per-thread arguments.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L246-L250
fn serialize_config_overrides(
  config : CodexConfigObject,
) -> Array[String] raise CodexSdkError {
  let overrides : Array[String] = []
  flatten_config_overrides(ConfigObject(config), "", overrides)
  overrides
}

///| Flattens nested config objects into dotted CLI override paths.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L252-L290
fn flatten_config_overrides(
  value : CodexConfigValue,
  prefix : String,
  overrides : Array[String],
) -> Unit raise CodexSdkError {
  match value {
    ConfigObject(object) => {
      if prefix == "" && object.is_empty() {
        return
      }
      if prefix != "" && object.is_empty() {
        overrides.push("\{prefix}={}")
        return
      }
      for key, child in object {
        guard key != "" else {
          raise InvalidConfig(
            path=prefix,
            message="Codex config override keys must be non-empty strings",
          )
        }
        let path = if prefix == "" { key } else { "\{prefix}.\{key}" }
        match child {
          ConfigObject(_) => flatten_config_overrides(child, path, overrides)
          _ => overrides.push("\{path}=\{to_toml_value(child, path)}")
        }
      }
    }
    _ =>
      if prefix == "" {
        raise InvalidConfig(
          path="",
          message="Codex config overrides must be a plain object",
        )
      } else {
        overrides.push("\{prefix}=\{to_toml_value(value, prefix)}")
      }
  }
}

///| Converts one config value to the TOML literal accepted by `--config`.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L292-L323
fn to_toml_value(
  value : CodexConfigValue,
  path : String,
) -> String raise CodexSdkError {
  match value {
    ConfigString(text) => Json::string(text).stringify()
    ConfigInt(number) => number.to_string()
    ConfigDouble(number) => {
      guard !number.is_nan() && !number.is_inf() else {
        raise InvalidConfig(
          path=path,
          message="Codex config override must be a finite number",
        )
      }
      number.to_string()
    }
    ConfigBool(value) => if value { "true" } else { "false" }
    ConfigArray(values) =>
      "[\{values.mapi((index, item) => to_toml_value(item, "\{path}[\{index}]")).join(", ")}]"
    ConfigObject(object) => {
      let parts : Array[String] = []
      for key, child in object {
        guard key != "" else {
          raise InvalidConfig(
            path=path,
            message="Codex config override keys must be non-empty strings",
          )
        }
        parts.push(
          "\{format_toml_key(key)} = \{to_toml_value(child, "\{path}.\{key}")}",
        )
      }
      "{\{parts.join(", ")}}"
    }
  }
}

///| Formats a TOML key exactly as the upstream TOML_BARE_KEY branch.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/exec.ts#L325-L328
fn format_toml_key(key : String) -> String {
  let is_bare = key.iter().all(char =>
    char.is_ascii_alphabetic() ||
    char.is_ascii_digit() ||
    char == '-' ||
    char == '_')
  if is_bare { key } else { Json::string(key).stringify() }
}
