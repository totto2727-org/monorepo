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

fn build_command_args(
  args : CodexExecArgs,
  config_overrides : CodexConfigObject?,
) -> Array[String] raise CodexSdkError {
  let command_args = ["exec", "--experimental-json"]
  if config_overrides is Some(config) {
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
  command_args
}
