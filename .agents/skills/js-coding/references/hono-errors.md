# Hono Errors

> Document type: concrete TypeScript implementation guidance.

## HTTP Error Template

Define an HTTP error as `Data.TaggedError` with `makeResponseEffect` only when the HTTP boundary must render a distinct response status or body. Reuse an existing typed failure when callers do not need a new distinction.

```typescript
export class {Name} extends Data.TaggedError('http/error/{Name}') {
  makeResponseEffect() {
    return Effect.succeed(Context.get().json({ error: '{Display Name}' }, {statusCode}))
  }
}
```

Tag format: `http/error/{ErrorName}`

### Examples

- [email/sender.ts](../../../../../js/app/identity-provider/app/feature/email/sender.ts)
