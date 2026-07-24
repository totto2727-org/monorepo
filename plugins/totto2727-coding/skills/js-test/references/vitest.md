# Vitest Implementation

> Document type: concrete TypeScript test implementation guidance.

## Supported execution surface

```bash
vp run js:test
vp test run <test-file>
vp test related <source-file>
```

Use a project-level `vp run --filter <project> test` task when the test belongs to one workspace project. Do not place manual verification, browser inspection without an automated oracle, or prose-only review procedures in this skill.

## Implementation practices

- Import test APIs from the repository-supported Vite+ test entry point when established by surrounding code.
- Keep tests isolated and deterministic; use Vitest lifecycle hooks only to create and dispose state owned by the current test scope.
- Mock external boundaries, not the unit's internal implementation details.
- Prefer observable results and typed errors over assertions about private call sequences.
- Use the matcher that directly describes the contract, such as `toEqual`, `toMatchObject`, `toThrow`, or awaited `rejects`; do not reduce a richer assertion to a boolean or mutable sentinel.
- Use the smallest file-level or related-test command that proves the changed behavior, then use the project or root task when broader evidence is required.

## Assertion and exception anti-patterns

Do not assign a thrown error or an exception-occurrence flag to a temporary variable merely to control whether the test passes.

```ts
// Bad: manual catch and temporary state obscure the expected rejection.
it('rejects invalid input', async () => {
  let caught: unknown
  try {
    await parseConfig('invalid')
  } catch (error) {
    caught = error
  }
  expect(caught).toBeInstanceOf(ConfigError)
})

// Good: the matcher directly expresses the expected rejection.
it('rejects invalid input', async () => {
  await expect(parseConfig('invalid')).rejects.toThrow(ConfigError)
})
```

For synchronous exceptions, pass a function to `toThrow`:

```ts
it('throws for invalid input', () => {
  expect(() => parseConfigSync('invalid')).toThrow(ConfigError)
})
```

Always await `resolves` and `rejects` expectations. Use explicit `try`/`catch` only when a property of the caught error is part of the contract and no direct matcher can express it.

## Scope boundary

This reference covers only TypeScript test code executable through Vite+ and Vitest. Manual QA, subjective inspection, and human-readable reports belong to `share-test-design-flow`.
