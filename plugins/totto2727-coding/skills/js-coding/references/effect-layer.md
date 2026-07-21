# Effect Layer Definition Patterns

> Document type: concrete TypeScript implementation guidance.

Related references: [Effect Layer Composition](effect-layer-composition.md), [Effect Runtime](effect-runtime.md), and [Hono Handler Boundary](hono-handler.md).

## File Template

```typescript
// feature/{name}.ts

import { Effect, Layer, ServiceMap } from 'effect'

// --- Non-exported (internal) ---

const makeInstance = (/* deps */) => {
  // ...
}

// --- Exported ---

export type Instance = ReturnType<typeof makeInstance>

export const Service = ServiceMap.Service<Instance>('@app/{app-name}/feature/{name}/Service')

// Layer variants as needed
export const layer = Layer.effect(Service, ...)
export const localLayer = Layer.sync(Service, ...)
export const remoteLayer = Layer.effect(Service, ...)
```

### Export Rules

- **Export**: `Instance` type, `Service` tag, `layer` / `{variant}Layer`
- **Non-export**: `make*` functions, internal helpers, config values

### Naming Conventions

| Name                       | Role                                                 |
| -------------------------- | ---------------------------------------------------- |
| `Instance`                 | Type of the value the service provides               |
| `Service`                  | `ServiceMap.Service` tag                             |
| `layer` / `{variant}Layer` | Layer definition (`localLayer`, `remoteLayer`, etc.) |
| `make{Variant}`            | Instance factory function (non-exported)             |

### Service Tag Format

```
@app/{app-name}/feature/{feature-name}/Service
```

## Layer Constructors

| Constructor     | Description                                       | Use Case                               |
| --------------- | ------------------------------------------------- | -------------------------------------- |
| `Layer.succeed` | Provides a static implementation of the service   | Already-known value (e.g., env config) |
| `Layer.sync`    | Defines a service using a synchronous constructor | Synchronous computation needed         |
| `Layer.effect`  | Defines a service with an effectful constructor   | Depends on other services              |
| `Layer.scoped`  | Creates a service with lifecycle management       | Requires acquire/release               |

### Examples

- `Layer.succeed` — [env.ts](../../../../../js/app/feed-platform-backend/src/feature/env.ts)
- `Layer.sync` / `Layer.effect` — [kysely.ts](../../../../../js/app/identity-provider/app/feature/db/kysely.ts)
- `Layer.effect` with multiple deps — [better-auth.ts](../../../../../js/app/feed-platform-backend/src/feature/auth/better-auth.ts)

## Service Access

Access services within `Effect.gen` using `yield*`:

```typescript
const service = yield * SomeModule.Service
```
