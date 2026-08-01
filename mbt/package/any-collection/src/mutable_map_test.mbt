///|
test "AnyMutableMap get - returns values through typed references" {
  let request_id : AnyRef[String] = AnyRef::AnyRef("request_id")
  let retry_count : AnyRef[Int] = AnyRef::AnyRef("retry_count")
  let context = AnyMutableMap::AnyMutableMap()
  context.set(request_id, "request-1")
  context.set(retry_count, 2)
  debug_inspect(context.get(request_id), content="Some(\"request-1\")")
  debug_inspect(context.get(retry_count), content="Some(2)")
}

///|
test "AnyMutableMap get - rejects a mismatched reference type" {
  let count : AnyRef[Int] = AnyRef::AnyRef("value")
  let text : AnyRef[String] = AnyRef::AnyRef("value")
  let context = AnyMutableMap::AnyMutableMap()
  context.set(count, 2)
  debug_inspect(context.get(text), content="None")
}

///|
test "AnyMutableMap remove - removes the referenced value" {
  let request_id : AnyRef[String] = AnyRef::AnyRef("request_id")
  let context = AnyMutableMap::AnyMutableMap()
  context.set(request_id, "request-1")
  context.remove(request_id)
  debug_inspect(context.get(request_id), content="None")
  inspect(context.contains(request_id), content="false")
  inspect(context.length(), content="0")
  inspect(context.is_empty(), content="true")
}
