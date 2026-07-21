# MoonBit JSON

> Document type: concrete MoonBit implementation guidance.

Keep `Json` at the serialization boundary. Decode incoming JSON into an external response type, convert that response into a validated domain type, and expose only the domain type to internal application layers. For outbound data, convert the domain type into a dedicated request type and call its `ToJson` implementation at the wire boundary.

Never pass a generic `Json` value, `Map[String, Json]`, or serialized JSON string through internal services when the structure is known. Never build JSON by concatenating strings. Prefer direct `Json::object({ ... })` construction, pattern matching for variants, and explicit `ToJson` implementations for external request types.

Use `Map[String, Json]` only when the wire format distinguishes omitted fields from explicit `Json::null()` values, or when a dynamic key set cannot be expressed directly with `Json::object({ ... })`. When omission is required by an external API, keep the map inside the one `to_json` implementation that needs it.

See [`boundary-conversion.md`](boundary-conversion.md) for the full ingress, domain, and egress pipeline.
