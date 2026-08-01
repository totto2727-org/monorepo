///|
fn opencode_test_context(
  group : @async.TaskGroup[Unit],
  environment : Map[String, String],
) -> @core.CodingAgentOpenContext {
  @core.CodingAgentOpenContext::{
    run_id: @core.RunId::parse("opencode-test-run") catch {
      _ => abort("test run ID must be valid")
    },
    task_group: group,
    workspace: @core.WorkspaceRef::{
      root: @path.Path("/workspace"),
      additional_writable_roots: [],
    },
    approval: @core.Never,
    network: @core.Disabled,
    environment: @immut_hashmap.HashMap(environment.to_array()),
    events: @core.EventSink::discard(),
  }
}

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

///|
async test "opencode_agent 2 - merges inherited adapter and caller environment" {
  @async.with_task_group() <| group => {
    let options = OpenCodeAgentOptions::OpenCodeAgentOptions(extra_env={
      "ADAPTER": "enabled",
      "SHARED": "adapter",
    })
    let environment = merged_environment(
      options,
      opencode_test_context(group, { "CALLER": "active", "SHARED": "caller" }),
    )
    assert_eq(environment.get("ADAPTER"), Some("enabled"))
    assert_eq(environment.get("CALLER"), Some("active"))
    assert_eq(environment.get("SHARED"), Some("caller"))
    assert_true(environment.get("PATH") is Some(_))
  }
}

///|
test "opencode_agent 3 - maps context files to CLI file inputs" {
  let input = request_input(@path.Path("/workspace"), @core.CodingAgentRequest::{
    instruction: "fix the issue",
    context_files: [@path.Path("README.md"), @path.Path("/shared/guide.md")],
  })
  match input {
    @sdk.UserInputs(
      [
        @sdk.Text(instruction),
        @sdk.LocalFile(relative),
        @sdk.LocalFile(absolute),
      ]
    ) => {
      assert_eq(instruction, "fix the issue")
      assert_eq(relative, @path.Path("/workspace/README.md"))
      assert_eq(absolute, @path.Path("/shared/guide.md"))
    }
    _ => fail("expected text followed by two local-file inputs")
  }
}
