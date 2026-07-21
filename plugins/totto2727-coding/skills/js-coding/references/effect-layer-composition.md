# Effect Layer Composition

> Document type: concrete TypeScript implementation guidance.

## Layer Composition

| Method               | Role                                          | Why                                                                                                                       |
| -------------------- | --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `Layer.provideMerge` | Provide deps and expose both layers' services | Use when downstream consumers need access to both the provider and the dependent layer's services                         |
| `Layer.provide`      | Provide deps without exposing them            | Use for internal dependencies (logging, tracing, etc.) that should stay encapsulated and not leak to downstream consumers |

Start from the highest-level service and chain dependencies downward with `.pipe()`.
