# Lens Usage Reference

Load this reference when implementing or reviewing code that uses `totto2727/lens`.

## Dependency Setup

Add the module dependency from the consumer module root:

```bash
moon add totto2727/lens
```

Confirm that the command added a resolved `totto2727/lens@...` import to the current `moon.mod`. Edit `moon.mod.json` only when the consumer is an explicitly legacy project that already uses that filename.

Import the root package in the `moon.pkg` that uses it:

```text
import {
  "totto2727/lens",
}
```

Use the default `@lens` alias unless the surrounding package already assigns an explicit alias.

## Typed Reads

Build a complete path by starting from `@lens.root()` or `@lens.object(key)` and choosing a typed child lens.

```moonbit
///|
let user_name_lens : @lens.Lens[String] = @lens.object("user").string("name")

///|
fn read_user_name(document : Json) -> String raise @lens.LensError {
  user_name_lens.get(document)
}
```

Available typed child selectors are `string`, `bool`, `number`, `int`, `json`, and `custom`; call `array()` on an item lens to decode or encode an array.

Prefer `ObjectLens::custom` for a stable application type and implement both `@json.FromJson` and `ToJson`. Use `ObjectLens::json` only when the selected value is genuinely dynamic or schema-less, and place a code comment next to the lens explaining that reason.

Do not use a raw `Json` lens merely because one JSON direction is unavailable or expensive. First implement a real counterpart whenever its wire contract can be defined reasonably. Only as a last resort, the `custom` API's combined `FromJson + ToJson` bound may be satisfied by implementing the unsupported direction as an explicit failure with a rationale comment. Prefer a standard decode error for `FromJson` and `abort` for `ToJson`. Before accepting an aborting serializer, audit every direct and generic `ToJson` call site, keep the type out of logging, persistence, forwarding, and other externally triggerable serialization paths, and test only the supported direction:

```moonbit
///|
struct ProviderEvent {
  kind : String
} derive(FromJson)

///|
impl ToJson for ProviderEvent with fn to_json(_self) -> Json {
  // Provider events are inbound-only; encoding has no wire contract.
  abort("ProviderEvent does not support JSON encoding")
}

///|
let provider_event_lens : @lens.Lens[ProviderEvent] = @lens.root()
  .custom("event")
```

For the opposite direction, implement `FromJson` and raise an explanatory `@json.JsonDecodeError` at the received path. This keeps the trait pair explicit without pretending that the unsupported operation can succeed:

```moonbit
///|
struct OutboundCommand {
  name : String
} derive(ToJson)

///|
impl @json.FromJson for OutboundCommand with fn from_json(_json, path) {
  raise @json.JsonDecodeError::JsonDecodeError((
    path,
    "OutboundCommand does not support JSON decoding",
  ))
}

///|
let outbound_command_lens : @lens.Lens[OutboundCommand] = @lens.root()
  .custom("command")
```

An explicit failure is a compatibility adapter for the combined `custom` bound, not a usable wire contract. If the unsupported direction can be reached by ordinary application flow or untrusted input, redesign the boundary before using `custom`.

The library also provides `Lens[Json]::decode_from_json` as a direct bridge for a type that only implements `FromJson`. Under this skill's recommended typed-boundary policy, do not select a raw `Json` lens solely to avoid implementing `ToJson`; reserve that bridge for an already-justified raw-JSON boundary such as a dynamic or schema-less section.

Use a raw lens only for a truly untyped value and document the exception:

```moonbit
///| Raw JSON is intentional because provider-defined metadata has no stable schema.
let provider_metadata_lens : @lens.Lens[Json] = @lens.root().json("metadata")
```

## Standard FromJson Boundary

Translate selection failures to `@json.JsonDecodeError` inside a manual `FromJson` implementation.

```moonbit
///|
let request_name_lens : @lens.Lens[String] = @lens.root().string("name")

///|
let request_note_lens : @lens.PresenceLens[String] = @lens.root()
  .string("note")
  .nullish()

///|
struct Request {
  name : String
  note : String?
}

///|
impl @json.FromJson for Request with fn from_json(json, path) {
  let name = request_name_lens.get_or_json_decode_error(json, path)
  let note = request_note_lens.get_or_json_decode_error(json, path)
  { name, note }
}
```

Use `lens.add_to_json_path(path)` when passing a selected value to another path-aware decoder yourself. Use `lens.json_decode_error(path, message)` when validation fails specifically at the selected path. `Lens[Json]::decode_from_json` remains available for an intentional raw-JSON exception, but it is not a substitute for pairing `FromJson` and `ToJson` on a stable type.

## Typed Construction and ToJson

Use `set_or_abort` in `ToJson::to_json` because the trait cannot raise `@lens.JsonBuildError`; a path conflict means the static serializer schema is inconsistent.

```moonbit
///|
let request_output_name_lens : @lens.Lens[String] = @lens.root().string("name")

///|
let request_output_note_lens : @lens.PresenceLens[String] = @lens.root()
  .string("note")
  .nullish()

///|
impl ToJson for Request with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  request_output_name_lens.set_or_abort(builder, self.name)
  request_output_note_lens.set_or_abort(builder, self.note)
  builder.to_json()
}
```

Use `set` instead when construction is an ordinary fallible operation and the caller can handle `@lens.JsonBuildError`. Missing object parents are created, later writes replace earlier writes at the same path, and a failed path conflict leaves the builder unchanged.

## Presence Semantics

Choose the policy from the wire contract, not from the MoonBit type alone.

| Selected leaf | Required | `nullable()` | `optional()` | `nullish()` |
| --- | --- | --- | --- | --- |
| Missing | error | error | `None` | `None` |
| JSON `null` | type error | `None` | type error | `None` |
| Typed value | value | `Some(value)` | `Some(value)` | `Some(value)` |

On write, `nullable(None)` emits JSON `null`, `optional(None)` omits or removes the property, and `nullish(None)` omits it by default. Pass `encode_mode=@lens.NullishEncodeMode::Null` to `nullish` when `None` must emit JSON `null`.

Presence combinators replace one another. For example, `nullable().optional()` has optional semantics, while `optional().nullable()` has nullable semantics.

`PresenceLens::array()` applies nullable semantics to each item so `None` preserves its index as JSON `null`. Apply `optional()` after `array()` when the entire array property may be absent:

```moonbit
let nullable_items : @lens.Lens[Array[String?]] = @lens.root()
  .string("items")
  .nullable()
  .array()

let optional_array : @lens.PresenceLens[Array[String]] = @lens.root()
  .string("items")
  .array()
  .optional()
```

A missing intermediate object remains an error for every presence policy.

## Aggregate Validation

Pass heterogeneous typed lenses as `&LensTrait` values. Validation runs every check and preserves input order.

```moonbit
match @lens.validate(document, [request_name_lens, request_note_lens]) {
  @lens.Valid => {
    let name = request_name_lens.get(document)
    let note = request_note_lens.get(document)
    use_request(name, note)
  }
  @lens.Invalid(issues) => report_issues(issues)
}
```

`Valid` carries no decoded value and `Invalid` carries a `ReadOnlyArray[@lens.Issue]`; validation does not construct an application object.

## Deferred Lens Initialization

Top-level eager lenses are the simplest default. When measurements show that constructing a large set of lenses contributes materially to startup time, group lenses by independent first-use boundary and wrap each group in a top-level `@lazy.Lazy` value:

```moonbit
///|
struct UserLenses {
  name : @lens.Lens[String]
  age : @lens.Lens[Int]
}

///|
let user_lenses : @lazy.Lazy[UserLenses] = @lazy.Lazy(() => {
  let user = @lens.object("user")
  UserLenses::{
    name: user.string("name"),
    age: user.int("age"),
  }
})

///|
fn read_user(document : Json) -> (String, Int) raise @lens.LensError {
  let lenses = user_lenses.force()
  (lenses.name.get(document), lenses.age.get(document))
}
```

Import `"moonbitlang/core/lazy"` in the consuming `moon.pkg` when using this pattern.

Lazy initialization can reduce startup work only when some groups are not forced during startup. The first `force()` pays that group's construction cost, and later calls reuse the cached value. Do not wrap every lens separately or introduce `Lazy` when every group is immediately forced; that adds indirection without deferring useful work.

`@lazy.Lazy` is not thread-safe. Protect every cross-thread access with external synchronization, or keep the lazy cell thread-local; pre-forcing alone does not make the cell safe to share.

## Error and Scope Checklist

- `Lens::get` and `PresenceLens::get` raise `@lens.LensError` containing an RFC 6901 pointer and structured issue code.
- JSON boundary helpers raise standard `@json.JsonDecodeError` and preserve the incoming path.
- `ObjectLens::custom` is the default for stable application types; a raw `Json` lens needs a nearby rationale comment.
- Types used with `custom` implement both `FromJson` and `ToJson`, even when an unsupported direction can only fail explicitly because of the combined trait bound.
- An explicitly failing trait direction is documented, unreachable from externally triggerable generic trait calls, and excluded from round-trip expectations.
- `Lens::set` and `PresenceLens::set` raise `@lens.JsonBuildError` on output path conflicts.
- `JsonBuilder` creates new output JSON; lenses do not mutate or copy an existing source document.
- The current API traverses object properties and decodes arrays as a whole; it does not expose arbitrary array-index traversal.
- Startup-sensitive lens groups use `@lazy.Lazy` only after measurement and only across independent first-use boundaries.
