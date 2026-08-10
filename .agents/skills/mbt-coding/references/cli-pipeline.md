# MoonBit CLI Pipeline

> Document type: concrete MoonBit CLI implementation guidance.

## Required command pipeline

Every command must follow the first three steps. Request-backed commands also follow steps four and five:

1. **Option name constants** — define every CLI option name once.
2. **`admiral` command definition** — use only those constants in the option definitions.
3. **Options struct** — convert `@admiral.Context` into a typed command-local options struct.
4. **Body struct** — convert the options struct into the exact request body type.
5. **Request** — send `body.to_json()` to the HTTP layer.

Do not skip the options struct. Do not build JSON directly from `@admiral.Context`.
