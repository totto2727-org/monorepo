---
name: effect-layer
user-invocable: false
description: >-
  Effect Layer and Service definition patterns for this monorepo.
  Use when defining a new service with Layer, creating ServiceMap.Service tags,
  or implementing dependency injection with Effect.
  Common triggers: "create a service", "define a Layer", "add Effect DI",
  "ServiceMap", "Layer.effect", "Layer.sync", "Layer.succeed", "Layer.scoped".
  Do NOT use for: Layer composition or runtime creation (use effect-runtime),
  Hono handler patterns (use effect-hono).
---

# Effect Layer Definition Patterns

Related skills: [effect-runtime](../effect-runtime/SKILL.md), [effect-hono](../effect-hono/SKILL.md)

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

- `Layer.succeed` — [env.ts](../../js/app/saas-example/src/feature/env.ts)
- `Layer.sync` / `Layer.effect` — [kysely.ts](../../js/app/saas-example/src/feature/db/kysely.ts)
- `Layer.effect` with multiple deps — [better-auth.ts](../../js/app/saas-example/src/feature/auth/better-auth.ts)

## Service Access

Access services within `Effect.gen` using `yield*`:

```typescript
const service = yield * SomeModule.Service
```
