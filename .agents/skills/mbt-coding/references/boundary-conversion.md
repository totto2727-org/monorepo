# MoonBit Boundary Conversion

> Document type: concrete MoonBit implementation guidance.

## Boundary pipeline

Keep `Json`, `@admiral.Context`, environment strings, and weak library values inside the adapter that receives them. Convert them through explicit types:

```text
Json -> external response type -> validated domain type -> external request type -> Json
```

An external response type mirrors the remote contract and can use the optional and primitive fields that the source actually sends. A domain constructor validates identifiers, enum cases, units, ranges, required relationships, and cross-field invariants before returning the internal type. An external request type mirrors the outbound contract and owns its only `T -> Json` interface as a standard `ToJson::to_json` implementation. For a known object shape, define complete output lenses at the top level and populate a `JsonBuilder` through those lenses' `set_or_abort` operations inside `to_json`. Required output lenses use `Lens[T]`; lenses configured with `nullable`, `optional`, or `nullish` use `PresenceLens[T]`, where `T` is the underlying non-option type. Do not expose a separate encoder helper or method that returns `Json`.

## JSON ingress

Parse JSON text into the standard `Json` type and decode it into an external response type through that type's standard `FromJson` implementation. Use `derive(FromJson)` when the generated format matches the wire contract and a manual `FromJson` implementation otherwise. Do not replace the trait with a dedicated `Json -> T` decoder. A transport boundary may translate `JsonDecodeError` into its own typed error after `@json.from_json` fails.

Inside a manual `FromJson` implementation, use `totto2727/lens` for known object-field selection. Define complete lenses once at the top level with explicit types and never construct or compose a lens in a function body. Keep lens reads in the `FromJson` implementation or in a private implementation-only helper. Use `Lens::get_or_json_decode_error(document, path)` for ordinary selection failures, then pass `path=lens.add_to_json_path(path)` when the selected `Json` is decoded through `@json.from_json`. Use `Lens::json_decode_error(path, message)` only when a custom validation error belongs to the selected location. Use direct `Lens::get` with `catch` only for intentional recovery or fallback behavior, and never operate on `Pointer` directly. Use direct `@json.from_json` or pattern matching for scalar wrappers and discriminators. Outside `FromJson`, lens access is allowed only for values intentionally kept as unstructured `Json` because their shape is dynamic or lacks a stable type. A known structure must still cross the boundary through `FromJson`.

Keep response and request types separate even when their current fields are similar. They belong to different external contracts and may evolve independently.

## Admiral ingress

Read `@admiral.Context` once in a command-local conversion function. Convert raw flags, positional values, configuration, and environment fallbacks into a validated internal command input. Internal functions must not accept `@admiral.Context`.

For a command that calls an external API, use this sequence:

```text
@admiral.Context -> command input -> domain operation -> request body -> Json
```

The command input represents user intent; the request body represents the remote protocol. Do not collapse them into one type or construct request JSON while reading Admiral options.

## Library adapters

Treat a library type as an external input when it is too broad to encode the domain invariant. Convert it once in a small adapter, reject unsupported variants there, and expose only the validated domain type to the rest of the program.
