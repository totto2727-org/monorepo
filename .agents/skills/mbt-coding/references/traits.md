# MoonBit Traits

> Document type: concrete MoonBit implementation guidance.

## Contract ownership

Define a trait in the package that owns the behavior contract, not in each implementing package. Keep the required surface minimal so implementations do not depend on unrelated capabilities.

## Default methods

Provide a default method when its behavior follows entirely from other trait methods and the derived behavior is valid for every implementation. Override it only when the type has a materially better implementation or a stricter invariant.

## Delegation

When a wrapper or variant has the same semantics as an inner value, pattern match once and delegate to the inner implementation. Implement behavior directly when delegation would create a dependency cycle or change the contract.

## Trait objects

Use a trait object only when runtime heterogeneity is required. Prefer generic trait bounds when the concrete type can remain known to the caller.
