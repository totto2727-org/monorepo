///|
test "AnyImmutableHashMap added - preserves the original map" {
  let request_id : AnyRef[String, String] = AnyRef::AnyRef("request_id")
  let original = AnyImmutableHashMap::AnyImmutableHashMap()
  let updated = original.added(request_id, "request-1")
  debug_inspect(original.get(request_id), content="None")
  debug_inspect(updated.get(request_id), content="Some(\"request-1\")")
  inspect(updated.map.contains(request_id.key), content="true")
  inspect(updated.map.length(), content="1")
}

///|
test "AnyImmutableHashMap map - exposes persistent operations" {
  let request_id : AnyRef[String, String] = AnyRef::AnyRef("request_id")
  let populated = AnyImmutableHashMap::AnyImmutableHashMap().added(
    request_id, "request-1",
  )
  let removed : AnyImmutableHashMap[String] = {
    map: populated.map.remove(request_id.key),
  }
  debug_inspect(populated.get(request_id), content="Some(\"request-1\")")
  debug_inspect(removed.get(request_id), content="None")
  inspect(removed.map.length(), content="0")
}
