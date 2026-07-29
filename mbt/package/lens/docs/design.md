# Typed JSON Lens and Validation for MoonBit

## Status

This document is the reviewed design direction for a future `lens` package.

The proposal is viable after the corrections recorded below. Its primary public abstraction is `Lens[T]`. The first release exposes only the read side, while the name deliberately reserves a future lawful `set` and `modify` API.

This review targets MoonBit 0.10.4 and `moonbitlang/core` 0.10.4.

## Decision summary

- Start with a read-only typed JSON lens and validation library.
- Model a lens as a package-owned JSON Pointer plus a value decoder.
- Use `Lens[T]` for the public typed abstraction and `ObjectLens` for paths that may create child property lenses.
- Keep the package's pointer representation independent from `@json.JsonPath`.
- Raise `LensError` from one lens and return a non-generic `Validation` from aggregate checks.
- Preserve missing properties and explicit JSON `null` as different states.
- Keep all static result types on `Lens[T]`; validation only reports success or accumulated issues.
- Erase a lens's result type explicitly with `Lens::check` when composing heterogeneous validation checks.
- Start with object properties and primitive decoders.
- Delegate numeric parsing and conversion to MoonBit core APIs; do not maintain a package-specific number parser.
- Add optionality, arrays, refinements, transformations, and alternatives only after the foundation is stable.
- Do not promise JSON Schema or OpenAPI generation from opaque decoder closures.
- Reserve `set` and `modify` for a later milestone with explicit write policies and lens-law tests.
- Do not add value construction, type inference, or mutation operations to the validation API.

## Problem statement

MoonBit's standard `Json` type represents JSON values and its `FromJson` trait decodes a complete value into a MoonBit type. This package addresses a different use case: repeatedly selecting known locations from one JSON document, decoding each selected value, and optionally collecting all independent failures into one validation result.

The core model is:

```text
Lens[T]
├── location: Pointer
└── value interpretation: Decoder[T]
```

The first release is deliberately not a general JSON query language, a complete Haskell lens implementation, or a replacement for `FromJson` derivation. It establishes the read side of a future JSON lens while keeping mutation out of the initial scope.

## Review findings that change the original proposal

### Retain `Lens` as the public abstraction

A conventional lens supports both reading and lawful updating. The first milestone implements only reading and decoding, but future `set` and `modify` operations are part of the intended design space.

The package and public type should therefore use `lens` and `Lens[T]`. The documentation must state clearly which operations are currently available so the name does not imply that mutation already exists.

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

`Lens[T]` is the source of static type information. Aggregate validation explicitly erases each result type to `Check`, evaluates all checks, and returns only success or accumulated issues. After successful validation, callers continue to read values through their original typed lenses.

This deliberately means that validation followed by access performs traversal and decoding again. Avoiding that duplication would require a heterogeneous typed cache or generated application-specific code, neither of which belongs in the initial package.

### Delegate numeric conversion to MoonBit core

The package should own JSON traversal, type selection, and structured error mapping, but it should not own decimal, exponent, sign, overflow, or rounding algorithms.

For a `Json::Number`, use the `Double` value already produced by MoonBit core. Do not reparse its retained source text. Convert that value with standard methods such as `Double::to_int`, and use standard predicates, limits, and reverse conversions to validate the result.

If a later decoder accepts numeric text, delegate parsing to the current non-deprecated standard entry points such as `@string.from_str`, `@string.parse_double`, or `@string.parse_int`, then translate the raised standard error into `DecodeProblem`. The reviewed toolchain still exposes `@strconv.parse_*` as deprecated compatibility APIs; new package code should use their supported `@string` replacements.

Hand-written digit loops, regular expressions that duplicate a numeric grammar, and package-specific decimal or exponent parsers are out of scope. This avoids duplicating standard-library semantics and maintenance.

### Design presence semantics before exposing optionality

Missing and `null` are distinct:

| Input state | Required string | Optional string | Nullable string | Optional nullable string |
|---|---:|---:|---:|---:|
| Missing | error | `None` | error | `None` |
| `null` | type error | type error | `None` | `None` |
| String | value | `Some(value)` | `Some(value)` | `Some(value)` |

Do not implement optional nullable values as `lens.optional().nullable()`. Both operations change the output to an option, so naive chaining produces nested option types or ambiguous semantics. Use three explicit combinators:

```moonbit
lens.optional()
lens.nullable()
lens.optional_nullable()
```

These operations are deferred until their exact MoonBit signatures are compiled and tested.

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

A validator composed only from independent `Check` closures does not know the complete set of allowed properties for an object. Consequently, rejecting unknown fields cannot be added correctly as a simple option on the initial aggregate validator.

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
  priv decode_ : (Json) -> T raise DecodeProblem
}
```

`DecodeProblem` is a package-private suberror containing path-independent failure information. `Lens::get` catches it, attaches the selected pointer to produce a public `Issue`, and raises `LensError(issue)`.

Primitive decoders should perform JSON variant dispatch directly so the package can provide stable structured error codes. Numeric parsing and conversion inside those decoders must delegate to MoonBit core. A later `Decoder::from_json[T : FromJson]` bridge may catch `JsonDecodeError`, but it should classify the failure as an external decode failure because core's human-readable message is not a stable structured error code.

### Object lens

`ObjectLens` represents a location from which child properties may be declared.

```moonbit
pub struct ObjectLens {
  priv pointer : Pointer
}
```

It prevents invalid APIs such as creating a child string property from a `Lens[String]`.

### Typed lens

```moonbit
pub struct Lens[T] {
  priv pointer : Pointer
  priv decoder : Decoder[T]
}
```

`Lens::get` performs two operations:

1. Traverse the document to the lens's pointer.
2. Decode the selected value with its decoder.

Traversal and decoding failures are normalized into the same public `Issue` value and raised as `LensError`.

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

pub fn Lens::get[T](
  Self[T],
  Json,
) -> T raise LensError
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
  InvalidInteger
  NumberOutOfRange(
    target~ : String,
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

Accept only `Json::Number` values that can be represented by the selected MoonBit target.

The phase 1 `number` decoder returns the `Double` already stored by `Json::Number`. It does not inspect or reparse the retained textual representation. Use the standard `Double::is_nan` and `Double::is_inf` predicates to reject non-finite results with `NumberOutOfRange`.

### Integer

JSON has a number type, not a distinct integer type. The `int` decoder starts from the `Double` already stored by `Json::Number` and uses standard conversions:

1. Reject `Double::is_nan()` and `Double::is_inf()`.
2. Compare against `@int.MIN_VALUE.to_double()` and `@int.MAX_VALUE.to_double()` to classify out-of-range values.
3. Convert with `Double::to_int()`.
4. Convert the resulting `Int` back with `Int::to_double()` and require equality with the original value. A mismatch identifies a fractional or otherwise non-exact conversion.

This sequence relies on MoonBit's standard saturation, truncation, and representation behavior while preserving the package's `InvalidInteger` and `NumberOutOfRange` classifications. The package must not parse the JSON number text itself.

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
pub struct Check {
  priv run_ : (Json) -> Unit raise LensError
}

pub fn Lens::check[T](Self[T]) -> Check

pub fn validate(
  Json,
  Array[Check],
) -> Validation
```

`Check` is the intentional type-erasure boundary. It runs a lens's traversal and decoder, discards the successful value, and preserves a raised `Issue` for aggregation.

```moonbit
let user = object("user")
let name_lens = user.string("name")
let age_lens = user.int("age")

match validate(document, [name_lens.check(), age_lens.check()]) {
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

| Policy | Behavior |
|---|---|
| `strict` | Reject undeclared keys. |

`strip_unknown` and `passthrough` are transformation policies, not validation policies. If they are ever needed, they require a separate API with an explicit transformed output and must not change the meaning of `Validation`.

## Mutation is deferred, not excluded

Phase 1 does not provide `set` or `modify`.

The `Lens` name is retained because lawful mutation may be added later. Before exposing writes, the design must resolve:

- Whether missing intermediate objects are created.
- Whether updates are persistent or in place.
- How an out-of-bounds array index behaves.
- How optional and nullable lenses interact with writes.

If mutation is implemented, `get`, `set`, and `modify` should remain operations on the same `Lens[T]` abstraction. The internal write implementation may live in separate source files, while `Check` and `Validation` remain validation-only.

For every successfully traversable source, tests should cover the standard lens laws:

```text
get(set(source, value)) = value
set(source, get(source)) = source
set(set(source, first), second) = set(source, second)
```

Failure behavior for missing or incompatible paths is part of the API contract and must be specified before these laws are applied.

## Delivery roadmap

### Milestone 1: Selection foundation

- Opaque `Pointer` with RFC 6901 rendering.
- `JsonKind`, `IssueCode`, `Issue`, and `LensError`.
- Key-only lookup with exact failure locations.
- `Decoder[T]`, `ObjectLens`, and `Lens[T]`.
- String, boolean, number, integer, and raw JSON decoders.
- `Lens::get`.

Exit criteria:

- Public examples compile.
- Primitive success and failure behavior is tested.
- Every traversal failure reports the exact failing pointer.
- Fractional and out-of-range integer cases are covered.
- Numeric tests exercise the boundaries of the delegated standard conversions rather than a package-specific parser.

### Milestone 2: Aggregate validation

- Non-generic `Validation`.
- Type-erased `Check`.
- `Lens::check` and aggregate `validate`.
- Deterministic error ordering.
- Refinement with stable constraint codes.

Exit criteria:

- Every check is evaluated once per validation call.
- Multiple independent field issues are returned together.
- Successful validation returns `Valid` without constructing or caching typed values.
- Callers continue to access successfully validated data through their original `Lens[T]` values.

### Milestone 3: Presence and collections

- `optional`, `nullable`, and `optional_nullable`.
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

### Future milestone: Lawful mutation

- `Lens::set`.
- `Lens::modify`.
- Explicit missing-path, incompatible-path, and array-index write policies.
- A documented choice between persistent and in-place updates.
- Lens-law tests for every writable lens category.

This milestone is optional until a real caller requires mutation, but the public naming and internal pointer model must not prevent it.

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
    ├── lens.mbt
    └── lookup.mbt
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
- Non-finite or unrepresentable number.
- Fractional value passed to `int`.
- Positive and negative `Int` overflow.
- Exact `@int.MIN_VALUE` and `@int.MAX_VALUE` conversion.
- Standard numeric conversion failures mapped to stable `IssueCode` values.
- Explicit `null` passed to every primitive decoder.
- JSON Pointer escaping for `~`, `/`, and the empty key.
- Correct pointer for every traversal and decoding failure.
- Reusing one lens against multiple documents.

## Deferred decisions

The following choices do not block milestone 1 and should be resolved with implementation evidence:

- Whether `Issue`, `IssueCode`, `JsonKind`, and the payload of `LensError` should be fully public or read-only.
- Whether `Pointer` should expose its segments or only iteration and string conversion.
- Whether array item validation accumulates failures by default or exposes both accumulating and fail-fast modes.
- Whether a `FromJson` bridge is useful enough despite its less structured error classification.
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
