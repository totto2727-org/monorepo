///|
test "opencode_agent 1 - constructs CLI options" {
  let config : @sdk.OpenCodeConfigObject = {
    "model": @sdk.ConfigString("test/model"),
  }
  let options = OpenCodeAgentOptions::OpenCodeAgentOptions(
    opencode_path_override=@path.Path("/tools/opencode"),
    config~,
    resume_thread_id="session-7",
    model="provider/model",
    agent="build",
    variant="high",
    title="graph run",
    thinking=true,
    extra_env={ "ADAPTER": "enabled" },
  )
  assert_eq(options.opencode_path_override, Some(@path.Path("/tools/opencode")))
  assert_eq(options.config, Some(config))
  assert_eq(options.resume_thread_id, Some("session-7"))
  assert_eq(options.model, Some("provider/model"))
  assert_eq(options.agent, Some("build"))
  assert_eq(options.variant, Some("high"))
  assert_eq(options.title, Some("graph run"))
  assert_true(options.thinking)
  assert_eq(options.extra_env.get("ADAPTER"), Some("enabled"))
}

// OpenCode CLI and JSONL contracts:
// https://opencode.ai/docs/cli/
// https://github.com/anomalyco/opencode/blob/1e17856ba4b5b052650c8115060852f3f023844e/packages/opencode/src/cli/cmd/run.ts#L416-L428
