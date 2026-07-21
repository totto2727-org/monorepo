# MoonBit Boundary Conversion

> Document type: concrete MoonBit implementation guidance.

## Boundary pipeline

Keep `Json`, `@admiral.Context`, environment strings, and weak library values inside the adapter that receives them. Convert them through explicit types:

```text
Json -> external response type -> validated domain type -> external request type -> Json
```

An external response type mirrors the remote contract and can use the optional and primitive fields that the source actually sends. A domain constructor validates identifiers, enum cases, units, ranges, required relationships, and cross-field invariants before returning the internal type. An external request type mirrors the outbound contract and owns its `ToJson` implementation.

## JSON ingress

Parse and decode JSON into an external response type at the transport boundary. Use `FromJson`, explicit pattern matching, or a dedicated decoder according to the remote format. Do not let a raw `Json`, `Map[String, Json]`, or partially decoded response type enter internal services.

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
