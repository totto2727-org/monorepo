# MoonBit Pattern Matching

> Document type: concrete MoonBit implementation guidance.

## Early exits

Use `guard` when the remaining function requires a precondition or extracted variant. The fallback must explain or propagate the invalid state rather than hide it behind an unrelated default.

```mbt check
guard geometry is Polygon(coordinates~) else {
  fail("expected Polygon")
}
```

## Finite states

Use exhaustive `match` for enum behavior so a new variant makes incomplete handling visible. Model a finite domain as an enum instead of strings, booleans, or wrapper structs unless each state carries additional data that requires a distinct type.

Do not add a wildcard branch merely to silence an exhaustiveness failure. Use one only when all unmatched variants intentionally share the same stable behavior.
