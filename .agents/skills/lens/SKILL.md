---
name: lens
description: Use totto2727/lens to read, construct, and validate typed JSON in MoonBit. Use when implementing or reviewing nested JSON selection, choosing custom instead of raw Json lenses, nullable/optional/nullish fields, JSON Pointer-aware FromJson decoding, ToJson serialization with JsonBuilder, aggregate validation, or deferred Lens initialization with Lazy after measuring startup cost. Do not use for mutating an existing JSON document or arbitrary array-index traversal, which are outside the library's current scope.
---

# MoonBit Lens

Apply `totto2727/lens` as a typed boundary around JSON paths while preserving the caller's standard `FromJson`, `ToJson`, and error contracts.

## Installation

Add the module with `moon add totto2727/lens`, then import `"totto2727/lens"` in the consuming `moon.pkg`. The default package alias is `@lens`.

## API Selection

| Goal | API |
| --- | --- |
| Read one typed path | `Lens::get` or `PresenceLens::get` |
| Implement a standard JSON decoder | `get_or_json_decode_error`, `add_to_json_path`, or `json_decode_error` |
| Decode an intentional raw-`Json` exception | `Lens[Json]::decode_from_json` |
| Build JSON with recoverable errors | `JsonBuilder` plus `set` |
| Implement `ToJson::to_json` | `JsonBuilder` plus `set_or_abort` |
| Report every selected-field issue | `validate` with heterogeneous lenses |
| Defer measured startup construction | Group lenses in top-level `@lazy.Lazy` values |

## References

- [references/usage.md](references/usage.md) covers concrete APIs, presence semantics, construction, decoding errors, validation, and deferred lens initialization.
- [references/json-boundaries.md](references/json-boundaries.md) covers JSON ingress, egress, and application type boundaries.

## Core Rules

- Prefer derived `FromJson` and `ToJson` for an ordinary stable shape; use lens when the task needs path-focused access, an irregular wire shape, typed construction, presence control, or aggregate diagnostics.
- Prefer `ObjectLens::custom` over `ObjectLens::json` so the selected value crosses the boundary as an application type. Use a raw `Json` lens only for a genuinely dynamic or schema-less value, and add a nearby code comment explaining why it cannot have a stable type.
- Implement `FromJson` and `ToJson` as a pair for types selected through `custom`. Implement both directions normally whenever possible. Only when one direction is genuinely impossible or disproportionately expensive, still implement that trait and fail explicitly inside it, with a comment explaining the constraint; this is a last-resort workaround for the language's combined `custom` trait bound. Before using an aborting implementation, audit generic serialization call sites and keep the type away from externally triggerable serialization paths. Do not choose `json` merely because only one trait has a meaningful implementation.
- Define complete reusable lenses at top level with explicit `@lens.Lens[T]`, `@lens.PresenceLens[T]`, or `@lens.ObjectLens` types so paths and codecs are constructed once and reviewable in one place.
- Use `get` only when `@lens.LensError` is the intended boundary. Inside `FromJson`, translate failures with the library's JSON-decoding helpers so nested errors retain the incoming `@json.JsonPath`.
- Use `set` when the caller can handle `@lens.JsonBuildError`. Use `set_or_abort` only inside an infallible `ToJson::to_json` implementation, where a path conflict is an implementation defect.
- Treat `nullable`, `optional`, and `nullish` as replacement policies; the last presence combinator determines both read and write behavior.
- Treat `PresenceLens::array()` as nullable item semantics, while `primitive.array().optional()` makes the entire array property optional.
- Use `validate` only to collect ordered issues. Read application values through the original typed lenses after `Valid`.
- Do not invent source-document mutation, refinement, alternative, or arbitrary array-index APIs; confirm the current README or generated package interface when a requested operation is outside the documented scope.

## Failure Handling

- When an API name or signature differs, inspect the checked-out `README.mbt.md`, `moon.mod`, and generated `.mbti` output before changing code because the installed version may differ from examples.
- When a selected value needs a custom validation error, use `lens.json_decode_error(path, message)` so the error points to the selected location.
- When only one JSON direction is meaningful for an otherwise stable type, first confirm that a real counterpart cannot reasonably be implemented. Then implement the unsupported trait with an explicit failure and rationale rather than falling back to a raw `Json` lens. Prefer a standard `JsonDecodeError` for an unsupported `FromJson` direction and `abort` for an unsupported `ToJson` direction. Treat that implementation as a deliberately unreachable compatibility adapter: document the supported direction, audit every generic trait call site, and do not expose the unsupported operation to untrusted input.
- When a missing intermediate object occurs, preserve the error; presence policies apply to the selected leaf and must not hide an invalid surrounding structure.
