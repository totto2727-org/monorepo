# MoonBit Test Execution

> Document type: concrete MoonBit test execution guidance.

## Supported execution surface

```bash
vp run mbt:test
vp run --filter <project> test
moon test
moon test --update
```

Prefer the Vite+ task. Invoke `moon test` directly only when a repository task cannot express the required file, package, or snapshot-update operation.

## Async tests

Write asynchronous cases as `async test`. Add the resolved `moonbitlang/async` module dependency and import `"moonbitlang/async"` in the package's `moon.pkg`; MoonBit requires that runtime import even when the test body uses no `@async` function directly. Use `for "test"` when only black-box tests need it, `for "wbtest"` when only white-box tests need it, or the ordinary package import when production code is also asynchronous.

Async tests may run in parallel. Keep their state independent, await every operation under test, and use the package's supported target for the resolved async runtime.

## Scope boundary

This reference covers only MoonBit test code executable through repository Vite+ tasks or `moon test`. Manual verification, visual or subjective inspection, and human-readable QA reports belong to `share-test-design-flow`.
