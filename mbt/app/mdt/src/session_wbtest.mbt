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
test "PromptBody ToJson 1 - sends the selected model and text format" {
  let body : PromptBody = {
    model: parse_model("anthropic/claude-sonnet-4-6"),
    system: "System",
    text: "Input",
  }
  json_inspect(ToJson::to_json(body), content={
    "model": { "providerID": "anthropic", "modelID": "claude-sonnet-4-6" },
    "format": { "type": "text" },
    "system": "System",
    "parts": [{ "type": "text", "text": "Input" }],
  })
}

///|
test "SessionCreateBody ToJson 1 - denies every tool" {
  let body : SessionCreateBody = { title: "mdt-translate" }
  json_inspect(ToJson::to_json(body), content={
    "title": "mdt-translate",
    "permission": [{ "permission": "*", "pattern": "*", "action": "deny" }],
  })
}

///|
test "decode_assistant_text 1 - joins text parts" {
  let raw =
    #|{"info":{"role":"assistant"},"parts":[{"type":"text","text":"Hello"},{"type":"step-finish"},{"type":"text","text":" world"}]}
  let response = @json.parse(raw)
  inspect(decode_assistant_text(response), content="Hello world")
}

///|
test "panic_decode_assistant_text 2 - rejects an assistant error" {
  let raw =
    #|{"info":{"role":"assistant","error":{"name":"ProviderError"}},"parts":[]}
  let response = @json.parse(raw)
  try! (decode_assistant_text(response) |> ignore)
}
