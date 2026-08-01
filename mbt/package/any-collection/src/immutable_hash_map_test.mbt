///|
test "AnyImmutableHashMap added - preserves the original map" {
  let request_id : AnyRef[String] = AnyRef::AnyRef("request_id")
  let original = AnyImmutableHashMap::AnyImmutableHashMap()
  let updated = original.added(request_id, "request-1")
  debug_inspect(original.get(request_id), content="None")
  debug_inspect(updated.get(request_id), content="Some(\"request-1\")")
  inspect(updated.contains(request_id), content="true")
  inspect(updated.length(), content="1")
}

///|
test "AnyImmutableHashMap removed - preserves the source map" {
  let request_id : AnyRef[String] = AnyRef::AnyRef("request_id")
  let populated = AnyImmutableHashMap::AnyImmutableHashMap().added(
    request_id, "request-1",
  )
  let removed = populated.removed(request_id)
  debug_inspect(populated.get(request_id), content="Some(\"request-1\")")
  debug_inspect(removed.get(request_id), content="None")
  inspect(removed.length(), content="0")
}
