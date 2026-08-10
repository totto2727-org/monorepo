# Typed JSON Lens, Builder, and Validation for MoonBit

## Status

This document records the reviewed design and implemented direction of the `lens` package.

The primary public abstraction is `Lens[T]`. A lens reads typed values from an existing `Json` document and writes typed values to a separate `JsonBuilder`. Builder writes construct outbound JSON and do not mutate or persistently update an input document.

This review targets MoonBit 0.10.4 and `moonbitlang/core` 0.10.4.

## Decision summary

- Provide typed JSON access, builder construction, and aggregate validation.
- Model a lens as a package-owned JSON Pointer plus a value decoder and encoder.
- Use `Lens[T]` for typed values and `ObjectLens` for typed object values and paths that may create child property lenses.
- Keep the package's pointer representation independent from `@json.JsonPath`.
- Raise `LensError` from one lens and return a non-generic `Validation` from aggregate checks.
- Preserve missing properties and explicit JSON `null` as different states.
- Keep static result types on `Lens[T]` and `ObjectLens`; validation only reports success or accumulated issues.
- Use a check-only `LensTrait` trait object to erase concrete lens types only at the aggregate validation boundary.
- Start with object properties and primitive decoders.
- Delegate numeric parsing and conversion to MoonBit core APIs; do not maintain a package-specific number parser.
- Build outbound objects through a mutable `JsonBuilder` that implements `ToJson`.
- Define `Lens::set` as a builder-targeted write that creates missing object parents and never updates an existing JSON document.
- Add optionality, arrays, refinements, transformations, and alternatives only after the foundation is stable.
- Do not promise JSON Schema or OpenAPI generation from opaque decoder closures.
- Keep source-document mutation outside the builder API and validation API.
- Do not add value construction, type inference, or mutation operations to the validation API.

## Problem statement

MoonBit's standard `Json` type represents JSON values, its `FromJson` trait decodes a complete value into a MoonBit type, and its `ToJson` trait encodes a complete value. This package addresses two related use cases: repeatedly selecting known locations from one JSON document, and reusing those typed locations to construct an outbound JSON object without hand-maintaining a `Map[String, Json]` inside each caller.

The core model is:

```text
ObjectLens
└── object accessor: Lens[Map[String, Json]]

Lens[T]
├── location: Pointer
├── value interpretation: Decoder[T]
└── output encoding: Encoder[T]

JsonBuilder
└── generated object path tree
```

The package is deliberately not a general JSON query language, a complete Haskell lens implementation, or a replacement for `FromJson` and `ToJson` derivation. Builder writes reuse lens pointers and typed encoders, while source-document mutation remains out of scope.

## Review findings that change the original proposal

### Retain `Lens` as the shared typed location

A conventional lens supports both reading and lawful updating. This package instead reuses one typed location for input decoding and output construction. `Lens::set` targets a mutable `JsonBuilder`, so it is a builder setter rather than a source-document update.

The package and public type retain `lens` and `Lens[T]`, while the method signature and documentation make the target explicit. Existing JSON documents remain immutable from the package's perspective.

### Own the pointer representation

The current `@json.JsonPath` interface exposes an abstract `JsonPath` type and append methods, but it does not expose a public root constructor. It is designed primarily for `FromJson` and `JsonDecodeError`.

The package therefore needs its own opaque `Pointer` type. It should render as an RFC 6901 JSON Pointer and expose only safe construction and inspection operations. Depending on `@json.JsonPath` would otherwise prevent the package from constructing a root path and would couple the public error model to core internals.

### Report the location where traversal failed

A lookup must track both the requested pointer and the successfully traversed prefix.

For a request for `/user/profile/name`:

- If `name` is absent, report `/user/profile/name`.
- If `profile` is a string, report a type mismatch at `/user/profile`.
- If `user` is absent, report `/user`.

Reporting the full requested pointer for every failure would misidentify intermediate type errors.

### Separate raised errors from validation data

`Lens::get` should raise a package-specific `LensError` rather than return `Result`. The error carries one `Issue`, which remains a plain structured value so aggregate validation can retain many issues without using exceptions as a collection.

This separation gives each type one role:

- `LensError` is the typed control-flow boundary used by `raise` and `catch`.
- `Issue` is inspectable diagnostic data containing a pointer, stable code, and optional message.

The name `CustomError` is too generic for a public package API. `LensError(Issue)` identifies both the owning abstraction and the reusable diagnostic payload.

### Keep static types on lenses

MoonBit cannot derive a compile-time result type from a runtime collection of validation definitions in the way TypeScript libraries can infer a type from a Zod schema expression. The validation API must not imitate that model with `Schema[T]`, fixed-arity builders, or a value-producing validation result.

`Lens[T]` is the source of static type information for primitive and raw JSON values. `ObjectLens` owns a `Lens[Map[String, Json]]`, so it also provides statically typed object access. Aggregate validation accepts both through the check-only `LensTrait` trait object, evaluates all checks, and returns only success or accumulated issues. Callers do not perform an explicit conversion. After successful validation, they continue to read values through their original lenses.

This deliberately means that validation followed by access performs traversal and decoding again. Avoiding that duplication would require a heterogeneous typed cache or generated application-specific code, neither of which belongs in the initial package.

### Delegate numeric conversion to MoonBit core

The package should own JSON traversal, type selection, and structured error mapping, but it should not own decimal, exponent, sign, overflow, or rounding algorithms.

For a `Json::Number`, use the `Double` value already produced by MoonBit core. Do not reparse its retained source text. When an `Int` is requested, delegate directly to `Double::to_int()` and inherit its standard conversion behavior without package-level validation.

If a later decoder accepts numeric text, delegate parsing to the current non-deprecated standard entry points such as `@string.from_str`, `@string.parse_double`, or `@string.parse_int`, then translate the raised standard error into `DecodeProblem`. The reviewed toolchain still exposes `@strconv.parse_*` as deprecated compatibility APIs; new package code should use their supported `@string` replacements.

Hand-written digit loops, regular expressions that duplicate a numeric grammar, and package-specific decimal or exponent parsers are out of scope. This avoids duplicating standard-library semantics and maintenance.

### Design presence semantics before exposing optionality

Missing and `null` are distinct:

| Input state | Required string | Optional string | Nullable string | Optional nullable string |
| ----------- | --------------: | --------------: | --------------: | -----------------------: |
| Missing     |           error |          `None` |           error |                   `None` |
| `null`      |      type error |      type error |          `None` |                   `None` |
| String      |           value |   `Some(value)` |   `Some(value)` |            `Some(value)` |

Applying a presence combinator produces `PresenceLens[T]`, whose decoded and encoded value type is `T?`. Applying another presence combinator replaces the policy without nesting the option type. The last call determines both missing-value and JSON `null` behavior:

```moonbit
lens.optional()
lens.nullable()
lens.nullish()
lens.optional().nullable() // equivalent to lens.nullable()
```

In particular, `optional().nullable()` and `nullish().nullable()` are nullable, not nullish: a missing property is an error, while JSON `null` decodes to `None` and `None` encodes as JSON `null`.

### Separate value alternatives from location fallback

An `or` operation is ambiguous. It can mean either:

- Try another decoder on the same selected JSON value.
- Try another location if the first lens fails.

The design must use separate names:

```text
Decoder::one_of2     alternatives for one value
Lens::or_else        fallback to another location, if this feature is needed
```

Only value alternatives belong to the initial validation roadmap.

### Unknown-field validation requires object metadata

A validator composed only from independent `LensTrait` checks does not know the complete set of allowed properties for an object. Consequently, rejecting unknown fields cannot be added correctly as a simple option on the initial aggregate validator.

Unknown-field validation must wait for an explicit object-check representation that records the object boundary and declared keys. `strip_unknown` and `passthrough` transform or return data, so they do not belong to a validation-only API.

### Schema generation requires declarative decoder metadata

Opaque predicate and transform closures cannot be translated reliably into JSON Schema or OpenAPI. Pointer and decoder separation improves implementation structure, but it is not sufficient for schema generation.

Schema generation is a non-goal unless a later design introduces a declarative constraint model.

## Architecture

### Pointer

`Pointer` is an opaque package type. Internally it stores ordered path segments.

```moonbit
priv enum PointerSegment {
  Key(String)
  Index(Int)
}

pub struct Pointer {
  priv segments : Array[PointerSegment]
}
```

Only key traversal is exposed in phase 1. Index traversal becomes public with array support.

The string form follows RFC 6901:

- Root renders as an empty string.
- A key appends `/key`.
- `~` is escaped as `~0`.
- `/` is escaped as `~1`.
- An array index appends its decimal representation.

### Decoder

`Decoder[T]` interprets one already-selected JSON value. It does not perform document traversal.

```moonbit
pub struct Decoder[T] {
  priv decode_ : (Json, JsonPath?) -> T raise DecodeProblem
}
```

Every decoder receives a required optional path. `Lens::get` passes `None`; JSON decoding entry points pass `Some(selected_path)`. `DecodeProblem` is a package-private suberror that preserves either a structured lens failure or a standard `JsonDecodeError`. `Lens::get` converts it into a public `Issue`, while `get_or_json_decode_error` returns the preserved standard error or translates the structured failure at the selected path.

Primitive decoders perform JSON variant dispatch directly so the package can provide stable structured error codes. Numeric parsing and conversion inside those decoders delegate to MoonBit core. `ObjectLens::custom[T : FromJson + ToJson]` delegates to standard `FromJson`, forwarding the optional selected `JsonPath` through the same decoder callback. Its ordinary `Lens::get` path reports a standard decoder failure as `ExternalDecode` at the selected lens pointer because `JsonPath` is opaque, while `get_or_json_decode_error` preserves the exact nested standard path. Array and presence combinators forward the optional path through that single callback. `ObjectLens::json` remains the raw `Json` accessor, and `Lens[Json]::decode_from_json` remains a read-only bridge for types without `ToJson`.

### Encoder

`Encoder[T]` converts a typed value into one concrete JSON value. Primitive encoders delegate to MoonBit core JSON constructors, while a custom lens delegates to standard `ToJson`. Property omission belongs to `PresenceLens::set` rather than `Encoder`. JSON arrays cannot contain a missing element without shifting later indices, so `PresenceLens::array` normalizes every presence mode to nullable item semantics for both encoding and decoding.

Presence combinators have explicit builder behavior:

| Lens                        | `Some(value)`     | `None`             |
| --------------------------- | ----------------- | ------------------ |
| `nullable`                  | Encode the value. | Write JSON `null`. |
| `optional`                  | Encode the value. | Omit the property. |
| `nullish()`                 | Encode the value. | Omit the property. |
| `nullish(encode_mode=Null)` | Encode the value. | Write JSON `null`. |

`NullishEncodeMode` makes the outbound representation explicit when JSON `null` is required, while defaulting to omission. The implementation selects the existing optional or nullable encoder instead of maintaining a separate nullish encoder.

### JSON builder

`JsonBuilder` is a mutable outbound-object builder whose internal nodes distinguish encoded JSON leaves from generated object parents. `Lens::set` walks its package-owned pointer, creates missing object parents, and writes the encoded leaf. Writing the same pointer again replaces its value. An encoded leaf used as an intermediate node raises `JsonBuildError` at the exact conflicting pointer.

`optional(None)` removes an earlier value at the same pointer and prunes empty generated parents. `BuildNode` implements `ToJson`; generated object nodes delegate directly to `Map[String, BuildNode]::to_json`, while encoded leaves pass through unchanged. Every conversion creates fresh maps for generated object nodes, so later builder writes cannot mutate an earlier result.

### Current composition constraints and future directions

The current API does not own a schema registry, so independently declared lenses may resolve to the same property without a declaration-time error. Repeated writes to the exact same pointer use the latest value, while writing through a child pointer after its parent has become an encoded leaf raises `JsonBuildError(PathConflict)`. Callers should treat one typed lens as the canonical definition of each known property. A future declarative layer may detect duplicate property definitions or require an explicit override policy before construction begins.

Presence combinators use a normalized last-call-wins policy. Repeating or mixing `nullable`, `optional`, and `nullish` keeps the type as `PresenceLens[T]` and replaces the earlier missing and `null` behavior instead of creating nested options.

An array can contain JSON values, including explicit `null`, but it cannot contain an omitted element. `PresenceLens::array` is therefore a normalization boundary: `primitive.optional().array()`, `primitive.nullable().array()`, and `primitive.nullish().array()` all decode JSON `null` as `None` and encode `None` as JSON `null`. The original property-level presence mode no longer applies after `array`, because an array item has no missing-property state. In contrast, `primitive.array().optional()` applies optionality to the entire array property.

The duplicate-path rule is a current composition constraint rather than a permanent exclusion. Any future support should preserve unambiguous JSON output, exact error pointers, and the distinction between omission and explicit `null`.

### Object lens

`ObjectLens` represents a typed object location from which child properties may be declared. It delegates traversal and object decoding to an internal `Lens[Map[String, Json]]`. Object decoding copies the selected top-level map so mutations through the returned map do not alter the source document; nested `Json` values retain their standard sharing semantics.

```moonbit
pub struct ObjectLens {
  priv lens : Lens[Map[String, Json]]
}
```

It returns the selected object through `ObjectLens::get` and prevents invalid APIs such as creating a child string property from a `Lens[String]`.

### Typed lens

```moonbit
pub struct Lens[T] {
  priv pointer : Pointer
  priv decoder : Decoder[T]
  priv encoder : Encoder[T]
}
```

`Lens::get` performs two operations:

1. Traverse the document to the lens's pointer.
2. Decode the selected value with its decoder.

Traversal and decoding failures are normalized into the same public `Issue` value and raised as `LensError`.

`Lens::set` encodes a value and writes it to a `JsonBuilder`. Encoding and construction failures are normalized into `JsonBuildIssue` and raised as `JsonBuildError` without changing the read-side `LensError` contract.

## Phase 1 public API

The exact declaration syntax must be confirmed during implementation, but the intended API surface is:

```moonbit
pub fn root() -> ObjectLens

pub fn object(String) -> ObjectLens

pub fn ObjectLens::object(
  Self,
  String,
) -> ObjectLens

pub fn ObjectLens::string(
  Self,
  String,
) -> Lens[String]

pub fn ObjectLens::bool(
  Self,
  String,
) -> Lens[Bool]

pub fn ObjectLens::number(
  Self,
  String,
) -> Lens[Double]

pub fn ObjectLens::int(
  Self,
  String,
) -> Lens[Int]

pub fn ObjectLens::json(
  Self,
  String,
) -> Lens[Json]

pub fn ObjectLens::custom[T : FromJson + ToJson](
  Self,
  String,
) -> Lens[T]

pub fn ObjectLens::get(
  Self,
  Json,
) -> Map[String, Json] raise LensError

pub fn Lens::get[T](
  Self[T],
  Json,
) -> T raise LensError

pub(all) enum NullishEncodeMode {
  Omit
  Null
}

pub fn Lens::nullish[T](
  Self[T],
  encode_mode? : NullishEncodeMode,
) -> PresenceLens[T]

pub fn JsonBuilder::JsonBuilder() -> JsonBuilder

pub impl ToJson for JsonBuilder

pub fn Lens::set[T](
  Self[T],
  JsonBuilder,
  T,
) -> Unit raise JsonBuildError
```

`object("user")` is a convenience alias for `root().object("user")`.

Example:

```moonbit
fn read_name(document : Json) -> String raise LensError {
  object("user").object("profile").string("name").get(document)
}

let name : String = read_name(document)
```

## Lookup semantics

Lookup proceeds from the root and records the traversed pointer after every successful segment.

Conceptually:

```text
lookup(document, requested_pointer)
  current = document
  traversed = root

  for segment in requested_pointer:
    if segment is a key:
      require current to be an object at traversed
      extend traversed with the key
      require the property to exist at traversed
      current = property value

    if segment is an index:
      require current to be an array at traversed
      extend traversed with the index
      require the index to exist at traversed
      current = array item

  return current
```

Phase 1 only constructs key segments, but the internal failure-location rule must already be covered by tests.

## Error model

Errors are structured data, not preformatted strings.

```moonbit
pub(all) enum JsonKind {
  Null
  Boolean
  Number
  String
  Array
  Object
}

pub(all) enum IssueCode {
  MissingProperty
  TypeMismatch(
    expected~ : JsonKind,
    actual~ : JsonKind,
  )
  IndexOutOfBounds(
    index~ : Int,
    length~ : Int,
  )
  ConstraintViolation(
    code~ : String,
  )
  ExternalDecode
}

pub(all) struct Issue {
  pointer : Pointer
  code : IssueCode
  message : String?
}

pub(all) suberror LensError {
  LensError(Issue)
}
```

The final visibility mode may be narrowed, but consumers must be able to inspect the pointer and code without parsing text.

The `message` field is optional diagnostic context. Program logic should branch on `IssueCode`, not on `message`.

The pointer already identifies a missing property, so the error does not need a redundant property-name field.

`Issue` is not itself a suberror. Keeping it as the payload of `LensError` allows `Validation::Invalid` to store `Array[Issue]` directly while callers of `Lens::get` still use MoonBit's typed error propagation.

## Primitive decoding semantics

### String

Accept only `Json::String`.

### Boolean

Accept only `Json::True` and `Json::False`.

### Number

Accept only `Json::Number`.

The phase 1 `number` decoder returns the `Double` already stored by `Json::Number` without finite or range validation. It does not inspect or reparse the retained textual representation.

### Integer

JSON has a number type, not a distinct integer type. The `int` decoder applies `Double::to_int()` directly to the `Double` already stored by `Json::Number`. It performs no finite, range, or integer-exactness validation and therefore inherits MoonBit's standard truncation, saturation, and special-value behavior. The package must not parse the JSON number text itself.

### Raw JSON

The `json` decoder always succeeds with the selected value.

## Why one lens raises `LensError`

MoonBit gives package-defined suberrors typed `raise` and `catch` behavior. `Lens::get` uses that native control flow so ordinary reads propagate one failure without forcing callers to unwrap a `Result`.

Aggregate validation remains value based. `validate` catches `LensError(issue)` independently for each check, retains the contained `Issue`, and returns every collected issue in `Validation::Invalid`. A failure from one check must not prevent evaluation of the other independent checks.

## Phase 2 aggregate validation

### Validation

```moonbit
pub enum Validation {
  Valid
  Invalid(Array[Issue])
}
```

`Invalid` must always contain at least one issue. The implementation should enforce this invariant through private construction helpers. A dedicated non-empty collection type is optional and should not be introduced solely for this invariant unless it improves the rest of the package.

`Validation` is readonly outside the package. Consumers can destructure it through pattern matching, but only this package can construct `Valid` or `Invalid`, which prevents external construction of `Invalid([])`.

`Valid` carries no decoded value. Validation establishes only that every supplied check succeeded for that invocation.

```moonbit
pub trait LensTrait {
  fn check(Self, Json) -> Unit raise LensError
}

pub impl[T] LensTrait for Lens[T]

pub impl LensTrait for ObjectLens

pub fn validate(
  Json,
  Array[&LensTrait],
) -> Validation
```

`LensTrait` is the intentional type-erasure boundary. It is readonly and sealed so only this package can define implementations. Its only method runs a lens's traversal and decoder, discards the successful value, and preserves a raised `Issue` for aggregation. MoonBit cannot express a type-parameterized trait object that retains each heterogeneous result type, so typed `get` remains on `Lens[T]` and `ObjectLens`.

```moonbit
let user = object("user")
let name_lens = user.string("name")
let age_lens = user.int("age")

match validate(document, [user, name_lens, age_lens]) {
  Valid => {
    let name : String = name_lens.get(document)
    let age : Int = age_lens.get(document)
    consume(name, age)
  }
  Invalid(issues) => report(issues)
}
```

The validator evaluates checks in array order and returns issues in the same deterministic order. It never constructs a MoonBit struct, tuple, enum, or other application value.

## Later combinators

### Refinement

Refinement keeps the decoded type and adds a value constraint:

```text
Decoder[T] + (T -> Bool) -> Decoder[T]
```

The public API should require a stable constraint code and may accept a diagnostic message.

### Transformation

Transformation changes the decoded type:

```text
Decoder[A] + (A -> B raise DecodeProblem) -> Decoder[B]
```

Transformations belong on `Decoder`, with forwarding conveniences on `Lens` only if they materially improve use.

### Arrays

Array support needs:

- A decoder for `Array[T]`.
- Item-level pointers containing indices.
- Minimum, maximum, and non-empty constraints.
- A clear choice between fail-fast item decoding and accumulation of all item issues.

The recommended default is to accumulate all independent item issues in index order, because the package already targets validation use cases.

### Value alternatives

`Decoder::one_of2` applies multiple decoders to the same selected value. If all alternatives fail, retain the failures grouped by alternative rather than flattening them into an indistinguishable list.

Different output types must be mapped into an explicit MoonBit enum before combination.

### Discriminated unions

A discriminated-union decoder should decode its discriminator once and select one homogeneous `Case[T]`. Every case must produce the same output type, usually an application enum, so the resulting `Lens[T]` remains statically typed.

This feature belongs to typed lens decoding, not to aggregate validation. It should be designed after ordinary object lenses exist because case selection needs an explicit object boundary.

### Unknown fields

Unknown-field rejection belongs to a future declarative object check:

| Policy   | Behavior                |
| -------- | ----------------------- |
| `strict` | Reject undeclared keys. |

`strip_unknown` and `passthrough` are transformation policies, not validation policies. If they are ever needed, they require a separate API with an explicit transformed output and must not change the meaning of `Validation`.

## Construction is separate from source mutation

`Lens::set` mutates only its `JsonBuilder` target. It does not accept an existing `Json`, so missing parents are unambiguously created as builder-owned object nodes and no source aliasing policy is required.

This builder contract deliberately replaces the previously proposed source-mutation milestone. If source-document updates are ever required, they need a separately named API with persistent-update policies and lens-law tests; they must not change the meaning of builder-targeted `Lens::set`.

## Delivery roadmap

### Milestone 1: Selection foundation

- Opaque `Pointer` with RFC 6901 rendering.
- `JsonKind`, `IssueCode`, `Issue`, and `LensError`.
- Key-only lookup with exact failure locations.
- `Decoder[T]`, `ObjectLens` backed by `Lens[Map[String, Json]]`, and `Lens[T]`.
- String, boolean, number, integer, and raw JSON decoders.
- `Lens::get`.

Exit criteria:

- Public examples compile.
- Primitive success and failure behavior is tested.
- Every traversal failure reports the exact failing pointer.
- Fractional, out-of-range, and non-finite integer cases follow `Double::to_int()` semantics.
- Numeric tests exercise the boundaries of the delegated standard conversions rather than a package-specific parser.

### Milestone 2: Aggregate validation

- Non-generic `Validation`.
- Check-only `LensTrait` implemented by `Lens[T]`, `PresenceLens[T]`, and `ObjectLens`.
- Trait-object aggregate `validate`.
- Deterministic error ordering.
- Refinement with stable constraint codes.

Exit criteria:

- Every check is evaluated once per validation call.
- Multiple independent field issues are returned together.
- Successful validation returns `Valid` without constructing or caching typed values.
- Callers continue to access successfully validated data through their original `Lens[T]` values.

### Milestone 3: Presence and collections

- `optional`, `nullable`, and `nullish`.
- `default`, applied to missing values only by default.
- Array item decoding with indexed pointers.
- Array length constraints.
- Transformation.

Exit criteria:

- The missing/null truth table is covered.
- Array issue ordering is deterministic.
- Defaults never hide explicit `null` or invalid present values.

### Milestone 4: Alternatives and object checks

- `Decoder::one_ofN`.
- Discriminated unions.
- Declarative object boundaries.
- Unknown-field rejection.

JSON Schema and OpenAPI generation remain separate proposals that require declarative metadata for every supported constraint.

### Milestone 5: Typed output construction

- `Encoder[T]` paired with every supported decoder.
- Mutable `JsonBuilder` implementing `ToJson`.
- Builder-targeted `Lens::set` with generated object parents.
- Explicit optional omission, nullable null, and configurable nullish behavior.
- Structured failures for path conflicts and unrepresentable omissions.

Exit criteria:

- Primitive, array, optional, and nullable values produce the documented JSON output.
- Repeated writes use the latest value.
- Optional removal prunes empty generated parents.
- Path and encoding failures report exact pointers without partially changing the builder.
- JSON produced before a later builder write remains unchanged.

## Initial package layout

Keep the first implementation small:

```text
lens/
├── docs/
│   ├── design.md
│   └── design.ja.md
└── src/
    ├── pointer.mbt
    ├── issue.mbt
    ├── decoder.mbt
    ├── encoder.mbt
    ├── lens.mbt
    ├── lookup.mbt
    └── builder.mbt
```

Add `check.mbt` and `validation.mbt` in milestone 2. Add files for optionality, arrays, and alternatives only when those features are implemented.

## Test matrix for milestone 1

- Root property success.
- Nested property success.
- Missing root property.
- Missing intermediate property.
- Missing leaf property.
- Non-object root for a key lens.
- Non-object intermediate value.
- String type mismatch.
- Boolean type mismatch.
- Number type mismatch.
- Non-finite number passed through by `number`.
- Fractional value converted by `Double::to_int()`.
- Positive and negative overflow saturated by `Double::to_int()`.
- Non-finite values converted by `Double::to_int()`.
- Exact `@int.MIN_VALUE` and `@int.MAX_VALUE` conversion.
- Explicit `null` passed to every primitive decoder.
- JSON Pointer escaping for `~`, `/`, and the empty key.
- Correct pointer for every traversal and decoding failure.
- Reusing one lens against multiple documents.

## Deferred decisions

The following choices do not block milestone 1 and should be resolved with implementation evidence:

- Whether `Issue`, `IssueCode`, `JsonKind`, and the payload of `LensError` should be fully public or read-only.
- Whether `Pointer` should expose its segments or only iteration and string conversion.
- Whether array item validation accumulates failures by default or exposes both accumulating and fail-fast modes.
- Whether additional read-only bridges are useful without expanding `Lens[T]`'s encoder contract.
- Whether future writes use persistent or in-place updates.
- Whether a missing intermediate object is an error or may be created by an explicit write policy.
- How optional and nullable lenses behave when a write targets a missing or `null` value.

## References

- [MoonBit method and trait documentation](https://docs.moonbitlang.com/en/stable/language/methods.html)
- [MoonBit error handling documentation](https://docs.moonbitlang.com/en/stable/language/error-handling.html)
- [MoonBit deriving documentation](https://docs.moonbitlang.com/en/stable/language/derive.html)
- [MoonBit core JSON API](https://mooncakes.io/docs/moonbitlang/core/json)
- [MoonBit core string parsing API](https://mooncakes.io/docs/moonbitlang/core/string)
- [MoonBit `Double::to_int` implementation and semantics](https://mooncakes.io/assets/moonbitlang/core/builtin/double_to_int_wasm.mbt.html)
- [MoonBit core API index](https://mooncakes.io/docs/moonbitlang/core/)
- [RFC 6901: JSON Pointer](https://www.rfc-editor.org/rfc/rfc6901)
