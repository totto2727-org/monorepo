# MoonBit Test File Layout

> Document type: concrete MoonBit test placement and file-naming guidance.

## Unit tests

A unit-test file under `src/**` must correspond to exactly one implementation file in the same directory. For an implementation named `src/**/foo.mbt`, use `src/**/foo_test.mbt` for black-box tests or `src/**/foo_wbtest.mbt` for white-box tests.

Choose `_test.mbt` when the test needs only the implementation's public contract. Choose `_wbtest.mbt` only when the test must access package-private declarations. The visibility suffix does not change the implementation-aligned stem.

Do not insert a scenario, suite, lifecycle, benchmark, or other qualifier between the implementation stem and the test suffix. Names such as `foo_integration_test.mbt`, `foo_lifecycle_test.mbt`, `foo_bench_test.mbt`, and `test_fixture_wbtest.mbt` are not allowed under `src/**`.

Keep `bench` blocks in the corresponding `foo_test.mbt` or `foo_wbtest.mbt`; run them with `moon bench` without changing the implementation-aligned file stem.

## Integration tests

Place a test that exercises multiple implementation files, packages, or an end-to-end production flow under `src/test/**`. Integration-test file names must end in `_test.mbt` or `_wbtest.mbt`; they do not claim a one-to-one relationship with an implementation file outside `src/test`.

Prefer `_test.mbt` for integration tests so they consume public production contracts. Use `_wbtest.mbt` only when the integration-test package itself has package-private support declarations that the test must access. A white-box integration test does not gain access to private declarations of an imported production package.

Every `src/test` package must have a `moon.pkg` with explicit imports for the production packages and test dependencies it exercises. Keep fixtures in the integration test file when practical; shared integration support may use ordinary `.mbt` source files inside the same `src/test` package.

## Classification

Use `src/**/foo{_test,_wbtest}.mbt` when one implementation file is the test's system under test, even if collaborators are replaced with fakes. Use `src/test/**/*{_test,_wbtest}.mbt` when the observable behavior depends on multiple real implementation units or crosses a production boundary such as client to thread to process execution.

## Official references

- [Writing Tests](https://docs.moonbitlang.com/en/latest/language/tests.html) — black-box `_test.mbt` and white-box `_wbtest.mbt` semantics.
- [Package Configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) — package, test, and white-box test imports.
