# MoonBit JSON

> Document type: concrete MoonBit implementation guidance.

Keep the standard `Json` type at the serialization boundary. Every type constructed from JSON must implement the standard `FromJson` trait. Use `derive(FromJson)` when its generated representation matches the wire contract; otherwise implement `FromJson` manually. Parse text into `Json`, then call `@json.from_json`; do not add a type-specific function whose contract is `Json -> T`.

Decode incoming JSON into an external response type, convert that response into a validated domain type, and expose only the domain type to internal application layers. For outbound data, convert the domain type into a dedicated request type and call its `ToJson` implementation at the wire boundary.

Never pass a generic `Json` value, `Map[String, Json]`, or serialized JSON string through internal services when the structure is known. Never build JSON by concatenating strings. Prefer direct `Json::object({ ... })` construction, pattern matching for variants, and explicit `ToJson` implementations for external request types.

Whenever adding `ToJson` to a type, verify the inverse contract with an executable round-trip test: serialize an instance with `to_json`, decode that `Json` through the same type's standard `FromJson` implementation, and assert that the decoded value preserves the original instance. Do not treat a JSON snapshot alone as proof that encoding and decoding agree.

Use `Map[String, Json]` only when the wire format distinguishes omitted fields from explicit `Json::null()` values, or when a dynamic key set cannot be expressed directly with `Json::object({ ... })`. When omission is required by an external API, keep the map inside the one `to_json` implementation that needs it.

## Lens-assisted decoding

Use `totto2727/lens` to select known object fields inside a manual `FromJson` implementation, or inside a private helper called exclusively by `FromJson` implementations. Do not expose `LensError` as the type's JSON decoding contract. Direct `@json.from_json` or pattern matching remains appropriate for scalar wrappers and discriminators.

Define each complete lens at the top level with an explicit type annotation. Function bodies may use these prebuilt lenses, but must not construct lenses with `@lens.root`, `@lens.object`, or lens combinators such as `json`, `string`, `optional`, and `nullish`; rebuilding lens paths and decoders on every call adds avoidable runtime work. When a path is genuinely dynamic and cannot be predefined, access the unstructured `Json` directly instead of constructing a lens inside the function.

Use `Lens::get_or_json_decode_error(document, path)` for the normal case where a failed selection must become a standard `JsonDecodeError`. When the selected value still needs standard decoding, pass `path=lens.add_to_json_path(path)` to `@json.from_json` so nested failures retain the complete location. Use `Lens::json_decode_error(path, message)` only for a custom validation or discriminator error that belongs to the selected lens location. Direct `Lens::get` with `catch` is reserved for intentional recovery such as a fallback or tolerant optional interpretation; do not use it merely to translate a failed read into `JsonDecodeError`.

Do not operate on `Pointer` directly. Pointer path conversion is an implementation detail used by the lens JSON-decoding helpers.

```mbt
///|
let response_status_lens : @lens.Lens[Json] = @lens.root().json("status")

///|
pub impl @json.FromJson for Response with fn from_json(json, path) {
  let status : Status = @json.from_json(
    response_status_lens.get_or_json_decode_error(json, path),
    path=response_status_lens.add_to_json_path(path),
  )
  { status }
}
```

Outside `FromJson`, lens access is allowed when a value intentionally remains `Json` because its shape is dynamic, schema-less, or otherwise cannot be represented by one stable type. Do not use this exception for a known structure that should implement `FromJson`; commands, services, and transport handlers should prefer the typed boundary whenever one exists.

See [`boundary-conversion.md`](boundary-conversion.md) for the full ingress, domain, and egress pipeline.
