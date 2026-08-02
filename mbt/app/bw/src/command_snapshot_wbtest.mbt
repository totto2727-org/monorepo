///|
test "SnapshotResponse FromJson - decodes content and screenshot" {
  let response : SnapshotResponse = @json.from_json(
    @json.parse(
      "{\"success\":true,\"result\":{\"content\":\"<html />\",\"screenshot\":\"aGVsbG8=\"}}",
    ),
  )
  inspect(response.success, content="true")
  debug_inspect(response.result.unwrap().content, content="Some(\"<html />\")")
  debug_inspect(
    response.result.unwrap().screenshot,
    content="Some(\"aGVsbG8=\")",
  )
}
