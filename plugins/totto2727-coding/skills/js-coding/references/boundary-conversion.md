# TypeScript Boundary Conversion

> Document type: concrete TypeScript implementation guidance.

## Boundary pipeline

Treat every external response, JSON document, command argument, environment value, and weakly typed library result as untrusted input. Keep it as `unknown` only inside the adapter that owns the boundary, then move it through explicit representations:

```text
unknown input -> external response model -> validated domain model -> external request model -> encoded JSON
```

The external response model mirrors the source contract closely enough to decode it without inventing domain guarantees. The domain conversion validates identifiers, variants, units, ranges, required relationships, and cross-field invariants. The external request model mirrors the destination contract and contains only serializable values.

## Effect Schema

Use an Effect Schema decoder such as `Schema.decodeUnknownEffect` at an untyped ingress. Return a typed failure from that adapter instead of asserting the value with `as` or widening it to `any`.

```ts
const decodeHogeResponse = Schema.decodeUnknownEffect(HogeResponse)

const receiveHoge = (input: unknown) =>
  decodeHogeResponse(input).pipe(
    Effect.mapError((error) => new HogeBoundaryError({ error })),
    Effect.flatMap(Hoge.fromResponse),
  )
```

`Hoge.fromResponse` is the strict domain conversion. It must return an Effect or another typed failure mechanism when a decoded wire value is structurally valid but violates a domain invariant.

## Internal contracts

- Internal services accept domain types, not `unknown`, `any`, generic records, JSON objects, response DTOs, or third-party library types.
- A weak third-party type receives the same adapter treatment as an external JSON payload; normalize it once before it enters the domain.
- Do not use `as` to bypass a conversion. If the compiler cannot prove the conversion, add a decoder, constructor, or explicit exhaustive mapping.
- Do not reuse one type for both response and request payloads merely because their current fields happen to match.
- Encode JSON only from the outbound request model at the transport boundary.

## Review questions

- Where does the value first become trusted?
- Which function validates domain invariants that the external schema does not express?
- Can any `unknown`, `any`, wire DTO, or library-owned value escape its adapter?
- Does the request encoder accept a dedicated request model rather than the internal domain object?
