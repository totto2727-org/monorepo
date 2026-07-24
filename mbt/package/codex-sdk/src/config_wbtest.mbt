///|
test "CodexOptions config - passes TOML override flags" {
  let config : CodexConfigObject = {
    "approval_policy": ConfigString("never"),
    "sandbox_workspace_write": ConfigObject({
      "network_access": ConfigBool(true),
    }),
    "retry_budget": ConfigInt(3),
    "tool_rules": ConfigObject({
      "allow": ConfigArray([
        ConfigString("git status"),
        ConfigString("git diff"),
      ]),
    }),
  }
  json_inspect(
    build_command_args(default_exec_args(), Some(config)),
    content=[
      "exec", "--experimental-json", "--config", "approval_policy=\"never\"",
      "--config", "sandbox_workspace_write.network_access=true", "--config",
      "retry_budget=3", "--config",
      "tool_rules.allow=[\"git status\", \"git diff\"]",
    ],
  )
}

///|
test "CodexOptions config - thread options are emitted after global overrides" {
  let config : CodexConfigObject = {
    "approval_policy": ConfigString("never"),
  }
  let args = { ..default_exec_args(), approval_policy: Some(OnRequest) }
  json_inspect(
    values_after(build_command_args(args, Some(config)), "--config"),
    content=["approval_policy=\"never\"", "approval_policy=\"on-request\""],
  )
}

///|
test "CodexOptions env - fully overrides inherited environment" {
  let options = CodexOptions::CodexOptions(env={
    "PATH": "/usr/bin:/bin",
    "CODEX_HOME": "/tmp/codex-home",
    "CUSTOM_ENV": "custom",
  })
  let exec = CodexExec::CodexExec(options)
  let (environment, inherit_environment) = exec.environment(Some("test"))
  assert_eq(inherit_environment, false)
  assert_eq(environment.get("CODEX_HOME"), Some("/tmp/codex-home"))
  assert_eq(environment.get("CUSTOM_ENV"), Some("custom"))
  assert_eq(environment.get("CODEX_API_KEY"), Some("test"))
  assert_eq(
    environment.get("CODEX_INTERNAL_ORIGINATOR_OVERRIDE"),
    Some("codex_sdk_mbt"),
  )
}

///|
test "CodexExec path - uses an explicit executable path" {
  let options = CodexOptions::CodexOptions(
    codex_path_override=@path.Path("/opt/codex/bin/codex"),
  )
  let exec = CodexExec::CodexExec(options)
  inspect(exec.executable_path.to_string(), content="/opt/codex/bin/codex")
}

///|
test "CodexExec path - defaults to the PATH executable" {
  let exec = CodexExec::CodexExec(CodexOptions::CodexOptions())
  inspect(exec.executable_path.to_string(), content="codex")
}

///|
test "CodexExec env - inherits PATH when no environment override is provided" {
  let exec = CodexExec::CodexExec(CodexOptions::CodexOptions())
  let (environment, inherit_environment) = exec.environment(None)
  assert_eq(inherit_environment, true)
  assert_eq(environment.get("PATH"), None)
}

///|
test "CodexExec env - preserves caller PATH entries without rewriting them" {
  let path = "/opt/codex/bin:/usr/bin:/opt/codex/bin"
  let exec = CodexExec::CodexExec(
    CodexOptions::CodexOptions(env={ "PATH": path }),
  )
  let (environment, inherit_environment) = exec.environment(None)
  assert_eq(inherit_environment, false)
  assert_eq(environment.get("PATH"), Some(path))
}

///|
test "CodexExec env - preserves the Windows Path key" {
  let exec = CodexExec::CodexExec(
    CodexOptions::CodexOptions(env={ "Path": "C:\\Windows\\System32" }),
  )
  let (environment, inherit_environment) = exec.environment(None)
  assert_eq(inherit_environment, false)
  assert_eq(environment.get("Path"), Some("C:\\Windows\\System32"))
  assert_eq(environment.get("PATH"), None)
}

///|
test "normalizeInput - combines structured text input segments" {
  let normalized = normalize_input(UserInputs([
    Text("Describe file changes"),
    Text("Focus on impacted tests"),
  ]))
  inspect(
    normalized.prompt,
    content="Describe file changes\n\nFocus on impacted tests",
  )
  inspect(normalized.images.length(), content="0")
}

///|
test "normalizeInput - separates image paths from text" {
  let normalized = normalize_input(UserInputs([
    Text("describe the images"),
    LocalImage(@path.Path("first.png")),
    LocalImage(@path.Path("second.jpg")),
  ]))
  inspect(normalized.prompt, content="describe the images")
  inspect(
    normalized.images.map(path => path.to_string()).join(","),
    content="first.png,second.jpg",
  )
}
