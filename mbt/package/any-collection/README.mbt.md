# any-collection

`totto2727/any-collection` provides mutable and immutable maps whose values are stored as `tonyfettes/any.Any` and retrieved through reusable typed references. Names are supplied only when references are defined; collection operations do not accept raw string names.

## Usage

```mbt check
///|
test {
  let request_id : @any_collection.AnyRef[String] =
    @any_collection.AnyRef::AnyRef("request_id")
  let retry_count : @any_collection.AnyRef[Int] =
    @any_collection.AnyRef::AnyRef("retry_count")

  let mutable = @any_collection.AnyMutableMap::AnyMutableMap()
  mutable.set(request_id, "request-1")
  mutable.set(retry_count, 2)
  debug_inspect(mutable.get(request_id), content="Some(\"request-1\")")
  debug_inspect(mutable.get(retry_count), content="Some(2)")

  let immutable =
    @any_collection.AnyImmutableHashMap::AnyImmutableHashMap()
    .added(request_id, "request-2")
  debug_inspect(immutable.get(request_id), content="Some(\"request-2\")")
}
```

`AnyMutableMap::set` mutates its map. `AnyImmutableHashMap::added` and `AnyImmutableHashMap::removed` return new maps and preserve their source maps. Both map types accept the same `AnyRef[T]` instance.

`get` returns `None` when a name is absent or when the stored runtime type does not match the reference's type. Define one shared `AnyRef[T]` for each name and value type so mismatched references cannot be introduced accidentally.
