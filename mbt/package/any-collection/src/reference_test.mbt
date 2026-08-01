///|
test "AnyRef - is shared by mutable and immutable maps" {
  let request_id : AnyRef[String] = AnyRef::AnyRef("request_id")
  let mutable = AnyMutableMap::AnyMutableMap()
  let immutable = AnyImmutableHashMap::AnyImmutableHashMap().added(
    request_id, "immutable-request",
  )
  mutable.set(request_id, "mutable-request")
  debug_inspect(mutable.get(request_id), content="Some(\"mutable-request\")")
  debug_inspect(
    immutable.get(request_id),
    content="Some(\"immutable-request\")",
  )
}
