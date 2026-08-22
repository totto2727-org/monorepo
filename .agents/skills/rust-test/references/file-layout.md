# Rust Test File Layout

Classify a test by the boundary it exercises before choosing its location.

## Unit and white-box tests

Place unit and white-box tests beside the production source under `src/`.

- Keep small tests inline in the source file under a `#[cfg(test)]` module.
- Move larger test modules to a sibling file named `{source_file_stem}_test.rs`, such as `src/cli_test.rs` for `src/cli.rs`.
- Register a sibling test module only under `#[cfg(test)]` so it is excluded from production builds.
- Keep tests that require private implementation access inside the production module's test module; use `#[path = "cli_test.rs"]` when the test body must live in a sibling file.

Do not place unit or white-box tests in the repository-root `tests/` directory.

## Integration and black-box tests

Place integration and black-box tests only in `<repository-root>/tests/`.

- Exercise the crate through its public API or run the compiled binary through its user-facing interface.
- Do not use `#[cfg(test)]` to register files under `tests/`; Cargo compiles each top-level test file as a separate crate.
- Keep shared integration-test support code in a submodule such as `tests/common/mod.rs` when needed, rather than as another top-level test target.

## Examples

Write usage examples as rustdoc documentation tests on the public item or crate documentation they explain. Use a runnable Rust code block under an `# Examples` section and verify it with `cargo test --doc` or the repository's equivalent test task.

Do not place usage examples in a standalone example test or an `examples/` directory.

## Official references

- [Test Organization, The Rust Programming Language](https://doc.rust-lang.org/book/ch11-03-test-organization.html)
- [Documentation tests, The rustdoc book](https://doc.rust-lang.org/rustdoc/write-documentation/documentation-tests.html)
