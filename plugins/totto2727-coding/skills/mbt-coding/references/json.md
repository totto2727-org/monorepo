# MoonBit JSON

> Document type: concrete MoonBit implementation guidance.

Keep the standard `Json` type at the serialization boundary. Every type constructed from JSON must implement the standard `FromJson` trait. Use `derive(FromJson)` when its generated representation matches the wire contract; otherwise implement `FromJson` manually. Parse text into `Json`, then call `@json.from_json`; do not add a type-specific function whose contract is `Json -> T`.

Decode incoming JSON into an external response type, convert that response into a validated domain type, and expose only the domain type to internal application layers. For outbound data, convert the domain type into a dedicated request type and call its `ToJson` implementation at the wire boundary.

Never pass a generic `Json` value, `Map[String, Json]`, or serialized JSON string through internal services when the structure is known. Never build JSON by concatenating strings. A conversion interface from a known type `T` to `Json` must be that type's standard `ToJson::to_json` implementation; do not add helpers or methods such as `encode_T`, `T_to_json`, or `render_T_json` whose contract is `T -> Json`. Pattern matching inside `to_json` remains appropriate for scalar and variant representations.

Whenever adding `ToJson` to a type, verify the inverse contract with an executable round-trip test: serialize an instance with `to_json`, decode that `Json` through the same type's standard `FromJson` implementation, and assert that the decoded value preserves the original instance. Do not treat a JSON snapshot alone as proof that encoding and decoding agree.

Use `Map[String, Json]` only for a dynamic key set that cannot be expressed by static lenses. Keep the map inside the one `to_json` implementation that needs it, and serialize it through its standard `ToJson` implementation.

## Lens-assisted encoding

Use `totto2727/lens` to construct every known object shape inside a manual `ToJson` implementation. Define each complete output lens once at the top level with an explicit type annotation. Inside `to_json`, create a `JsonBuilder`, write values through the prebuilt lenses' `set_or_abort` operations, and return `builder.to_json()`. `ToJson::to_json` cannot propagate `JsonBuildError`; an encoding failure here is a conflicting static schema or serializer implementation defect. Keep ordinary fallible builder operations on `set`. Do not construct or compose a lens in `to_json` or another function body.

Use typed primitive and array lenses directly. For a nested request type, convert the nested value only through its own `ToJson::to_json` implementation and write that result through a raw `Json` lens. Optional output fields use an `optional` or `nullish` lens according to the wire contract so omission and explicit `null` remain distinct. Applying `nullable`, `optional`, or `nullish` produces `PresenceLens[T]`; repeated presence combinators use the last call and must not be represented as nested option types. `PresenceLens::array()` always normalizes every item to nullable semantics: JSON `null` decodes to `None`, and `None` encodes as JSON `null` so the item index is preserved. Apply `optional` after `array` only when the entire array property is optional.

Static lenses do not model dynamic object keys, scalar roots, or enum discriminators. Those representations may use standard `ToJson` conversion or direct `Json` variants inside the owning `to_json` implementation. This exception does not permit a separate `T -> Json` helper.

Parsing JSON text or selecting a schema-less portion of an existing `Json` document may still return `Json`; that operation does not encode a known type. Do not use this exception for a stable request, response, configuration, or domain shape.

## Lens-assisted decoding

Use `totto2727/lens` to select known object fields inside a manual `FromJson` implementation, or inside a private helper called exclusively by `FromJson` implementations. Translate `LensError` into the standard `JsonDecodeError` while retaining the incoming `JsonPath`. Do not expose `LensError` as the type's JSON decoding contract. Direct `@json.from_json` or pattern matching remains appropriate for scalar wrappers and discriminators.

Define each complete lens at the top level with an explicit type annotation. Use `Lens[T]` for required values and `PresenceLens[T]` for values configured with `nullable`, `optional`, or `nullish`; the `PresenceLens` type parameter is the underlying `T`, not `T?`. Function bodies may call `get` on these prebuilt lenses, but must not construct lenses with `@lens.root`, `@lens.object`, or lens combinators such as `json`, `string`, `optional`, and `nullish`; rebuilding lens paths and decoders on every call adds avoidable runtime work. When a path is genuinely dynamic and cannot be predefined, access the unstructured `Json` directly instead of constructing a lens inside the function.

Outside `FromJson`, lens access is allowed when a value intentionally remains `Json` because its shape is dynamic, schema-less, or otherwise cannot be represented by one stable type. Do not use this exception for a known structure that should implement `FromJson`; commands, services, and transport handlers should prefer the typed boundary whenever one exists.

See [`boundary-conversion.md`](boundary-conversion.md) for the full ingress, domain, and egress pipeline.
