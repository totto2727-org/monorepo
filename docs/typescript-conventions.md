# TypeScript Conventions

This document defines TypeScript-specific coding conventions.

## type vs interface

**Use `type` by default, `interface` only when necessary**

### Recommended: type

```typescript
export type Env = {
  Bindings: Cloudflare.Env
  Variables: {
    database: Drizzle.Client
  }
}

export type Client = ReturnType<typeof make>
```

### When interface is necessary

Use `interface` only for specific cases like module augmentation:

```typescript
declare module "@tanstack/react-router" {
  interface Register {
    router: ReturnType<typeof getRouter>
  }
}
```

When using `interface` in this context, suppress the lint warning with reason:

```typescript
// biome-ignore lint/style/useConsistentTypeDefinitions: Need override
```

## Mandatory import type

Always use `import type` for type-only imports:

```typescript
import type { Context as HonoContext } from "hono"
import type { Option } from "@totto/function/effect"
import type { AnyDrizzleD1Database } from "../db/type.js"
```

This helps:

- Tree-shaking and bundle optimization
- Clear separation between runtime and type dependencies
- Faster type checking
