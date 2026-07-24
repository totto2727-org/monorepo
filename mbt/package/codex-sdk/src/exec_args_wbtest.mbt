fn default_exec_args() -> CodexExecArgs {
  {
    input: "hi",
    base_url: None,
    api_key: None,
    thread_id: None,
    images: [],
    model: None,
    sandbox_mode: None,
    working_directory: None,
    additional_directories: [],
    skip_git_repo_check: None,
    output_schema_file: None,
    model_reasoning_effort: None,
    network_access_enabled: None,
    web_search_mode: None,
    web_search_enabled: None,
    approval_policy: None,
  }
}

///|
test "CodexExec run - places resume args before image args" {
  let args = {
    ..default_exec_args(),
    thread_id: Some("thread-id"),
    images: [@path.Path("img.png")],
  }
  json_inspect(
    build_command_args(args, None),
    content=[
      "exec", "--experimental-json", "resume", "thread-id", "--image", "img.png",
    ],
  )
}

///|
test "CodexExec run - passes base URL model and sandbox options" {
  let args = {
    ..default_exec_args(),
    base_url: Some("https://example.test"),
    model: Some("gpt-test-1"),
    sandbox_mode: Some(WorkspaceWrite),
  }
  json_inspect(
    build_command_args(args, None),
    content=[
      "exec", "--experimental-json", "--config",
      "openai_base_url=\"https://example.test\"", "--model", "gpt-test-1",
      "--sandbox", "workspace-write",
    ],
  )
}

///|
test "CodexExec run - passes model reasoning effort" {
  let args = {
    ..default_exec_args(),
    model_reasoning_effort: Some(High),
  }
  json_inspect(
    build_command_args(args, None),
    content=[
      "exec", "--experimental-json", "--config", "model_reasoning_effort=\"high\"",
    ],
  )
}

///|
test "CodexExec run - passes network access enabled" {
  let args = {
    ..default_exec_args(),
    network_access_enabled: Some(true),
  }
  json_inspect(
    build_command_args(args, None),
    content=[
      "exec", "--experimental-json", "--config",
      "sandbox_workspace_write.network_access=true",
    ],
  )
}

///|
test "CodexExec run - maps legacy web search enabled to live" {
  let args = { ..default_exec_args(), web_search_enabled: Some(true) }
  json_inspect(
    build_command_args(args, None),
    content=["exec", "--experimental-json", "--config", "web_search=\"live\""],
  )
}

///|
test "CodexExec run - passes explicit web search mode" {
  let args = {
    ..default_exec_args(),
    web_search_mode: Some(Cached),
    web_search_enabled: Some(false),
  }
  json_inspect(
    build_command_args(args, None),
    content=["exec", "--experimental-json", "--config", "web_search=\"cached\""],
  )
}

///|
test "CodexExec run - maps legacy web search disabled" {
  let args = { ..default_exec_args(), web_search_enabled: Some(false) }
  json_inspect(
    build_command_args(args, None),
    content=[
      "exec", "--experimental-json", "--config", "web_search=\"disabled\"",
    ],
  )
}

///|
test "CodexExec run - passes approval policy" {
  let args = { ..default_exec_args(), approval_policy: Some(OnRequest) }
  json_inspect(
    build_command_args(args, None),
    content=[
      "exec", "--experimental-json", "--config", "approval_policy=\"on-request\"",
    ],
  )
}

///|
test "CodexExec run - passes additional directories as repeated flags" {
  let args = {
    ..default_exec_args(),
    additional_directories: [
      @path.Path("../backend"),
      @path.Path("/tmp/shared"),
    ],
  }
  json_inspect(
    build_command_args(args, None),
    content=[
      "exec", "--experimental-json", "--add-dir", "../backend", "--add-dir",
      "/tmp/shared",
    ],
  )
}

///|
test "CodexExec run - passes output schema working directory and git option" {
  let args = {
    ..default_exec_args(),
    working_directory: Some(@path.Path("/tmp/work")),
    skip_git_repo_check: Some(true),
    output_schema_file: Some(@path.Path("/tmp/schema.json")),
  }
  json_inspect(
    build_command_args(args, None),
    content=[
      "exec", "--experimental-json", "--cd", "/tmp/work",
      "--skip-git-repo-check", "--output-schema", "/tmp/schema.json",
    ],
  )
}

///|
test "CodexExec run - forwards images in input order" {
  let args = {
    ..default_exec_args(),
    images: [@path.Path("first.png"), @path.Path("second.jpg")],
  }
  json_inspect(
    build_command_args(args, None),
    content=[
      "exec", "--experimental-json", "--image", "first.png", "--image",
      "second.jpg",
    ],
  )
}
