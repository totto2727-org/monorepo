# any-collection

`totto2727/any-collection` provides mutable and immutable maps whose values are stored as `Yoorkin/any.Any` and retrieved through reusable typed references. Keys are supplied when references are defined and may use any type supported by the underlying map.

## Usage

```mbt check
///|
test {
  let request_id : @any_collection.AnyRef[String, String] =
    @any_collection.AnyRef::AnyRef("request_id")
  let retry_count : @any_collection.AnyRef[String, Int] =
    @any_collection.AnyRef::AnyRef("retry_count")

  let mutable = @any_collection.AnyMutableMap::AnyMutableMap()
  mutable.set(request_id, "request-1")
  mutable.set(retry_count, 2)
  debug_inspect(mutable.get(request_id), content="Some(\"request-1\")")
  debug_inspect(mutable.get(retry_count), content="Some(2)")
  let retry_text : @any_collection.AnyRef[String, String] =
    @any_collection.AnyRef::AnyRef("retry_count")
  inspect(mutable.get_or(retry_text, "fallback"), content="fallback")
  debug_inspect(mutable.get_or_none(retry_text), content="None")
  inspect(mutable.map.length(), content="2")

  let immutable =
    @any_collection.AnyImmutableHashMap::AnyImmutableHashMap()
    .added(request_id, "request-2")
  debug_inspect(immutable.get(request_id), content="Some(\"request-2\")")
  inspect(immutable.map.contains(request_id.key), content="true")
}
```

`AnyMutableMap::set` mutates its map. `AnyImmutableHashMap::added` returns a new map and preserves its source map. Both map types accept the same `AnyRef[K, T]` instance.

The wrappers only provide the operations that require a typed reference and value conversion. Use the public `map` field directly for operations such as `contains`, `remove`, `length`, `is_empty`, iteration, and merging. Direct insertion of `Any` values is allowed.

`get` returns `None` when a key is absent and raises the original `Yoorkin/any` conversion error when the stored runtime type does not match the reference's type. `get_or` replaces both absence and conversion errors with its default value. `get_or_none` preserves successful and missing results while replacing conversion errors with `None`.

Define one shared `AnyRef[K, T]` for each key and value type so mismatched references cannot be introduced accidentally.

Value types must implement `Yoorkin/any.Anyable`. The dependency provides implementations for MoonBit core types. Custom types must extend `Yoorkin/any.Payload` and implement `Anyable`; see `src/examples/basic/main.mbt` for a complete example.
