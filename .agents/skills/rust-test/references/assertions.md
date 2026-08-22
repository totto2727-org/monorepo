# Rust Test Assertions

Apply the matcher-selection principles from [`share-test`](../../share-test/SKILL.md), then use the standard Rust assertion that preserves the most useful failure diagnostics.

## Assertion selection

- Use `assert_eq!` or `assert_ne!` for value equality so failures display both values.
- Use `assert!` when the named boolean predicate itself is the contract. Do not reduce an equality or error-variant check to `assert!(actual == expected)` or `assert!(result.is_err())`.
- Use `matches!` when only an enum or `Result` variant matters. When its payload is also part of the contract, destructure it with `match` or `let ... else`, then assert the relevant fields.
- Assert a typed recoverable `Err` instead of expecting a panic. Use `#[should_panic(expected = "...")]` only when panic behavior is the public contract, and keep the expected text to the stable fragment the caller can rely on.
- Add a snapshot dependency only when the project already uses it and the complete stable representation is the contract. Prefer standard structural assertions for small values.

## Execution

When invoking Cargo directly, use the smallest command that proves the behavior:

```bash
cargo test <test-name>
cargo test --test <integration-target>
cargo test --doc
```

## Async tests

Use the async executor already selected by the crate or repository, such as its runtime test attribute or an established `block_on` helper. Do not add a second runtime or a new executor dependency only for one test. Await every operation and assertion that belongs to the contract; do not let the test return while spawned work remains unobserved.

For a runtime-independent library that returns `Future` values, keep executor selection in the consumer or integration-test boundary unless the library already defines a supported test executor.
