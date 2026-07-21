# TypeScript Error Handling

> Document type: concrete TypeScript implementation guidance.

## Typed failure channels

Use `Effect.Effect<Success, Failure, Requirements>` to expose recoverable failures in the type. Compose or `yield*` the Effect so failures propagate to the application boundary by default.

Use `Effect.mapError` when a boundary must translate an upstream error into its own vocabulary without changing control flow. Use `Effect.catchTag` or `Effect.catchTags` only when the current layer recovers, selects a different behavior, or intentionally converts failure into success.

Do not catch merely to log, stringify, rename, or rethrow the same failure. Centralize final logging, HTTP rendering, CLI exit handling, and defect reporting at the application boundary.

## Custom errors

Define a `Data.TaggedError` only when a caller must discriminate that failure or inspect structured context. Reuse the upstream typed error when no new distinction is required.

A boundary error should preserve the original failure as structured data when it translates an external or weakly typed failure. Do not replace it with `String(error)`, `error.message`, or a fallback message.

```ts
const loadHoge = source.load.pipe(
  Effect.mapError((error) => new HogeLoadError({ error, message: 'failed to load Hoge' })),
)
```

The human-authored message explains the boundary. The `error` field preserves the cause for diagnostics and later rendering.

## Defects

Do not widen programmer defects into the recoverable error channel merely to make them catchable. Fix violated invariants at their source, and reserve typed failures for conditions the program is designed to report, recover from, or branch on.
