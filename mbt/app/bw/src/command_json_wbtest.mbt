///|
test "format_json_extract_response keeps raw JSON by default" {
  let raw = "{\"success\":true,\"result\":\"# Title\\n\\nBody\"}"
  inspect(
    try! format_json_extract_response(raw, RawJson),
    content="{\"success\":true,\"result\":\"# Title\\n\\nBody\"}",
  )
}

///|
test "format_json_extract_response renders markdown string result" {
  let raw = "{\"success\":true,\"result\":\"# Title\\n\\nBody\"}"
  inspect(
    try! format_json_extract_response(raw, Markdown),
    content="# Title\n\nBody",
  )
}

///|
test "format_json_extract_response renders text string result" {
  let raw = "{\"success\":true,\"result\":\"plain output\"}"
  inspect(try! format_json_extract_response(raw, Text), content="plain output")
}

///|
test "format_json_extract_response renders structured markdown as fenced JSON" {
  let raw = "{\"success\":true,\"result\":{\"title\":\"Example\"}}"
  inspect(
    try! format_json_extract_response(raw, Markdown),
    content="```json\n{\"title\":\"Example\"}\n```",
  )
}
