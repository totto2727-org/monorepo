# MoonBit Visibility and Construction

> Document type: concrete MoonBit implementation guidance.

## Package surface

Keep package-level functions minimal. Prefer type-associated functions whenever a natural owning type exists, even when a free function would be shorter or more DSL-like. Use a package-level function only when no single type owns the operation. Do not keep aliases that merely shorten a type-associated operation.

## Structs

Declare structs as `pub` by default and expose one canonical `TypeName::TypeName` constructor. Use `pub(all)` only when direct external struct literals are an intentional API requirement, and document that requirement next to the declaration.

## Enums and suberrors

An enum or suberror may use `pub(all)` when its variants only wrap primitive values or structs and every representable value is valid without validation, normalization, or cross-value rules. Construct these values directly with `TypeName::VariantName`.

Declare the type as `pub` when valid construction follows any rule. Expose only the allowed construction paths as type-associated functions with snake_case names, such as `Number::plus(value)`, rather than package-level wrapper functions.

## Open extension

Use `extenum` only when an existing open union must be extended and an ordinary enum, trait, or closed wrapper cannot express the required integration.

Declare traits as `pub` by default. Use `pub(open)` only when downstream packages must provide implementations, and document that requirement next to the trait.

## Tests

Do not widen type or trait visibility for test convenience. Use the production constructor or factory, or move implementation-detail tests to white-box scope.
