# MoonBit JSON Boundaries

Load this reference when deciding where `Json`, application types, and lens-based codecs belong.

## Boundary Pipeline

Keep raw `Json` at transport and serialization boundaries. Convert values through explicit types:

```text
Json -> external response type -> validated domain type -> external request type -> Json
```

An external response type mirrors the inbound contract. A domain constructor validates identifiers, variants, ranges, relationships, and other invariants. A separate request type mirrors the outbound contract. Do not pass a known structure as `Json`, `Map[String, Json]`, or serialized text through internal services.

## Standard Traits

- Implement the standard `FromJson` trait for every stable type decoded from JSON. Use `derive(FromJson)` when the generated representation matches the wire contract and a manual implementation otherwise.
- Implement the standard `ToJson` trait for every stable type encoded to JSON. Keep the only `T -> Json` contract in `ToJson::to_json`; do not add parallel helpers such as `encode_T`, `T_to_json`, or `render_T_json`.
- Implement `FromJson` and `ToJson` together by default. Implement a real counterpart whenever its wire contract can reasonably be defined. For a genuinely unsupported direction required only by `ObjectLens::custom`, follow the last-resort explicit-failure and call-site-audit rules in [usage.md](usage.md).
- When both directions are meaningful, add an executable round-trip test that encodes an instance, decodes it through the same type, and compares the result. A JSON snapshot alone does not prove the contracts agree.

Parse JSON text into `Json`, then call `@json.from_json`. Do not replace the standard trait with a type-specific `Json -> T` function.

## Raw JSON Exceptions

Prefer `ObjectLens::custom` for stable shapes. Use `ObjectLens::json`, `Json`, or `Map[String, Json]` only when the value is genuinely dynamic, schema-less, or has keys that cannot be represented statically. Place a nearby code comment explaining the concrete reason.

Keep a necessary `Map[String, Json]` inside the one owning `ToJson` implementation. Never build JSON by concatenating strings, and do not choose raw JSON merely because only one codec direction is convenient to implement.

## Lens Placement

Define complete lenses once at top level with explicit types. Use `Lens[T]` for required values and `PresenceLens[T]` for `nullable`, `optional`, or `nullish` values; its type parameter is the underlying `T`, not `T?`. Do not rebuild static paths or codecs inside `FromJson`, `ToJson`, or other hot functions.

Inside manual `FromJson`, use lens decoding helpers so errors retain the incoming JSON path. Inside manual `ToJson`, use typed lenses and `JsonBuilder`; reserve direct `Json` variants for scalar roots, discriminators, or genuinely dynamic sections owned by that implementation.

For large applications, keep eager top-level lenses unless measurements show startup construction is material. Only then group independently used lenses behind top-level `@lazy.Lazy` values and force each group at first use. Because `Lazy` is not thread-safe, synchronize every cross-thread access externally or keep the cell thread-local; pre-forcing alone does not make it safe to share. Do not wrap individual lenses or introduce laziness without measurement.

## Review Checklist

- Raw JSON remains at a boundary or has a nearby schema-less/dynamic rationale.
- Known inbound and outbound shapes cross the boundary through standard traits.
- Response, domain, and request types remain separate when they represent different contracts.
- Both meaningful codec directions have a round-trip test.
- An explicitly failing codec direction is documented, audited, unreachable from untrusted generic calls, and excluded from round-trip expectations.
- Static lenses are top-level and explicitly typed; presence behavior matches the wire contract.
