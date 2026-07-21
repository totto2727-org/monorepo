# TypeScript State Modeling

> Document type: concrete TypeScript implementation guidance.

## Discriminated unions

Represent mutually exclusive states as a discriminated union. Each variant carries exactly the data that exists in that state.

```ts
type LoadState =
  | { readonly _tag: 'Idle' }
  | { readonly _tag: 'Loading' }
  | { readonly _tag: 'Loaded'; readonly data: Hoge }
  | { readonly _tag: 'Failed'; readonly error: LoadError }
```

Do not encode the same state as independent booleans and optional or untyped fields such as `{ loading: boolean, error: boolean, data: any }`. That shape permits contradictory and incomplete combinations.

## Transitions

- Transition functions accept a valid variant and return another valid variant.
- Construct state through named constructors when a variant requires validation or normalization.
- Match on the discriminant and make the match exhaustive. An `assertNever` branch may enforce exhaustiveness when the surrounding API does not provide an exhaustive matcher.
- Do not add a default branch that silently accepts future variants.
- Keep operation failure in `Effect.Effect<Success, Failure, Requirements>` while the operation is running. Store a failure in a state variant only when the application must retain or render that state.

## Domain variants

Use the same pattern for domain choices, not only UI lifecycle state. For example, model authenticated and anonymous sessions, local and remote resources, or accepted and rejected commands as distinct variants when their available data differs.
