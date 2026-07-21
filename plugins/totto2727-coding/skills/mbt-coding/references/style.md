# MoonBit Style

> Document type: concrete MoonBit implementation guidance.

## Documentation

Document every public function, type, method, and constant with `///`. State caller-visible behavior and constraints; do not restate the signature.

## Names

- Use PascalCase for types and traits.
- Use snake_case for functions, methods, variables, and parameters.
- Preserve standard abbreviations such as JSON and ID; do not invent local abbreviations.
- Name Array values with an `_array` suffix when the suffix prevents ambiguity about the representation.
- Use a bare verb for a mutating operation and a past participle for an immutable operation that returns a new value, such as `sort` versus `sorted`.
- Name the canonical constructor after the type. Name alternate factories by intent, such as `from_corners` or `new_unit`.

## Anonymous functions

Prefer arrow functions for inline callbacks. Use a named local function only when recursion, reuse, or an explicit local signature materially improves the code.

## Ignored results

Discard a return value explicitly with `expr |> ignore` when the operation is performed only for its effect.
