# MoonBit State Modeling

> Document type: concrete MoonBit implementation guidance.

## Enum states

Represent mutually exclusive states with an enum whose variants carry exactly the available data.

```mbt check
enum LoadState {
  Idle
  Loading
  Loaded(Hoge)
  Failed(HogeError)
}
```

Do not represent the same state with independent booleans, nullable values, or unrelated `Option` fields. Those representations permit combinations such as both loading and failed, or loaded without data.

## Transitions

- Match every state variant explicitly and let the compiler report missing cases.
- Return a new valid variant from a state transition instead of mutating several fields through an inconsistent intermediate state.
- Use a constructor when a variant payload requires validation before it becomes valid.
- Use an enum for retained application state and a typed `raise` effect for an operation that may fail. Convert a caught operation failure into `Failed(error)` only when the application must retain or render that state.

Apply the same rule to domain choices such as authenticated and anonymous sessions, local and remote sources, or mutually exclusive command inputs.
