# MoonBit Boundary Conversion

> Document type: concrete MoonBit implementation guidance.

## Boundary pipeline

Keep `Json`, `@admiral.Context`, environment strings, and weak library values inside the adapter that receives them. Convert them through explicit types:

```text
Json -> external response type -> validated domain type -> external request type -> Json
```

An external response type mirrors the remote contract and can use the optional and primitive fields that the source actually sends. A domain constructor validates identifiers, enum cases, units, ranges, required relationships, and cross-field invariants before returning the internal type. An external request type mirrors the outbound contract. Follow [`json.md`](json.md) for the authoritative JSON and Lens implementation rules.

## JSON ingress

Parse and convert incoming JSON inside the transport adapter, then expose the typed external response to the next layer. A transport boundary may translate a JSON decoding failure into its own typed error. Follow [`json.md`](json.md) for codec traits, typed Lens selection, raw-JSON exceptions, and error-path handling.

For a known shape, decode standard `Json` through `FromJson`; use Lens inside a manual implementation when typed paths and precise decode errors are required. Keep representation-level checks in `FromJson`. When decoding a domain type directly, route the decoded fields through the canonical constructor described in [`constructors.md`](constructors.md) so deserialization cannot bypass domain invariants.

When a TOML parser can produce `Json`, convert the document once and reuse the same `FromJson` and Lens boundary instead of maintaining a second untyped traversal. Otherwise, convert its parser-owned value promptly into an explicit wire type. Apply the same rule to each CSV row or another parser result; do not force it through `Json` when that adds no useful contract. Keep syntax, structural decoding, and domain-validation failures distinguishable.

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
