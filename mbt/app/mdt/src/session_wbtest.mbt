///|
test "parse_model 1 - separates provider and model IDs" {
  let model = parse_model("anthropic/claude-sonnet-4-6")
  inspect(model.provider_id, content="anthropic")
  inspect(model.model_id, content="claude-sonnet-4-6")
}

///|
test "panic_parse_model 2 - rejects a missing provider ID" {
  try! (parse_model("/claude-sonnet-4-6") |> ignore)
}

///|
test "panic_parse_model 3 - rejects a missing model ID" {
  try! (parse_model("anthropic/") |> ignore)
}

///|
test "ModelSelection to_string 1 - returns the CLI model ID" {
  inspect(
    parse_model("anthropic/claude-sonnet-4-6").to_string(),
    content="anthropic/claude-sonnet-4-6",
  )
}

///|
test "translation_opencode_config 1 - denies every tool" {
  match translation_opencode_config().get("permission") {
    Some(@opencode.ConfigString(value)) => inspect(value, content="deny")
    _ => fail("expected deny-all OpenCode configuration")
  }
}

///|
test "translation_prompt 1 - combines instructions and Markdown" {
  let prompt = translation_prompt("ja", "# Hello")
  assert_true(prompt.contains("Translate the user's input markdown to ja."))
  assert_true(prompt.contains("# Hello"))
  assert_true(prompt.contains("Output ONLY the translated markdown."))
}
