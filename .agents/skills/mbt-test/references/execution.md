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

## Scope boundary

This reference covers only MoonBit test code executable through repository Vite+ tasks or `moon test`. Manual verification, visual or subjective inspection, and human-readable QA reports belong to `share-test-design-flow`.
