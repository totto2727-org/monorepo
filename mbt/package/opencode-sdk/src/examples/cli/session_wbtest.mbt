///|
// OpenCode session and prompt wire contracts:
// https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/v2/gen/types.gen.ts#L9469-L9507
// https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/v2/gen/types.gen.ts#L9790-L9837
test "SessionCreateBody ToJson 1 - disables every tool" {
  let body : SessionCreateBody = {
    title: "English translation",
    tool_access: NoTools,
  }
  json_inspect(ToJson::to_json(body), content={
    "title": "English translation",
    "permission": [
      { "permission": "*", "pattern": "*", "action": "deny" },
    ],
  })
}

///|
test "SessionCreateBody ToJson 2 - permits only web fetch" {
  let body : SessionCreateBody = {
    title: "URL summary",
    tool_access: WebFetchOnly,
  }
  json_inspect(ToJson::to_json(body), content={
    "title": "URL summary",
    "permission": [
      { "permission": "*", "pattern": "*", "action": "deny" },
      { "permission": "webfetch", "pattern": "*", "action": "allow" },
    ],
  })
}

///|
test "PromptBody ToJson 1 - sends one text part" {
  let body : PromptBody = { system: "System", text: "User input" }
  json_inspect(ToJson::to_json(body), content={
    "format": { "type": "text" },
    "system": "System",
    "parts": [{ "type": "text", "text": "User input" }],
  })
}

///|
test "decode_session_id 1 - extracts the created session ID" {
  inspect(
    decode_session_id(Json::object({ "id": "ses_example".to_json() })),
    content="ses_example",
  )
}

///|
test "decode_assistant_text 1 - concatenates text parts only" {
  inspect(
    decode_assistant_text(
      Json::object({
        "info": Json::empty_object(),
        "parts": Json::array([
          Json::object({
            "type": "tool".to_json(),
            "text": "ignored".to_json(),
          }),
          Json::object({
            "type": "text".to_json(),
            "text": "Hello ".to_json(),
          }),
          Json::object({
            "type": "text".to_json(),
            "text": "world".to_json(),
          }),
        ]),
      }),
    ),
    content="Hello world",
  )
}

///|
test "panic_decode_assistant_text 2 - rejects assistant errors" {
  try! (
    decode_assistant_text(
      Json::object({
        "info": Json::object({
          "error": Json::object({
            "name": "UnknownError".to_json(),
            "data": Json::object({ "message": "failed".to_json() }),
          }),
        }),
        "parts": Json::array([]),
      }),
    )
    |> ignore
  )
}

///|
test "validated_http_url 1 - accepts HTTPS" {
  inspect(
    validated_http_url("https://example.com"),
    content="https://example.com",
  )
}

///|
test "validated_http_url 2 - accepts HTTP" {
  inspect(
    validated_http_url("http://example.com"),
    content="http://example.com",
  )
}

///|
test "panic_validated_http_url 3 - rejects non-HTTP schemes" {
  try! (validated_http_url("file:///tmp/page.html") |> ignore)
}
