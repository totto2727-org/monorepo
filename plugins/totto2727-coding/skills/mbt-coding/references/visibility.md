# MoonBit Visibility and Construction

> Document type: concrete MoonBit implementation guidance.

## Package surface

Keep package-level functions minimal. Prefer type-associated functions whenever a natural owning type exists, even when a free function would be shorter or more DSL-like. Use a package-level function only when no single type owns the operation. Do not keep aliases that merely shorten a type-associated operation.

## Structs

Declare structs as `pub` by default and expose one canonical `TypeName::TypeName` constructor. Use `pub(all)` only when direct external struct literals are an intentional API requirement, and document that requirement next to the declaration.

A `pub struct` already exposes its non-`priv` fields for readonly access outside the defining package. Read immutable state directly through those fields. Do not add a method that only returns one field unchanged; a getter such as `Repository::owner() -> Owner { self.owner }` duplicates the field surface without adding validation, conversion, ownership isolation, or behavior.

Do not declare a type or struct field with `priv` by default. Use `priv` only when the hidden representation enforces a concrete boundary, such as preventing aliases from mutating an internal `Array` or `Map`, or supporting a trait-based abstraction whose representation must not become part of the public contract. State the reason next to the declaration or in the owning reference. Validation alone is not a reason to hide immutable fields: keep the canonical constructor as the construction boundary and expose the resulting readonly fields directly.

Add a field-specific update method when direct property replacement would be cumbersome or would bypass validation. Use `with_<field>` for an immutable value that returns a reconstructed value, and route the replacement through the canonical constructor. Use `set_<field>` only when the type contract intentionally includes in-place mutation. Add update methods for real callers, not speculatively.

## Enums and suberrors

An enum or suberror may use `pub(all)` when its variants only wrap primitive values or structs and every representable value is valid without validation, normalization, or cross-value rules. Construct these values directly with `TypeName::VariantName`.

Declare the type as `pub` when valid construction follows any rule. Expose only the allowed construction paths as type-associated functions with snake_case names, such as `Number::plus(value)`, rather than package-level wrapper functions.

## Open extension

Use `extenum` only when an existing open union must be extended and an ordinary enum, trait, or closed wrapper cannot express the required integration.

Declare traits as `pub` by default. Use `pub(open)` only when downstream packages must provide implementations, and document that requirement next to the trait.

## Tests

Do not widen type or trait visibility for test convenience. Use the production constructor or factory, or move implementation-detail tests to white-box scope.
