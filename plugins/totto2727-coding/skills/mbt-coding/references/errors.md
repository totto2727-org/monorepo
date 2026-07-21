# MoonBit Errors

> Document type: concrete MoonBit implementation guidance.

## Failure boundary

Use the `raise` effect for synchronous operations that may fail. Declare the narrowest error type that callers can act on; use an open `raise` effect only when the function intentionally forwards heterogeneous failures.

Use a typed `suberror` when callers need to distinguish failure cases or inspect structured context. Use `fail(...)` for a generic failure that has no recoverable domain variants.

Use `Result` only when failure must be a value in the API contract, such as storage, deferred inspection, or composition with an API that consumes `Result`. Otherwise, prefer the typed `raise` effect so the signature exposes failure without manual success and failure plumbing.

## Structured payloads

Keep machine-usable context in typed fields. Do not flatten paths, JSON values, identifiers, or nested failures into a message string merely because they cross an error boundary.

```mbt check
suberror ConfigError {
  ConfigNotFound(path~ : @path.Path)
  ConfigInvalid(path~ : @path.Path, reason~ : String)
}
```

A message is for human explanation. It is not a replacement for values that a caller must inspect, compare, join, or serialize.

## Recovery

Catch an error only where the current scope can restore a valid state, translate it into the boundary's error vocabulary, or intentionally choose a documented fallback. Otherwise, let it propagate to the caller.

Do not catch merely to log, rename, stringify, or rethrow the same failure. Final rendering, logging, and exit-code selection belong at the application boundary unless a lower layer owns a genuine recovery decision.

When translating an error, retain the original failure as structured context when the target error type supports it. Do not replace an unknown error with a generic string that loses its identity.

Use `try?` only when `Result` is the required boundary contract. Avoid `try!` in production paths unless the invariant making failure impossible is local and evident.

Do not define a new `suberror` merely to replace a generic message with another name. A custom error is justified when a caller branches on its variants or needs typed context such as a path, identifier, status, or original failure.

## Tests

Let unexpected failures fail the test. For an expected failure, assert the typed error variant and its relevant fields instead of comparing rendered error text.
