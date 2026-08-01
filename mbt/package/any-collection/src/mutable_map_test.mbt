///|
test "AnyMutableMap get - returns values through typed references" {
  let request_id : AnyRef[String, String] = AnyRef::AnyRef("request_id")
  let retry_count : AnyRef[String, Int] = AnyRef::AnyRef("retry_count")
  let context = AnyMutableMap::AnyMutableMap()
  context.set(request_id, "request-1")
  context.set(retry_count, 2)
  debug_inspect(context.get(request_id), content="Some(\"request-1\")")
  debug_inspect(context.get(retry_count), content="Some(2)")
}

///|
test "AnyMutableMap get variants - handle conversion errors explicitly" {
  let count : AnyRef[Int, Int] = AnyRef::AnyRef(1)
  let text : AnyRef[Int, String] = AnyRef::AnyRef(1)
  let missing : AnyRef[Int, String] = AnyRef::AnyRef(2)
  let context = AnyMutableMap::AnyMutableMap()
  context.set(count, 2)
  let mismatch_raised = try {
    context.get(text) |> ignore
    false
  } catch {
    Failure::Failure(_) => true
    _ => false
  }
  inspect(mismatch_raised, content="true")
  inspect(context.get_or(text, "fallback"), content="fallback")
  inspect(context.get_or(missing, "fallback"), content="fallback")
  debug_inspect(context.get_or_none(text), content="None")
  debug_inspect(context.get_or_none(missing), content="None")
}

///|
test "AnyMutableMap map - exposes operations without typed conversion" {
  let request_id : AnyRef[String, String] = AnyRef::AnyRef("request_id")
  let context = AnyMutableMap::AnyMutableMap()
  context.set(request_id, "request-1")
  context.map.remove(request_id.key)
  debug_inspect(context.get(request_id), content="None")
  inspect(context.map.contains(request_id.key), content="false")
  inspect(context.map.length(), content="0")
  inspect(context.map.is_empty(), content="true")
}
