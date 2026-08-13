# MoonBit CLI JSON

> Document type: concrete MoonBit CLI implementation guidance.

Keep request bodies separate from command input, response types, and domain values. Construct a request body only after command input has been validated and converted to the domain operation's output. Do not pass `@admiral.Context` or a command input struct into serialization code, and do not construct request JSON while reading CLI options.

Follow [`json.md`](json.md) for the authoritative rules on `ToJson`, Lens-based construction, omission versus `null`, dynamic keys, raw `Json`, and codec validation. The CLI layer owns orchestration only; the request type owns its wire contract.
